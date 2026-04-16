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
    case backend(message: String)     // Server-provided error message (any status)
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
        case .backend(let message):     return message
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
        // Don't follow redirects automatically — the backend uses 302 → /login
        // for Spring Security auth failures which would otherwise cause an
        // infinite redirect loop. We surface the raw status instead.
        return URLSession(configuration: config, delegate: RedirectBlockingDelegate(), delegateQueue: nil)
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

    /// Multipart POST — supports multiple files plus optional form fields and query params.
    func postMultipart<T: Decodable>(
        path: String,
        query: [String: String] = [:],
        fields: [String: String] = [:],
        files: [MultipartFile] = [],
        responseType: T.Type = T.self
    ) async throws -> APIResponse<T> {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        for file in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")

        var components = URLComponents(url: resolve(path: path), resolvingAgainstBaseURL: true)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: components.url!)
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
        let appUuid = UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? ""
        if !appUuid.isEmpty { request.setValue(appUuid, forHTTPHeaderField: "X-App-UUID") }

        // Explicit whitelist of unauthenticated endpoints. Everything else
        // gets the Bearer token — including /api/auth/pin/status, pin/setup,
        // pin/change, which all require the authenticated session.
        let path = request.url?.path ?? ""
        let publicPaths: Set<String> = [
            "/api/auth/login",
            "/api/auth/pin-login",
            "/api/auth/register",
            "/api/auth/forgot-password",
            "/api/app/checkin",
            "/api/app/info"
        ]
        let isPublic = publicPaths.contains(path)

        if !isPublic, let token = TokenStore.shared.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private let redirectBlocker = RedirectBlockingDelegate()

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> APIResponse<T> {
        #if DEBUG
        logRequest(request)
        #endif

        do {
            let (data, response) = try await session.data(for: request, delegate: redirectBlocker)
            guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

            #if DEBUG
            logResponse(http, data: data)
            #endif

            switch http.statusCode {
            case 200...299:
                // Happy path — but check for nested error envelope:
                // { status: 200, data: { status: 400, message: "..." } }
                if let nested = extractNestedError(from: data) {
                    throw APIError.backend(message: nested)
                }
                do {
                    return try decoder.decode(APIResponse<T>.self, from: data)
                } catch {
                    throw APIError.decodingFailed(error)
                }
            case 302: throw APIError.invalidCredentials   // Spring redirect to /login
            case 401:
                throw extractBackendError(from: data) ?? .invalidCredentials
            case 403:
                throw extractBackendError(from: data) ?? .forbidden
            case 404:
                throw extractBackendError(from: data) ?? .notFound
            case 409:
                throw extractBackendError(from: data) ?? .conflict
            case 400:
                throw extractBackendError(from: data) ?? .unknown
            case 500...:
                throw extractBackendError(from: data) ?? .serverError(statusCode: http.statusCode)
            default:
                throw extractBackendError(from: data) ?? .unknown
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkUnavailable
        }
    }

    // MARK: - Backend Error Extraction

    /// Pulls a human-readable error message out of an `ApiResponseVoid`-shaped
    /// response. Handles both top-level `{status, message}` and nested
    /// `{data: {status, message}}` error envelopes.
    private func extractBackendError(from data: Data) -> APIError? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let nested = json["data"] as? [String: Any],
           let message = nested["message"] as? String, !message.isEmpty {
            return .backend(message: message)
        }
        if let message = json["message"] as? String,
           !message.isEmpty, message.lowercased() != "success" {
            return .backend(message: message)
        }
        return nil
    }

    /// Detects the "HTTP 200 but data.status is a 4xx error" pattern.
    private func extractNestedError(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nested = json["data"] as? [String: Any],
              let nestedStatus = nested["status"] as? Int,
              (400...599).contains(nestedStatus),
              let message = nested["message"] as? String, !message.isEmpty
        else { return nil }
        return message
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

// MARK: - MultipartFile

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

// MARK: - Redirect Blocking Delegate

/// Blocks all HTTP redirects. The EKGx backend uses Spring Security which
/// returns 302 → /login for unauthenticated requests to protected endpoints.
/// Following those redirects causes an infinite loop since /login itself
/// requires auth. Returning nil here surfaces the original 302 as the final
/// response so we can show a proper error instead of hanging.
final class RedirectBlockingDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
