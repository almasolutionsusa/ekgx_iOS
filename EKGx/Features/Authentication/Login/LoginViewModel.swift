//
//  LoginViewModel.swift
//  EKGx
//
//  Drives all state for LoginView. Contains zero UI code.
//

import Foundation

@Observable
@MainActor
final class LoginViewModel {

    // MARK: - Input State

    var email: String = ""
    var password: String = ""

    // MARK: - Username History / Suggestions

    var suggestions: [String] = []
    var showSuggestions: Bool = false

    private enum HistoryKey { static let usernames = "ekgx.loginHistory" }
    private var history: [String] {
        get { UserDefaults.standard.stringArray(forKey: HistoryKey.usernames) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: HistoryKey.usernames) }
    }

    private var suppressSuggestions = false

    func updateSuggestions() {
        guard !suppressSuggestions else { return }
        let q = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { showSuggestions = false; suggestions = []; return }
        suggestions = history.filter { $0.localizedCaseInsensitiveContains(q) }
        showSuggestions = !suggestions.isEmpty
    }

    func selectSuggestion(_ value: String) {
        suppressSuggestions = true
        email = value
        showSuggestions = false
        suggestions = []
        // Re-enable after the onChange cycle completes
        Task { @MainActor in suppressSuggestions = false }
    }

    func dismissSuggestions() {
        showSuggestions = false
    }

    private func saveToHistory(_ username: String) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var h = history.filter { $0 != trimmed }  // remove duplicate
        h.insert(trimmed, at: 0)
        history = Array(h.prefix(10))             // keep last 10
    }

    // MARK: - Forgot Password State

    var showForgotPassword: Bool = false
    var forgotEmail: String = ""
    var forgotEmailError: String? = nil
    var forgotIsLoading: Bool = false
    var forgotSuccessMessage: String? = nil
    var forgotErrorMessage: String? = nil

    func openForgotPassword() {
        forgotEmail        = email  // pre-fill with whatever is in the email field
        forgotEmailError   = nil
        forgotSuccessMessage = nil
        forgotErrorMessage = nil
        showForgotPassword = true
    }

    func cancelForgotPassword() {
        showForgotPassword = false
    }

    func submitForgotPassword() {
        let trimmed = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        forgotEmailError = Validators.validateEmail(trimmed)
        guard forgotEmailError == nil else { return }
        Task { await performForgotPassword(email: trimmed) }
    }

    private func performForgotPassword(email: String) async {
        forgotIsLoading    = true
        forgotErrorMessage = nil
        defer { forgotIsLoading = false }
        do {
            try await authService.forgotPassword(email: email)
            forgotSuccessMessage = L10n.Auth.Login.forgotPasswordSuccess
        } catch let authError as AuthError {
            forgotErrorMessage = authError.errorDescription
        } catch {
            forgotErrorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    // MARK: - PIN Login State

    var pinInput: String = ""
    var pinError: String? = nil

    // MARK: - UI State

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var emailError: String? = nil
    var passwordError: String? = nil

    // MARK: - UUID Alert

    var showUUIDAlert: Bool = false
    var isSendingUUID: Bool = false
    var uuidSendSuccess: Bool? = nil   // nil = not sent yet

    var appUUID: String { diContainer.checkinService.appUuid }

    func sendUUIDByEmail() {
        guard !isSendingUUID else { return }
        isSendingUUID = true
        uuidSendSuccess = nil
        Task {
            do {
                try await diContainer.appContentService.submitSupportTicket(
                    subject: "App UUID Request",
                    message: "App UUID: \(appUUID)"
                )
                uuidSendSuccess = true
            } catch {
                uuidSendSuccess = false
            }
            isSendingUUID = false
        }
    }

    // MARK: - Facility / Org info (tracked vars so SwiftUI re-renders when data arrives)

    var facilityName: String?     = nil
    var organizationName: String? = nil

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let diContainer: AppDIContainer
    private let router: AppRouter

    // MARK: - Init

    init(authService: AuthServiceProtocol, diContainer: AppDIContainer, router: AppRouter) {
        self.authService  = authService
        self.diContainer  = diContainer
        self.router       = router
        // Seed immediately if already cached (e.g. app relaunched)
        self.facilityName     = diContainer.appInfoService.cached?.facilityName
        self.organizationName = diContainer.appInfoService.cached?.organizationName
    }

    /// Call from LoginView .onAppear to pick up data once the async checkin/info calls complete.
    func refreshFacilityInfo() {
        facilityName     = diContainer.appInfoService.cached?.facilityName
        organizationName = diContainer.appInfoService.cached?.organizationName
    }

    // MARK: - Actions

    func login() {
        guard validateInputs() else { return }
        Task { await performLogin() }
    }

    func continueOffline() {
        diContainer.enableLocalMode(router: router)
    }

    func startEmergency() {
        diContainer.startEmergencySession(router: router)
    }

    func navigateToRegister() {
        router.navigate(to: .register)
    }

    func cancelPinLogin() {
        pinInput = ""
        pinError = nil
    }

    func keypadInput(_ digit: String) {
        guard pinInput.count < 6 else { return }
        pinInput += digit
        pinError = nil
        if pinInput.count == 6 { Task { await performPinLogin() } }
    }

    func keypadDelete() {
        guard !pinInput.isEmpty else { return }
        pinInput.removeLast()
        pinError = nil
    }

    func clearFieldError(for field: Field) {
        switch field {
        case .email:    emailError = nil
        case .password: passwordError = nil
        case .pin:      pinError = nil
        }
        errorMessage = nil
    }

    // MARK: - Private

    private func performPinLogin() async {
        isLoading = true
        pinError  = nil
        defer { isLoading = false }

        // Try the PIN against every registered user — whoever matches gets logged in.
        // This is necessary because the single keypad has no user-selection step.
        let matchedUser = LocalUserRegistry.shared.all.first { user in
            LocalUserStore.shared.validatePin(pinInput, forUser: user.username)
        }

        guard let user = matchedUser else {
            pinError = L10n.Auth.Login.pinErrorInvalid
            pinInput = ""
            return
        }

        LocalUserStore.shared.saveUser(
            username:     user.username,
            email:        user.email,
            facilityId:   user.facilityId,
            facilityName: user.facilityName,
            firstName:    user.firstName,
            lastName:     user.lastName
        )
        authService.restoreLocalSession(
            username:     user.username,
            email:        user.email,
            facilityId:   user.facilityId,
            facilityName: user.facilityName,
            firstName:    user.firstName,
            lastName:     user.lastName
        )
        diContainer.enableOnlineMode()
        diContainer.clearRecordingSession()
        configureAutoLock()
        pinInput = ""
        router.navigate(to: .patientSelection)
    }

    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try local login first — only for the user whose profile is stored on this device.
        // A different user's password hash may exist from a prior login, but their profile
        // data (facilityId, facilityName, PIN key) belongs to the last API-logged-in user.
        let store        = LocalUserStore.shared
        let storedEmail    = store.email?.lowercased()
        let storedUsername = store.username?.lowercased()
        let isStoredUser   = storedEmail == trimmedEmail.lowercased() ||
                             storedUsername == trimmedEmail.lowercased()

        if isStoredUser && store.canLoginLocally(email: trimmedEmail, password: password) {
            let infoSvc    = diContainer.appInfoService
            let facilityId   = store.facilityId   ?? infoSvc.facilityId
            let facilityName = store.facilityName ?? infoSvc.cached?.facilityName
            printStoredUserData(method: "LOCAL LOGIN (email+password)")
            // Clear any stale token — ensureValidToken will re-auth fresh when needed.
            authService.clearAccessToken()
            // Save under all possible lookup keys so ensureValidToken always finds it.
            store.savePasswordUnderAllKeys(password, typedInput: trimmedEmail)
            authService.restoreLocalSession(
                username:     store.username ?? trimmedEmail,
                email:        trimmedEmail,
                facilityId:   facilityId,
                facilityName: facilityName
            )
            diContainer.enableOnlineMode()
            saveToHistory(trimmedEmail)
            diContainer.clearRecordingSession()
            configureAutoLock()
            router.navigate(to: .patientSelection)
            return
        }

        // Fall back to API.
        do {
            try await authService.login(email: trimmedEmail, password: password)
            let data = authService.loginData
            // Save full profile and mark as verified so future logins work locally.
            let infoSvc = diContainer.appInfoService
            LocalUserStore.shared.saveUser(
                username:     data?.user.username ?? trimmedEmail,
                email:        data?.user.email,
                facilityId:   data?.facilityId   ?? infoSvc.facilityId,
                facilityName: data?.facilityName ?? infoSvc.cached?.facilityName,
                firstName:    data?.user.firstName,
                lastName:     data?.user.lastName
            )
            LocalUserStore.shared.savePasswordHash(password, for: trimmedEmail)
            // Save under all possible lookup keys so ensureValidToken always finds it.
            LocalUserStore.shared.savePasswordUnderAllKeys(password, typedInput: trimmedEmail)
            // Register user so PIN login can look them up by username.
            let infoFacilityId   = data?.facilityId   ?? infoSvc.facilityId
            let infoFacilityName = data?.facilityName ?? infoSvc.cached?.facilityName
            LocalUserRegistry.shared.upsert(LocalUserRecord(
                username:     data?.user.username ?? trimmedEmail,
                email:        data?.user.email,
                firstName:    data?.user.firstName,
                lastName:     data?.user.lastName,
                facilityId:   infoFacilityId,
                facilityName: infoFacilityName
            ))
            printStoredUserData(method: "API LOGIN")
            diContainer.enableOnlineMode()
            saveToHistory(trimmedEmail)
            diContainer.clearRecordingSession()
            configureAutoLock()
            router.navigate(to: .patientSelection)
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    private func printStoredUserData(method: String) {
        let store = LocalUserStore.shared
        let emailKey  = store.email
        let userKey   = store.username
        let pwByEmail = emailKey.flatMap  { store.storedPassword(for: $0) }
        let pwByUser  = userKey.flatMap   { store.storedPassword(for: $0) }
        print("┌─── \(method) ──────────────────────────────")
        print("│ username      : \(userKey    ?? "nil")")
        print("│ email         : \(emailKey   ?? "nil")")
        print("│ facilityId    : \(store.facilityId.map { String($0) } ?? "nil")")
        print("│ facilityName  : \(store.facilityName ?? "nil")")
        print("│ hasPin        : \(store.hasPin)")
        print("│ pw(byEmail)   : \(pwByEmail  != nil ? "✅ found" : "❌ nil")")
        print("│ pw(byUsername): \(pwByUser   != nil ? "✅ found" : "❌ nil")")
        print("└────────────────────────────────────────────")
    }

    private func configureAutoLock() {
        let secs = authService.loginData?.appSettings?.autolockSeconds ?? 0
        diContainer.autoLockManager.configure(timeoutSeconds: secs)
    }

    private func validateInputs() -> Bool {
        emailError    = Validators.validateUsername(email)
        passwordError = Validators.validatePassword(password)
        return emailError == nil && passwordError == nil
    }

    // MARK: - Field Enum

    enum Field {
        case email, password, pin
    }
}
