//
//  PatientListView.swift
//  EKGx
//
//  Orders queue (patient waiting list) for the current facility.
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │  [← Back]   Orders (4)           [🔍 Search bar]          [+ Add]      │
//  ├─────────────────────────────────────────────────────────────────────────┤
//  │                                                                         │
//  │  ┌─────────────────────────────────────────────────────────────────┐   │
//  │  │  JH  James Hartwell   · EKG · MRN-88210      [Cancel]  09:32   │   │
//  │  └─────────────────────────────────────────────────────────────────┘   │
//  │  ...                                                                    │
//  └─────────────────────────────────────────────────────────────────────────┘
//

import SwiftUI

// MARK: - PatientListView

struct PatientListView: View {

    @State private var viewModel: PatientListViewModel

    init(viewModel: PatientListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                PatientListNavBar(viewModel: viewModel)
                orderContent
            }
        }
        .onAppear {
            viewModel.clearActiveOrder()
            viewModel.loadOrders()
        }
        .alert("Device Not Connected", isPresented: $viewModel.showDeviceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please connect to the EKG device from the home screen before starting a recording.")
        }
        .sheet(isPresented: $viewModel.showAddPatient) {
            AddOrderSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationSizing(.fitted)
        }
        .confirmationDialog(
            L10n.WaitingList.Cancel.confirm,
            isPresented: Binding(
                get: { viewModel.orderPendingCancel != nil },
                set: { if !$0 { viewModel.orderPendingCancel = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.WaitingList.Cancel.confirm, role: .destructive) { viewModel.cancelOrder() }
            Button(L10n.WaitingList.Cancel.keep, role: .cancel) { viewModel.orderPendingCancel = nil }
        } message: {
            if let order = viewModel.orderPendingCancel {
                Text(L10n.WaitingList.Cancel.message(order.patientFullName))
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var orderContent: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                .scaleEffect(1.4)
            Spacer()
        } else if let error = viewModel.errorMessage {
            errorState(error)
        } else if viewModel.filteredOrders.isEmpty {
            emptyState
        } else if viewModel.filteredOrders.isEmpty && !viewModel.searchQuery.isEmpty {
            emptyState
        } else {
            orderList
        }
    }

    // MARK: - Order List

    private var orderList: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacing12) {
                ForEach(Array(viewModel.filteredOrders.enumerated()), id: \.element.id) { index, order in
                    OrderRow(
                        order: order,
                        position: index + 1,
                        isActive: viewModel.activeOrderId == order.id,
                        onSelect: { viewModel.startRecording(for: order) },
                        onCancel: { viewModel.confirmCancel(order) }
                    )
                }
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing24)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing20) {
            Spacer()
            Image(systemName: viewModel.searchQuery.isEmpty ? "list.clipboard" : "magnifyingglass")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            VStack(spacing: AppMetrics.spacing8) {
                Text(viewModel.searchQuery.isEmpty ? L10n.WaitingList.Empty.title : L10n.Patients.Empty.noResults)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.searchQuery.isEmpty
                     ? L10n.WaitingList.Empty.subtitle
                     : L10n.Patients.Empty.noResultsSubtitle(viewModel.searchQuery))
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if !viewModel.searchQuery.isEmpty {
                Button(L10n.Patients.Empty.clearSearch) { viewModel.clearSearch() }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.brandPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing48)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppMetrics.spacing20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.statusCritical.opacity(0.6))
            Text(message)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") { viewModel.loadOrders() }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.brandPrimary)
            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing48)
    }
}

// MARK: - Navigation Bar

private struct PatientListNavBar: View {

    @Bindable var viewModel: PatientListViewModel

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {

            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Common.back)
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.borderSubtle.opacity(0.5))
                .cornerRadius(AppMetrics.radiusMedium)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.WaitingList.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Patients.Nav.totalCount(viewModel.totalCount))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            PatientSearchBar(
                query: $viewModel.searchQuery,
                onClear: { viewModel.clearSearch() }
            )
            .frame(width: 340)

            Button(action: { viewModel.openAddPatient() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.Patients.Nav.addButton)
                        .font(AppTypography.callout)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing20)
                .padding(.vertical, AppMetrics.spacing10)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Search Bar

private struct PatientSearchBar: View {

    @Binding var query: String
    let onClear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppMetrics.spacing10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFocused ? AppColors.brandPrimary : AppColors.textSecondary)

            TextField(L10n.Patients.Search.placeholder, text: $query)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppMetrics.spacing14)
        .frame(height: 44)
        .background(AppColors.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .strokeBorder(
                    isFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                    lineWidth: isFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Order Row

private struct OrderRow: View {

    let order: PatientOrder
    let position: Int
    let isActive: Bool
    let onSelect: () -> Void
    let onCancel: () -> Void

    private var avatarColor: Color {
        let colors: [Color] = [
            AppColors.brandPrimary, AppColors.brandSecondary,
            AppColors.statusInfo, AppColors.statusSuccess,
            Color(red: 0.45, green: 0.31, blue: 0.82),
            Color(red: 0.90, green: 0.45, blue: 0.20),
        ]
        return colors[Int(order.id) % colors.count]
    }

    private var initials: String {
        let f = order.patientFirstName?.first.map(String.init) ?? ""
        let l = order.patientLastName?.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    private var examBadgeColor: Color {
        switch order.examType {
        case "VITALS":     return AppColors.statusSuccess
        case "ULTRASOUND": return AppColors.statusInfo
        default:           return AppColors.brandPrimary
        }
    }

    var body: some View {
        Button(action: onSelect) { orderContent }
            .buttonStyle(.plain)
    }

    private var orderContent: some View {
        HStack(spacing: 0) {

            // Left accent strip with queue number
            VStack(spacing: AppMetrics.spacing4) {
                Text("#\(position)")
                    .font(AppTypography.captionBold)
                    .foregroundStyle(avatarColor)
            }
            .frame(width: 44)
            .frame(maxHeight: .infinity)
            .background(avatarColor.opacity(0.08))

            HStack(spacing: AppMetrics.spacing16) {

                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text(initials)
                        .font(.custom("Montserrat-SemiBold", size: 18))
                        .foregroundStyle(avatarColor)
                }

                // Patient info
                VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                    Text(order.patientFullName)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppMetrics.spacing10) {
                        if let mrn = order.patientMrn, !mrn.isEmpty {
                            HStack(spacing: AppMetrics.spacing4) {
                                Image(systemName: "number")
                                    .font(.system(size: 11, weight: .medium))
                                Text(mrn)
                                    .font(AppTypography.caption)
                            }
                            .foregroundStyle(AppColors.textSecondary)
                        }
                        if let dob = order.patientDob, !dob.isEmpty {
                            Text("·").foregroundStyle(AppColors.borderSubtle)
                            HStack(spacing: AppMetrics.spacing4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11, weight: .medium))
                                Text(formattedDob(dob))
                                    .font(AppTypography.caption)
                            }
                            .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }

                Spacer()

                // Exam type badge
                if let examType = order.examType {
                    Text(examType)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(examBadgeColor)
                        .padding(.horizontal, AppMetrics.spacing12)
                        .padding(.vertical, AppMetrics.spacing6)
                        .background(examBadgeColor.opacity(0.12))
                        .cornerRadius(AppMetrics.radiusSmall)
                }

                // Time added
                if let createdAt = order.createdAt {
                    Text(timeLabel(from: createdAt))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }

                // Cancel button
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.statusCritical.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing20)
        }
        .frame(minHeight: 80)
        .background(isActive ? AppColors.brandPrimary.opacity(0.06) : AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(
                    isActive ? AppColors.brandPrimary.opacity(0.5) : AppColors.borderSubtle.opacity(0.5),
                    lineWidth: isActive ? 1.5 : AppMetrics.borderWidth
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func formattedDob(_ raw: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.timeZone = TimeZone(identifier: "UTC")
        guard let date = parser.date(from: raw) else { return raw }
        let display = DateFormatter()
        display.dateFormat = "M/d/yyyy"
        return display.string(from: date)
    }

    private func timeLabel(from iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return "" }
        let display = DateFormatter()
        display.dateFormat = "HH:mm"
        return display.string(from: date)
    }
}

// MARK: - Add Order Sheet (search patient → confirm → create order)

struct AddOrderSheet: View {

    @Bindable var viewModel: PatientListViewModel
    @FocusState private var focused: FocusedField?

    enum FocusedField { case firstName, lastName, mrn }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                HStack(spacing: 0) {
                    // Left: patient search form
                    searchForm
                        .frame(width: 380)

                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(width: 1)

                    // Right: results
                    searchResultsPanel
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreatePatient) {
            OrderCreatePatientSheet(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.WaitingList.Add.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.WaitingList.Add.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(action: { viewModel.closeAddPatient() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppMetrics.spacing28)
        .padding(.vertical, AppMetrics.spacing20)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Search Form (left panel)

    private var searchForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                Text(L10n.PatientSelection.Search.title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppMetrics.spacing24)

                VStack(spacing: AppMetrics.spacing14) {
                    ETextField(
                        label: L10n.PatientSelection.Search.firstName,
                        placeholder: L10n.PatientSelection.Search.firstName,
                        systemImage: "person",
                        text: $viewModel.searchFirstName,
                        errorMessage: viewModel.searchFirstNameError,
                        textContentType: .givenName,
                        autocapitalization: .words
                    )
                    .focused($focused, equals: .firstName)
                    .onChange(of: viewModel.searchFirstName) { _, _ in viewModel.searchFirstNameError = nil }
                    .onSubmit { focused = .lastName }

                    ETextField(
                        label: L10n.PatientSelection.Search.lastName,
                        placeholder: L10n.PatientSelection.Search.lastName,
                        systemImage: "person",
                        text: $viewModel.searchLastName,
                        textContentType: .familyName,
                        autocapitalization: .words
                    )
                    .focused($focused, equals: .lastName)

                    AddOrderDOBField(viewModel: viewModel)
                }

                HStack {
                    Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                    Text(L10n.PatientSelection.Search.or)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppMetrics.spacing12)
                    Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                }

                ETextField(
                    label: L10n.PatientSelection.Search.mrn,
                    placeholder: L10n.PatientSelection.Search.mrn,
                    systemImage: "number",
                    text: $viewModel.searchMRN
                )
                .focused($focused, equals: .mrn)
                .onSubmit { focused = nil; viewModel.searchPatients() }

                HStack(spacing: AppMetrics.spacing12) {
                    Button(action: { focused = nil; viewModel.searchPatients() }) {
                        HStack(spacing: AppMetrics.spacing8) {
                            if viewModel.isSearching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text(L10n.PatientSelection.Search.button)
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(AppMetrics.radiusMedium)
                    }
                    .disabled(viewModel.isSearching)

                    Button(action: { viewModel.clearPatientSearch() }) {
                        Text(L10n.PatientSelection.Search.clearButton)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.horizontal, AppMetrics.spacing20)
                            .frame(height: AppMetrics.buttonHeight)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)
                    }
                }

                Spacer(minLength: AppMetrics.spacing20)
            }
            .padding(.horizontal, AppMetrics.spacing24)
        }
    }

    // MARK: - Results Panel (right panel)

    private var searchResultsPanel: some View {
        VStack(spacing: 0) {
            if viewModel.isSearching {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                    .scaleEffect(1.4)
                Spacer()
            } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                emptySearchResults
            } else if !viewModel.hasSearched {
                promptState
            } else {
                resultsList
            }

            confirmBar
        }
    }

    private var promptState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.25))
            Text(L10n.PatientSelection.Prompt.title)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
            Text(L10n.PatientSelection.Prompt.subtitle)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppMetrics.spacing32)
    }

    private var emptySearchResults: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: "person.slash")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text(L10n.PatientSelection.Results.empty)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            Text(L10n.PatientSelection.Results.emptySubtitle)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppMetrics.spacing32)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacing12) {
                Text(L10n.PatientSelection.Results.title)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppMetrics.spacing8)

                ForEach(viewModel.searchResults) { patient in
                    PatientResultCard(
                        patient: patient,
                        isSelected: viewModel.selectedPatient?.id == patient.id
                    ) {
                        viewModel.selectPatient(patient)
                    }
                }
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.top, AppMetrics.spacing16)
        }
    }

    private var confirmBar: some View {
        VStack(spacing: 0) {
            if let error = viewModel.addOrderError {
                HStack(spacing: AppMetrics.spacing10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.statusCritical)
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusCritical)
                }
                .padding(.horizontal, AppMetrics.spacing24)
                .padding(.vertical, AppMetrics.spacing10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.statusCritical.opacity(0.07))
            }

            HStack(spacing: AppMetrics.spacing12) {
                Spacer()

                Button(action: { viewModel.openCreatePatient() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.PatientSelection.createNew)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(AppColors.brandPrimary)
                    .padding(.horizontal, AppMetrics.spacing20)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.brandPrimary.opacity(0.10))
                    .cornerRadius(AppMetrics.radiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .strokeBorder(AppColors.brandPrimary.opacity(0.3), lineWidth: AppMetrics.borderWidth)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.confirmAddOrder() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        if viewModel.isAddingOrder {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text(L10n.WaitingList.Add.confirmButton)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing24)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(viewModel.canConfirmAdd ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.35))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .disabled(!viewModel.canConfirmAdd || viewModel.isAddingOrder)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing16)
            .background(AppColors.surfaceCard)
            .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .top)
        }
    }
}

// MARK: - DOB Field (local to add order sheet)

private struct AddOrderDOBField: View {

    @Bindable var viewModel: PatientListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            HStack(spacing: AppMetrics.spacing8) {
                Text(L10n.PatientSelection.Search.dob)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                if let date = viewModel.searchDob {
                    Text(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()))
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, AppMetrics.spacing8)
                        .padding(.vertical, AppMetrics.spacing4)
                        .background(AppColors.brandPrimary.opacity(0.1))
                        .cornerRadius(AppMetrics.radiusSmall)
                }
            }

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.searchDob ?? Date() },
                    set: { viewModel.searchDob = $0; viewModel.searchDobError = nil }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(maxWidth: .infinity, maxHeight: 120)
            .clipped()
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        viewModel.searchDobError != nil ? AppColors.statusCritical : AppColors.borderSubtle,
                        lineWidth: AppMetrics.borderWidth
                    )
            )

            if let err = viewModel.searchDobError {
                Text(err)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
            }
        }
    }
}

// MARK: - Create Patient Sheet (order flow variant)

private struct OrderCreatePatientSheet: View {

    @Bindable var viewModel: PatientListViewModel
    @FocusState private var focused: Field?
    enum Field { case firstName, lastName, mrn }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                        if let error = viewModel.createErrorMessage {
                            HStack(spacing: AppMetrics.spacing12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppColors.statusCritical)
                                Text(error)
                                    .font(AppTypography.callout)
                                    .foregroundStyle(AppColors.statusCritical)
                            }
                            .padding(AppMetrics.spacing16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.statusCritical.opacity(0.08))
                            .cornerRadius(AppMetrics.radiusMedium)
                        }

                        HStack(spacing: AppMetrics.spacing14) {
                            ETextField(
                                label: L10n.PatientSelection.Create.firstName,
                                placeholder: L10n.PatientSelection.Create.firstName,
                                systemImage: "person",
                                text: $viewModel.createFirstName,
                                errorMessage: viewModel.createFirstNameError,
                                textContentType: .givenName,
                                autocapitalization: .words
                            )
                            .focused($focused, equals: .firstName)
                            .onChange(of: viewModel.createFirstName) { _, _ in viewModel.createFirstNameError = nil }
                            .onSubmit { focused = .lastName }

                            ETextField(
                                label: L10n.PatientSelection.Create.lastName,
                                placeholder: L10n.PatientSelection.Create.lastName,
                                systemImage: "person",
                                text: $viewModel.createLastName,
                                errorMessage: viewModel.createLastNameError,
                                textContentType: .familyName,
                                autocapitalization: .words
                            )
                            .focused($focused, equals: .lastName)
                            .onChange(of: viewModel.createLastName) { _, _ in viewModel.createLastNameError = nil }
                        }

                        CreatePatientDOBField(viewModel: viewModel)

                        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                            Text(L10n.PatientSelection.Create.gender)
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.textSecondary)
                            Picker("", selection: $viewModel.createGender) {
                                ForEach(viewModel.genderOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        ETextField(
                            label: L10n.PatientSelection.Create.mrn,
                            placeholder: L10n.PatientSelection.Create.mrnPlaceholder,
                            systemImage: "number",
                            text: $viewModel.createMRN,
                            errorMessage: viewModel.createMRNError
                        )
                        .focused($focused, equals: .mrn)
                        .onChange(of: viewModel.createMRN) { _, _ in viewModel.createMRNError = nil }

                        Spacer(minLength: AppMetrics.spacing20)
                    }
                    .padding(.horizontal, AppMetrics.spacing28)
                    .padding(.top, AppMetrics.spacing24)
                }
                footer
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.PatientSelection.Create.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.PatientSelection.Create.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(action: { viewModel.cancelCreatePatient() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppMetrics.spacing28)
        .padding(.vertical, AppMetrics.spacing20)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    private var footer: some View {
        HStack(spacing: AppMetrics.spacing12) {
            Button(action: { viewModel.cancelCreatePatient() }) {
                Text(L10n.PatientSelection.Create.cancel)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.plain)

            Button(action: { focused = nil; viewModel.submitCreatePatient() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    if viewModel.isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(L10n.PatientSelection.Create.submit)
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCreating)
        }
        .padding(.horizontal, AppMetrics.spacing28)
        .padding(.vertical, AppMetrics.spacing20)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .top)
    }
}

// MARK: - Create Patient DOB Field

private struct CreatePatientDOBField: View {

    @Bindable var viewModel: PatientListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            HStack(spacing: AppMetrics.spacing8) {
                Text(L10n.PatientSelection.Create.dob)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                if let date = viewModel.createDob {
                    Text(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()))
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, AppMetrics.spacing8)
                        .padding(.vertical, AppMetrics.spacing4)
                        .background(AppColors.brandPrimary.opacity(0.1))
                        .cornerRadius(AppMetrics.radiusSmall)
                }
            }

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.createDob ?? Date() },
                    set: { viewModel.createDob = $0; viewModel.createDobError = nil }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(maxWidth: .infinity, maxHeight: 120)
            .clipped()
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        viewModel.createDobError != nil ? AppColors.statusCritical : AppColors.borderSubtle,
                        lineWidth: AppMetrics.borderWidth
                    )
            )

            if let err = viewModel.createDobError {
                Text(err)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
            }
        }
    }
}
