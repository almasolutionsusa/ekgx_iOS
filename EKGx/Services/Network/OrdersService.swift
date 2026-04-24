//
//  OrdersService.swift
//  EKGx
//
//  Patient order queue for any exam type.
//  Per spec (JWT auth required):
//   - POST /api/orders              — create an order
//   - GET  /api/orders/app          — list open orders at the app's facility
//   - POST /api/orders/{id}/complete — manually mark an order complete
//   - POST /api/orders/{id}/cancel   — cancel an order
//

import Foundation

final class OrdersService {

    private let client: APIClient
    private let checkinService: AppCheckinService

    init(client: APIClient = .shared, checkinService: AppCheckinService) {
        self.client         = client
        self.checkinService = checkinService
    }

    // MARK: - Create

    func create(
        patientUuid: String,
        examType: String? = nil,
        visibility: String? = nil,
        note: String? = nil
    ) async throws -> PatientOrder {
        let body = CreateOrderRequest(
            patientUuid: patientUuid,
            appUuid: checkinService.appUuid,
            examType: examType,
            visibility: visibility,
            note: note
        )
        let response: APIResponse<PatientOrder> = try await client.post(
            path: APIEndpoints.Orders.create,
            body: body
        )
        guard let order = response.data else { throw APIError.decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing order in response"))) }
        return order
    }

    // MARK: - List

    func list(examType: String? = nil) async throws -> [PatientOrder] {
        var query: [String: String] = ["appUuid": checkinService.appUuid]
        if let examType { query["examType"] = examType }

        let response: APIResponse<[PatientOrder]> = try await client.get(
            path: APIEndpoints.Orders.list,
            query: query
        )
        return response.data ?? []
    }

    // MARK: - Complete

    @discardableResult
    func complete(id: Int64) async throws -> PatientOrder {
        let response: APIResponse<PatientOrder> = try await client.post(
            path: APIEndpoints.Orders.complete(id),
            body: EmptyBody()
        )
        guard let order = response.data else { throw APIError.decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing order in response"))) }
        return order
    }

    // MARK: - Cancel

    @discardableResult
    func cancel(id: Int64) async throws -> PatientOrder {
        let response: APIResponse<PatientOrder> = try await client.post(
            path: APIEndpoints.Orders.cancel(id),
            body: EmptyBody()
        )
        guard let order = response.data else { throw APIError.decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing order in response"))) }
        return order
    }
}

// MARK: - Helpers

private struct EmptyBody: Encodable {}
