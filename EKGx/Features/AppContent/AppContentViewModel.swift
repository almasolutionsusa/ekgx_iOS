//
//  AppContentViewModel.swift
//  EKGx
//
//  Shared ViewModel for FAQ, Indications for Use, and Support screens.
//

import Foundation

@Observable
@MainActor
final class AppContentViewModel {

    // MARK: - FAQ

    var faqEntries: [FaqEntry] = []
    var isFaqLoading: Bool = false
    var faqError: String? = nil

    // MARK: - Indications for Use

    var ifuContent: AppTextContent? = nil
    var isIfuLoading: Bool = false
    var ifuError: String? = nil

    // MARK: - Support Ticket

    var supportSubject: String = ""
    var supportMessage: String = ""
    var supportContactPhone: String = ""
    var isSubmitting: Bool = false
    var submitSuccess: Bool = false
    var submitError: String? = nil
    var subjectError: String? = nil
    var messageError: String? = nil

    // MARK: - Dependencies

    private let contentService: AppContentService
    private let router: AppRouter

    init(contentService: AppContentService, router: AppRouter) {
        self.contentService = contentService
        self.router         = router
    }

    // MARK: - FAQ

    func loadFaq() {
        guard faqEntries.isEmpty else { return }
        Task { await fetchFaq() }
    }

    private func fetchFaq() async {
        isFaqLoading = true; faqError = nil
        defer { isFaqLoading = false }
        do {
            faqEntries = try await contentService.getFaq()
        } catch {
            faqError = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Indications for Use

    func loadIfu() {
        guard ifuContent == nil else { return }
        Task { await fetchIfu() }
    }

    private func fetchIfu() async {
        isIfuLoading = true; ifuError = nil
        defer { isIfuLoading = false }
        do {
            ifuContent = try await contentService.getIndicationsForUse()
        } catch {
            ifuError = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Support

    func submitSupport() {
        subjectError = supportSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? L10n.Validation.required : nil
        messageError = supportMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? L10n.Validation.required : nil
        guard subjectError == nil && messageError == nil else { return }
        Task { await performSubmit() }
    }

    private func performSubmit() async {
        isSubmitting = true; submitError = nil; submitSuccess = false
        defer { isSubmitting = false }
        do {
            try await contentService.submitSupportTicket(
                subject: supportSubject.trimmingCharacters(in: .whitespacesAndNewlines),
                message: supportMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                contactName:  nil,
                contactEmail: nil,
                contactPhone: supportContactPhone.isEmpty ? nil : supportContactPhone
            )
            submitSuccess = true
            supportSubject = ""; supportMessage = ""
            supportContactPhone = ""
        } catch let error as APIError {
            submitError = error.errorDescription
        } catch {
            submitError = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Navigation

    func navigateBack() {
        router.navigate(to: .menu)
    }
}
