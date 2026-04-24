//
//  AppContentService.swift
//  EKGx
//
//  Static app content and support endpoints (permitAll — no auth required):
//   - GET  /api/app/faq
//   - GET  /api/app/terms
//   - GET  /api/app/privacy-policy
//   - GET  /api/app/indications-for-use
//   - POST /api/app/support-ticket
//

import Foundation

// MARK: - Response Models

struct AppTextContent: Decodable {
    let version: String?
    let effectiveDate: String?
    let text: String?
}

struct FaqEntry: Decodable, Identifiable {
    let id: Int64?
    let question: String?
    let answer: String?
    let displayOrder: Int?
}

struct FaqContent: Decodable {
    let entries: [FaqEntry]?
}

// MARK: - Service

final class AppContentService {

    private let client: APIClient
    private let checkinService: AppCheckinService

    init(client: APIClient = .shared, checkinService: AppCheckinService) {
        self.client         = client
        self.checkinService = checkinService
    }

    // MARK: - FAQ

    func getFaq() async throws -> [FaqEntry] {
        let response: APIResponse<FaqContent> = try await client.get(
            path: APIEndpoints.App.faq,
            query: ["appUuid": checkinService.appUuid]
        )
        return response.data?.entries ?? []
    }

    // MARK: - Terms & Conditions

    func getTerms() async throws -> AppTextContent? {
        let response: APIResponse<AppTextContent> = try await client.get(
            path: APIEndpoints.App.terms,
            query: ["appUuid": checkinService.appUuid]
        )
        return response.data
    }

    // MARK: - Privacy Policy

    func getPrivacyPolicy() async throws -> AppTextContent? {
        let response: APIResponse<AppTextContent> = try await client.get(
            path: APIEndpoints.App.privacyPolicy,
            query: ["appUuid": checkinService.appUuid]
        )
        return response.data
    }

    // MARK: - Indications For Use

    func getIndicationsForUse() async throws -> AppTextContent? {
        let response: APIResponse<AppTextContent> = try await client.get(
            path: APIEndpoints.App.indicationsForUse,
            query: ["appUuid": checkinService.appUuid]
        )
        return response.data
    }

    // MARK: - Support Ticket

    func submitSupportTicket(
        subject: String,
        message: String,
        contactName: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil
    ) async throws {
        let body = SupportTicketRequest(
            appUuid: checkinService.appUuid,
            subject: subject,
            message: message,
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone
        )
        try await client.postVoid(path: APIEndpoints.App.supportTicket, body: body)
    }
}
