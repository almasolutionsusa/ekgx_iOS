//
//  PatientListViewModel.swift
//  EKGx
//
//  Orders queue (patient waiting list) for the current facility.
//  Flow:
//    - On appear: GET /api/orders/app  → display open orders
//    - Add: search patient → select → POST /api/orders  → refresh list
//    - Cancel: POST /api/orders/{id}/cancel  → remove from list
//

import Foundation

@Observable
@MainActor
final class PatientListViewModel {

    // MARK: - Orders State

    var orders: [PatientOrder] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchQuery: String = ""

    // MARK: - Add Order Flow (search patient → create order)

    var showAddPatient: Bool = false

    // Patient search
    var searchFirstName: String = ""
    var searchLastName: String  = ""
    var searchDob: Date?        = nil
    var searchMRN: String       = ""
    var isSearching: Bool       = false
    var hasSearched: Bool       = false
    var searchResults: [SearchedPatient] = []
    var selectedPatient: SearchedPatient? = nil
    var searchFirstNameError: String? = nil
    var searchDobError: String?       = nil

    // Create patient sub-form
    var showCreatePatient: Bool       = false
    var createFirstName: String       = ""
    var createLastName: String        = ""
    var createDob: Date?              = nil
    var createGender: String          = "Male"
    var createMRN: String             = ""
    var isCreating: Bool              = false
    var createErrorMessage: String?   = nil
    var createFirstNameError: String? = nil
    var createLastNameError: String?  = nil
    var createDobError: String?       = nil
    var createMRNError: String?       = nil
    let genderOptions: [String]       = ["Male", "Female"]

    // Order creation
    var isAddingOrder: Bool   = false
    var addOrderError: String? = nil

    // Cancel confirmation
    var orderPendingCancel: PatientOrder? = nil
    var isCancelling: Bool = false

    // Device not connected alert
    var showDeviceAlert: Bool = false

    // MARK: - Computed

    var filteredOrders: [PatientOrder] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return orders }
        return orders.filter {
            ($0.patientFullName.localizedCaseInsensitiveContains(q)) ||
            ($0.patientMrn?.localizedCaseInsensitiveContains(q) ?? false) ||
            ($0.facilityName?.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    var totalCount: Int { orders.count }
    var canConfirmAdd: Bool { selectedPatient != nil }
    var facilityId: Int64? { appInfoService.facilityId }

    // MARK: - Dependencies

    private let ordersService: OrdersService
    private let patientsService: PatientsService
    private let appInfoService: AppInfoService
    private let router: AppRouter
    private let diContainer: AppDIContainer

    init(ordersService: OrdersService, patientsService: PatientsService, appInfoService: AppInfoService, router: AppRouter, diContainer: AppDIContainer) {
        self.ordersService   = ordersService
        self.patientsService = patientsService
        self.appInfoService  = appInfoService
        self.router          = router
        self.diContainer     = diContainer
    }

    // MARK: - Load Orders

    func loadOrders() {
        Task { await fetchOrders() }
    }

    private func fetchOrders() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            orders = try await ordersService.list()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Search (filter local list)

    func clearSearch() {
        searchQuery = ""
    }

    // MARK: - Navigate back

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Start recording from waiting list

    func startRecording(for order: PatientOrder) {
        guard diContainer.deviceService.currentState == .connected else {
            showDeviceAlert = true
            return
        }
        let patient = Patient(
            id: order.patientId.map { Int($0) },
            patientId: order.patientUuid,
            uniqueId: order.patientUuid,
            firstName: order.patientFirstName ?? "",
            lastName: order.patientLastName ?? "",
            birthDate: order.patientDob ?? "",
            gender: "Unknown",
            medicalRecordNumber: order.patientMrn,
            hasPhoto: nil
        )
        diContainer.lastRecordingPatient = patient
        diContainer.lastRecordingExistingId = nil
        diContainer.recordingSessionStartedAt = Date()
        activeOrderId = order.id
        router.recordingReturnRoute = .patientList
        router.navigate(to: .ecgRecording(patientId: order.patientUuid ?? ""))
    }

    // MARK: - Complete active order after recording

    /// Called when the user returns from analysis — cancels the order via API and removes it locally.
    func clearActiveOrder() {
        guard let oid = activeOrderId else { return }
        activeOrderId = nil
        orders.removeAll { $0.id == oid }
        Task { await performCancelOrder(id: oid) }
    }

    private(set) var activeOrderId: Int64? = nil

    // MARK: - Open Add Order Sheet

    func openAddPatient() {
        resetAddFlow()
        showAddPatient = true
    }

    func closeAddPatient() {
        showAddPatient = false
    }

    private func resetAddFlow() {
        searchFirstName = ""; searchLastName = ""; searchDob = nil; searchMRN = ""
        isSearching = false; hasSearched = false; searchResults = []; selectedPatient = nil
        searchFirstNameError = nil; searchDobError = nil
        showCreatePatient = false
        createFirstName = ""; createLastName = ""; createDob = nil
        createGender = "Male"; createMRN = ""
        isCreating = false; createErrorMessage = nil
        createFirstNameError = nil; createLastNameError = nil; createDobError = nil; createMRNError = nil
        isAddingOrder = false; addOrderError = nil
    }

    // MARK: - Patient Search (inside add sheet)

    func searchPatients() {
        let firstTrim = searchFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mrnTrim   = searchMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        if mrnTrim.isEmpty {
            searchFirstNameError = firstTrim.isEmpty ? L10n.Validation.nameEmpty : nil
            searchDobError       = searchDob == nil  ? L10n.Validation.required  : nil
            guard searchFirstNameError == nil && searchDobError == nil else { return }
        } else {
            searchFirstNameError = nil; searchDobError = nil
        }
        Task { await performPatientSearch() }
    }

    private func performPatientSearch() async {
        isSearching = true
        selectedPatient = nil
        defer { isSearching = false; hasSearched = true }

        guard let facId = facilityId else {
            await appInfoService.getInfo()
            guard let retryId = facilityId else { searchResults = []; return }
            await runPatientSearch(facilityId: retryId)
            return
        }
        await runPatientSearch(facilityId: facId)
    }

    private func runPatientSearch(facilityId: Int64) async {
        let dobString: String? = searchDob.map { Self.dobFormatter.string(from: $0) }
        do {
            let remote = try await patientsService.search(
                firstName: searchFirstName, lastName: searchLastName,
                dob: dobString, mrn: searchMRN, facilityId: facilityId
            )
            searchResults = remote.map { SearchedPatient.from($0) }
            if searchResults.count == 1 { selectedPatient = searchResults.first }
        } catch {
            searchResults = []
        }
    }

    func clearPatientSearch() {
        searchFirstName = ""; searchLastName = ""; searchDob = nil; searchMRN = ""
        searchResults = []; selectedPatient = nil; hasSearched = false
        searchFirstNameError = nil; searchDobError = nil
    }

    func selectPatient(_ patient: SearchedPatient) {
        selectedPatient = patient
    }

    // MARK: - Create Patient (inside add sheet)

    func openCreatePatient() {
        createFirstName = searchFirstName; createLastName = searchLastName
        createDob = searchDob; createMRN = searchMRN; createGender = "Male"
        createFirstNameError = nil; createLastNameError = nil
        createDobError = nil; createMRNError = nil; createErrorMessage = nil
        showCreatePatient = true
    }

    func cancelCreatePatient() { showCreatePatient = false }

    func submitCreatePatient() {
        guard validateCreateInputs() else { return }
        Task { await performCreatePatient() }
    }

    private func validateCreateInputs() -> Bool {
        let f = createFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = createLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = createMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        createFirstNameError = f.isEmpty ? L10n.Validation.nameEmpty : nil
        createLastNameError  = l.isEmpty ? L10n.Validation.nameEmpty : nil
        createDobError       = createDob == nil ? L10n.Validation.required : nil
        createMRNError       = m.isEmpty ? L10n.Validation.required : nil
        return [createFirstNameError, createLastNameError, createDobError, createMRNError].allSatisfy { $0 == nil }
    }

    private func performCreatePatient() async {
        isCreating = true; createErrorMessage = nil
        defer { isCreating = false }
        guard let facId = facilityId else {
            createErrorMessage = L10n.Auth.Register.errorFacilityNotAssigned; return
        }
        let dobStr = createDob.map { Self.dobFormatter.string(from: $0) } ?? ""
        do {
            let patient = try await patientsService.create(
                firstName: createFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName:  createLastName.trimmingCharacters(in: .whitespacesAndNewlines),
                dob: dobStr, gender: createGender,
                mrn: createMRN.trimmingCharacters(in: .whitespacesAndNewlines),
                facilityId: facId
            )
            guard let patient else { createErrorMessage = L10n.Auth.Login.errorGeneric; return }
            let created = SearchedPatient.from(patient)
            if !searchResults.contains(created) { searchResults.insert(created, at: 0) }
            selectedPatient = created
            hasSearched = true
            showCreatePatient = false
        } catch let error as APIError {
            createErrorMessage = error.errorDescription
        } catch {
            createErrorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Confirm Add Order

    func confirmAddOrder() {
        guard let patient = selectedPatient else { return }
        Task { await performAddOrder(patientUuid: patient.id) }
    }

    private func performAddOrder(patientUuid: String) async {
        isAddingOrder = true; addOrderError = nil
        defer { isAddingOrder = false }
        do {
            let order = try await ordersService.create(patientUuid: patientUuid)
            orders.insert(order, at: 0)
            showAddPatient = false
        } catch let error as APIError {
            addOrderError = error.errorDescription
        } catch {
            addOrderError = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Cancel Order

    func confirmCancel(_ order: PatientOrder) {
        orderPendingCancel = order
    }

    func cancelOrder() {
        guard let order = orderPendingCancel else { return }
        orderPendingCancel = nil
        Task { await performCancelOrder(id: order.id) }
    }

    private func performCancelOrder(id: Int64) async {
        isCancelling = true
        defer { isCancelling = false }
        do {
            _ = try await ordersService.cancel(id: id)
            orders.removeAll { $0.id == id }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - Helpers

    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
