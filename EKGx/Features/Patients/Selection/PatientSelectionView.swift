//
//  PatientSelectionView.swift
//  EKGx
//
//  Unified patient selection — patients are device-local (Core Data).
//  Left panel: live search + patient list.
//  Right panel: selected patient detail + confirm.
//

import SwiftUI
import Vision
import VisionKit

struct PatientSelectionView: View {

    @State private var viewModel: PatientSelectionViewModel
    @State private var searchMode: SearchMode = .name
    @State private var showQRScanner = false

    enum SearchMode: CaseIterable {
        case name
        case mrn

        var displayTitle: String {
            switch self {
            case .name: return L10n.PatientSelection.Search.nameSegment
            case .mrn:  return L10n.PatientSelection.Search.mrnSegment
            }
        }
    }

    init(viewModel: PatientSelectionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                HStack(spacing: 0) {
                    leftPanel
                        .frame(width: 360)

                    divider

                    centerPanel
                        .frame(maxWidth: .infinity)

                    divider

                    rightPanel
                        .frame(width: 360)
                }
            }

            // Side menu overlay
            SideMenuView(
                userFullName:        viewModel.menuUserFullName,
                userEmail:           viewModel.menuUserEmail,
                userInitials:        viewModel.menuUserInitials,
                userRoleDisplayName: viewModel.menuUserRole,
                isVisible:           viewModel.isMenuVisible,
                onDismiss:           { viewModel.closeMenu() },
                onSettings:          { viewModel.navigateToSettings() },
                onMyAccount:         { viewModel.navigateToMyAccount() },
                onSupport:           { viewModel.navigateToSupport() },
                onFAQ:               { viewModel.navigateToFAQ() },
                onIndicationsForUse: { viewModel.navigateToIndicationsForUse() },
                onLogout:            { viewModel.logout() }
            )
        }
        .sheet(isPresented: $viewModel.showCreatePatient) {
            CreatePatientSheet(viewModel: viewModel)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showEditPatient) {
            EditPatientSheet(viewModel: viewModel)
                .interactiveDismissDisabled()
        }
        .alert(L10n.PatientSelection.Delete.alertTitle, isPresented: $viewModel.showDeleteConfirm) {
            Button(L10n.PatientSelection.Delete.confirm, role: .destructive) { viewModel.deleteConfirmed() }
            Button(L10n.Common.cancel, role: .cancel) { viewModel.cancelDelete() }
        } message: {
            Text(L10n.PatientSelection.Delete.message)
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { scanned in
                viewModel.searchMRN = scanned
                showQRScanner = false
            }
            .ignoresSafeArea()
        }
        .onAppear { viewModel.activate() }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.borderSubtle.opacity(0.6))
            .frame(width: 1)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            // Title — truly centered regardless of button widths
            Text(L10n.PatientSelection.Nav.title)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                // Menu button
                Button(action: { viewModel.openMenu() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                        Text(L10n.Home.Nav.menuButton)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
                }

                Spacer()

                // Logout button
                Button(action: { viewModel.logout() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "power")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.Menu.logout)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.statusCritical)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.statusCritical.opacity(0.08))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Left Panel: Search Fields Only

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing16) {
                Text(L10n.PatientSelection.Search.title)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)

                brandSegment

                if searchMode == .name {
                    ETextField(
                        label: L10n.PatientSelection.Search.firstName,
                        placeholder: L10n.PatientSelection.Search.firstName,
                        systemImage: "person",
                        text: $viewModel.searchFirstName
                    )
                    ETextField(
                        label: L10n.PatientSelection.Search.lastName,
                        placeholder: L10n.PatientSelection.Search.lastName,
                        systemImage: "person",
                        text: $viewModel.searchLastName
                    )
                    DOBTextField(
                        label: L10n.PatientSelection.Search.dob,
                        date: $viewModel.searchDob
                    )
                } else {
                    ETextField(
                        label: L10n.PatientSelection.Search.mrn,
                        placeholder: L10n.PatientSelection.Search.mrnPlaceholder,
                        systemImage: "number",
                        text: $viewModel.searchMRN
                    ) {
                        Button { showQRScanner = true } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(AppColors.brandPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.isSearchActive {
                    Button(action: viewModel.clearSearch) {
                        HStack(spacing: AppMetrics.spacing6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                            Text(L10n.PatientSelection.Search.clearButton)
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppMetrics.spacing20)

            Spacer()

            VStack(alignment: .center, spacing: AppMetrics.spacing8) {
                AppImages.logo
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)

                Text(L10n.Branding.tagline)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textOnDark.opacity(0.7))
                    .lineLimit(2)
            }.frame(maxWidth: .infinity)
            
            Spacer()
        }
        .background(AppColors.surfaceCard)
    }

    private var brandSegment: some View {
        HStack(spacing: 4) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Button {
                    if searchMode != mode {
                        searchMode = mode
                        viewModel.clearSearch()
                    }
                } label: {
                    Text(mode.displayTitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(searchMode == mode ? .white : AppColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(searchMode == mode ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.08))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppColors.brandPrimary.opacity(0.08))
        .cornerRadius(AppMetrics.radiusMedium + 4)
    }

    // MARK: - Center Panel: Patient List

    private var centerPanel: some View {
        VStack(spacing: 0) {
            if viewModel.filteredPatients.isEmpty && !viewModel.isSearchActive {
                emptyState
            } else if viewModel.filteredPatients.isEmpty && viewModel.isSearchActive {
                // No matches — show only the create cell
                ScrollView {
                    VStack(spacing: AppMetrics.spacing10) {
                        createPatientCell
                    }
                    .padding(AppMetrics.spacing16)
                }
            } else {
                patientList
            }
        }
    }


    private var patientList: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacing10) {
                ForEach(viewModel.filteredPatients) { patient in
                    PatientRow(
                        patient: patient,
                        isSelected: viewModel.selected?.id == patient.id,
                        examCount: viewModel.examCount(for: patient),
                        onEdit:       { viewModel.openEditPatient(patient) },
                        onDelete:     { viewModel.confirmDelete(patient) },
                        onHistoryTap: { viewModel.navigateToHistory(patient) }
                    ) {
                        viewModel.navigateToVitals(patient)
                    }
                }
                if viewModel.isSearchActive {
                    createPatientCell
                }
            }
            .padding(AppMetrics.spacing16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: viewModel.isSearchActive ? "person.slash" : "person.2")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.25))
            Text(viewModel.isSearchActive ? L10n.PatientSelection.Results.empty : L10n.PatientSelection.Prompt.title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            Text(viewModel.isSearchActive ? L10n.PatientSelection.Results.emptySubtitle : L10n.PatientSelection.Prompt.subtitle)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Create Patient Cell (appears in search results)

    private var createPatientCell: some View {
        Button(action: viewModel.openCreatePatientWithSearchData) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    let name = "\(viewModel.searchFirstName) \(viewModel.searchLastName)"
                        .trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        Text(name)
                            .font(AppTypography.bodySemibold)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    if !viewModel.searchMRN.isEmpty {
                        Label(viewModel.searchMRN, systemImage: "number")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(CompactLabelStyle())
                    }
                    Text(L10n.PatientSelection.CreateCell.hint)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.brandPrimary)
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AppColors.brandPrimary)
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing14)
            .background(AppColors.brandPrimary.opacity(0.04))
            .cornerRadius(AppMetrics.radiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(AppColors.brandPrimary.opacity(0.35))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Right Panel: Selection + Actions

    private var rightPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            if let patient = viewModel.selected {
                selectedDetail(patient)
            } else {
                noSelectionHint
            }

            Spacer()

            actionBar
        }
    }

    private var noSelectionHint: some View {
        VStack(spacing: AppMetrics.spacing12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.3))
            Text(L10n.PatientSelection.Prompt.selectHint)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func selectedDetail(_ patient: LocalPatient) -> some View {
        VStack(spacing: AppMetrics.spacing16) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.15))
                    .frame(width: 72, height: 72)
                Text(patient.initials)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.brandPrimary)
            }

            VStack(spacing: AppMetrics.spacing4) {
                Text(patient.fullName)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: AppMetrics.spacing8) {
                    if !patient.birthDate.isEmpty {
                        Label(patient.age, systemImage: "calendar")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if !patient.gender.isEmpty {
                        Text("·").foregroundStyle(AppColors.borderSubtle)
                        Text(patient.genderDisplay)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if !patient.mrn.isEmpty {
                    Text("\(L10n.PatientSelection.Search.mrn): \(patient.mrn)")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textPrimary)
                }

                if !patient.createdBy.isEmpty {
                    Label("Added by \(patient.createdBy)", systemImage: "person.fill.checkmark")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, AppMetrics.spacing4)
                }
            }
        }
        .padding(.horizontal, AppMetrics.spacing28)
    }

    private var actionBar: some View {
        VStack(spacing: AppMetrics.spacing10) {
            Button(action: viewModel.openCreatePatient) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.PatientSelection.createNew)
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary.opacity(0.10))
                .cornerRadius(AppMetrics.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.brandPrimary.opacity(0.3), lineWidth: AppMetrics.borderWidth)
                )
            }
            .buttonStyle(.plain)

            if let patient = viewModel.selected {
                Button { viewModel.openEditPatient(patient) } label: {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.PatientSelection.Edit.button)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing20)
        .padding(.vertical, AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .top)
    }
}

// MARK: - Patient Row

private struct PatientRow: View {

    let patient: LocalPatient
    let isSelected: Bool
    let examCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onHistoryTap: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(isSelected ? 0.25 : 0.10))
                        .frame(width: 48, height: 48)
                    Text(patient.initials)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(patient.fullName)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppMetrics.spacing6) {
                        if !patient.birthDate.isEmpty {
                            Text(patient.age)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if !patient.gender.isEmpty {
                            GenderBadge(gender: patient.gender)
                        }
                        if !patient.mrn.isEmpty {
                            Text("·").foregroundStyle(AppColors.borderSubtle).font(AppTypography.caption)
                            Text("#\(patient.mrn)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    if !patient.createdBy.isEmpty {
                        Label(patient.createdBy, systemImage: "person")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(CompactLabelStyle())
                    }
                }

                Spacer(minLength: 0)

                // History badge — tappable, navigates to patient's exam history
                if examCount > 0 {
                    Button(action: onHistoryTap) {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .medium))
                            Text("\(examCount)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(AppColors.brandPrimary)
                        .frame(width: 48, height: 48)
                        .background(AppColors.brandPrimary.opacity(0.10))
                        .cornerRadius(AppMetrics.radiusMedium)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.borderSubtle)
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing12)
            .background(isSelected ? AppColors.brandPrimary.opacity(0.07) : AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(
                        isSelected ? AppColors.brandPrimary : AppColors.borderSubtle.opacity(0.6),
                        lineWidth: isSelected ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: {
                Label(L10n.PatientSelection.Edit.button, systemImage: "pencil")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label(L10n.PatientSelection.Delete.contextMenu, systemImage: "trash")
            }
        }
    }
}

// MARK: - Create Patient Sheet

struct CreatePatientSheet: View {

    @Bindable var viewModel: PatientSelectionViewModel
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
                                autocapitalization: .words
                            )
                            .focused($focused, equals: .lastName)
                            .onChange(of: viewModel.createLastName) { _, _ in viewModel.createLastNameError = nil }
                        }

                        DOBTextField(
                            label: L10n.PatientSelection.Create.dob,
                            date: $viewModel.createDob,
                            errorMessage: viewModel.createDobError
                        )
                        .onChange(of: viewModel.createDob) { _, _ in viewModel.createDobError = nil }

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
            Button(action: viewModel.cancelCreatePatient) {
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
            Button(action: viewModel.cancelCreatePatient) {
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

// MARK: - Edit Patient Sheet

struct EditPatientSheet: View {

    @Bindable var viewModel: PatientSelectionViewModel
    @FocusState private var focused: Field?
    enum Field { case firstName, lastName, mrn }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                        if let error = viewModel.editErrorMessage {
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
                                text: $viewModel.editFirstName,
                                errorMessage: viewModel.editFirstNameError,
                                autocapitalization: .words
                            )
                            .focused($focused, equals: .firstName)
                            .onChange(of: viewModel.editFirstName) { _, _ in viewModel.editFirstNameError = nil }
                            .onSubmit { focused = .lastName }

                            ETextField(
                                label: L10n.PatientSelection.Create.lastName,
                                placeholder: L10n.PatientSelection.Create.lastName,
                                systemImage: "person",
                                text: $viewModel.editLastName,
                                errorMessage: viewModel.editLastNameError,
                                autocapitalization: .words
                            )
                            .focused($focused, equals: .lastName)
                            .onChange(of: viewModel.editLastName) { _, _ in viewModel.editLastNameError = nil }
                        }

                        DOBTextField(
                            label: L10n.PatientSelection.Create.dob,
                            date: $viewModel.editDob,
                            errorMessage: viewModel.editDobError
                        )
                        .onChange(of: viewModel.editDob) { _, _ in viewModel.editDobError = nil }

                        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                            Text(L10n.PatientSelection.Create.gender)
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.textSecondary)
                            Picker("", selection: $viewModel.editGender) {
                                ForEach(viewModel.genderOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        ETextField(
                            label: L10n.PatientSelection.Create.mrn,
                            placeholder: L10n.PatientSelection.Create.mrnPlaceholder,
                            systemImage: "number",
                            text: $viewModel.editMRN,
                            errorMessage: viewModel.editMRNError
                        )
                        .focused($focused, equals: .mrn)
                        .onChange(of: viewModel.editMRN) { _, _ in viewModel.editMRNError = nil }
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
                Text(L10n.PatientSelection.Edit.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.PatientSelection.Edit.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(action: viewModel.cancelEditPatient) {
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
            Button(action: viewModel.cancelEditPatient) {
                Text(L10n.Common.cancel)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.plain)

            Button(action: { focused = nil; viewModel.submitEditPatient() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    if viewModel.isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(L10n.PatientSelection.Edit.submit)
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUpdating)
        }
        .padding(.horizontal, AppMetrics.spacing28)
        .padding(.vertical, AppMetrics.spacing20)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .top)
    }
}

// MARK: - Gender Badge (shared across patient cells)

struct GenderBadge: View {

    let gender: String

    private var isMale: Bool   { let g = gender.lowercased(); return g == "male"   || g == "m" }
    private var isFemale: Bool { let g = gender.lowercased(); return g == "female" || g == "f" }

    private var sfIcon: String { "person.fill" }

    private var label: String {
        if isMale   { return "Male" }
        if isFemale { return "Female" }
        return gender
    }

    private var color: Color {
        if isMale   { return Color(red: 0.22, green: 0.51, blue: 0.93) }
        if isFemale { return Color(red: 0.88, green: 0.33, blue: 0.60) }
        return AppColors.textSecondary
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: sfIcon)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Shared Label Style

private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - QR Scanner

private struct QRScannerView: UIViewControllerRepresentable {

    let onScanned: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr, .code128, .code39, .dataMatrix])],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScanned: (String) -> Void
        init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard let item = addedItems.first, case .barcode(let barcode) = item,
                  let value = barcode.payloadStringValue else { return }
            dataScanner.stopScanning()
            onScanned(value)
        }
    }
}
