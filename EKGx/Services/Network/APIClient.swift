//
//  APIClient.swift
//  EKGx
//
//  Shared HTTP client for all EKGx API calls.
//
//  - Uses URLSession with a persistent HTTPCookieStorage so JSESSIONID
//    is stored and re-sent automatically after login.
//  - All responses follow { status: Int, message: String, data: T? }.
//  - Throws APIError on non-2xx, network failure, or decode failure.
//  - Thread-safe: all async work happens on URLSession's delegate queue;
//    callers receive results on whatever actor they await from.
//

import Foundation

// MARK: - API Response Wrapper

struct APIResponse<T: Decodable>: Decodable {
    let status: Int
    let message: String
    let data: T?
}

// MARK: - APIError

enum APIError: LocalizedError {
    case invalidCredentials           // 401
    case forbidden                    // 403
    case notFound                     // 404
    case conflict                     // 409
    case serverError(statusCode: Int) // 5xx
    case decodingFailed(Error)
    case networkUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:        return L10n.Auth.Login.errorInvalidCredentials
        case .forbidden, .notFound,
             .conflict, .unknown,
             .decodingFailed:            return L10n.Auth.Login.errorGeneric
        case .serverError:               return L10n.Auth.Login.errorGeneric
        case .networkUnavailable:        return L10n.Auth.Login.errorNetwork
        }
    }
}

// MARK: - APIClient

final class APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Configuration

    let baseURL = URL(string: "https://dev.ekgx.com")!

    // MARK: - Session

    /// Dedicated cookie storage keeps JSESSIONID alive across requests
    /// without polluting HTTPCookieStorage.shared.
    let cookieStorage: HTTPCookieStorage = {
        let cs = HTTPCookieStorage()
        cs.cookieAcceptPolicy = .always
        return cs
    }()

    private(set) lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage   = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private init() {}

    // MARK: - Authenticated flag

    /// True when a valid session cookie exists.
    var isAuthenticated: Bool {
        let cookies = cookieStorage.cookies(for: baseURL) ?? []
        return cookies.contains { $0.name == "JSESSIONID" }
    }

    /// Clears all session cookies (logout).
    func clearSession() {
        cookieStorage.cookies(for: baseURL)?.forEach { cookieStorage.deleteCookie($0) }
    }

    // MARK: - Generic Request Methods

    /// POST with JSON body, decode response envelope.
    func post<Body: Encodable, T: Decodable>(
        path: String,
        body: Body,
        responseType: T.Type = T.self
    ) async throws -> APIResponse<T> {
        let request = try buildRequest(path: path, method: "POST", body: body)
        return try await execute(request)
    }

    /// POST with JSON body, no decoded data expected (data field ignored).
    func postVoid<Body: Encodable>(path: String, body: Body) async throws {
        let request = try buildRequest(path: path, method: "POST", body: body)
        let _: APIResponse<AnyCodable> = try await execute(request)
    }

    /// GET with query parameters, decode response envelope.
    func get<T: Decodable>(
        path: String,
        query: [String: String] = [:],
        responseType: T.Type = T.self
    ) async throws -> APIResponse<T> {
        let request = buildRequest(path: path, method: "GET", query: query)
        return try await execute(request)
    }

    /// Multipart POST — used for ECG file upload.
    func postMultipart<T: Decodable>(
        path: String,
        fields: [String: String],
        fileData: Data?,
        fileName: String = "ecg.bin",
        mimeType: String = "application/octet-stream",
        responseType: T.Type = T.self
    ) async throws -> APIResponse<T> {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        if let fileData {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")

        var request = URLRequest(url: resolve(path: path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        injectDeviceHeaders(&request)

        return try await execute(request)
    }

    // MARK: - Private Helpers

    private func resolve(path: String) -> URL {
        URL(string: path, relativeTo: baseURL)!
    }

    private func buildRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body,
        query: [String: String] = [:]
    ) throws -> URLRequest {
        var request = buildRequest(path: path, method: method, query: query)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func buildRequest(
        path: String,
        method: String,
        query: [String: String] = [:]
    ) -> URLRequest {
        var components = URLComponents(url: resolve(path: path), resolvingAgainstBaseURL: true)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        injectDeviceHeaders(&request)
        return request
    }

    private func injectDeviceHeaders(_ request: inout URLRequest) {
        let deviceUuid = UserDefaults.standard.string(forKey: AppCheckinService.Keys.deviceUuid) ?? ""
        let appUuid    = UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid)    ?? ""
        if !deviceUuid.isEmpty { request.setValue(deviceUuid, forHTTPHeaderField: "X-Device-UUID") }
        if !appUuid.isEmpty    { request.setValue(appUuid,    forHTTPHeaderField: "X-App-UUID")    }
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> APIResponse<T> {
        #if DEBUG
        logRequest(request)
        #endif

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

            #if DEBUG
            logResponse(http, data: data)
            #endif

            switch http.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(APIResponse<T>.self, from: data)
                } catch {
                    throw APIError.decodingFailed(error)
                }
            case 401: throw APIError.invalidCredentials
            case 403: throw APIError.forbidden
            case 404: throw APIError.notFound
            case 409: throw APIError.conflict
            case 500...: throw APIError.serverError(statusCode: http.statusCode)
            default:   throw APIError.unknown
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkUnavailable
        }
    }

    // MARK: - Debug Logging

    private func logRequest(_ request: URLRequest) {
        print("┌─── API REQUEST ───────────────────────────────")
        print("│ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("│ Headers: \(headers)")
        }
        if let body = request.httpBody,
           let contentType = request.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("application/json"),
           let json = try? JSONSerialization.jsonObject(with: body),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print("│ Body:\n\(str.split(separator: "\n").map { "│   \($0)" }.joined(separator: "\n"))")
        }
        print("└───────────────────────────────────────────────")
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        let status = response.statusCode
        let icon   = (200...299).contains(status) ? "✅" : "❌"
        print("┌─── API RESPONSE \(icon) ─────────────────────────────")
        print("│ \(status) \(response.url?.absoluteString ?? "?")")
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print("│ Body:\n\(str.split(separator: "\n").map { "│   \($0)" }.joined(separator: "\n"))")
        } else if let str = String(data: data, encoding: .utf8), !str.isEmpty {
            print("│ Body: \(str)")
        }
        print("└───────────────────────────────────────────────")
    }
}

// MARK: - Data Helpers

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}

// MARK: - AnyCodable (placeholder for void data fields)

struct AnyCodable: Codable {}
