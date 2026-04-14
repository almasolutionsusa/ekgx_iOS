//
//  PatientSelectionView.swift
//  EKGx
//
//  Dedicated full-screen route shown before entering the recording screen.
//  Layout (iPad landscape):
//
//  ┌──────────────────────────────────────────────────────────────────────┐
//  │  ← Back   Select Patient                                              │
//  ├────────────────────────────────┬─────────────────────────────────────┤
//  │  SEARCH FORM                   │  SEARCH RESULTS                      │
//  │  ┌──────────────────────────┐  │  ┌───────────────────────────────┐  │
//  │  │ First Name               │  │  │  JH  James Hartwell           │  │
//  │  │ Last Name (Optional)     │  │  │      Male · 59 · MRN-88210    │  │
//  │  │ Date of Birth            │  │  └───────────────────────────────┘  │
//  │  │ ─── OR ───                │  │  ...                                 │
//  │  │ MRN                      │  │                                      │
//  │  │ [ Search ]  [ Clear ]    │  │                                      │
//  │  └──────────────────────────┘  │                                      │
//  │                                │  [ Continue to Recording ]           │
//  └────────────────────────────────┴─────────────────────────────────────┘
//

import SwiftUI

struct PatientSelectionView: View {

    @State private var viewModel: PatientSelectionViewModel

    init(viewModel: PatientSelectionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                PatientSelectionNavBar(viewModel: viewModel)

                HStack(spacing: 0) {
                    PatientSearchForm(viewModel: viewModel)
                        .frame(width: 420)

                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(width: 1)

                    PatientResultsPanel(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreatePatient) {
            CreatePatientSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Nav Bar

private struct PatientSelectionNavBar: View {

    @Bindable var viewModel: PatientSelectionViewModel

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
                Text(L10n.PatientSelection.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.PatientSelection.Nav.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Search Form (Left Panel)

private struct PatientSearchForm: View {

    @Bindable var viewModel: PatientSelectionViewModel
    @FocusState private var focused: FocusedField?

    enum FocusedField { case firstName, lastName, mrn }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                Text(L10n.PatientSelection.Search.title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, AppMetrics.spacing24)

                // Name + DOB group
                VStack(spacing: AppMetrics.spacing14) {
                    ETextField(
                        label: L10n.PatientSelection.Search.firstName,
                        placeholder: L10n.PatientSelection.Search.firstName,
                        systemImage: "person",
                        text: $viewModel.firstName,
                        errorMessage: viewModel.firstNameError,
                        textContentType: .givenName,
                        autocapitalization: .words
                    )
                    .focused($focused, equals: .firstName)
                    .onChange(of: viewModel.firstName) { _, _ in viewModel.firstNameError = nil }
                    .onSubmit { focused = .lastName }

                    ETextField(
                        label: L10n.PatientSelection.Search.lastName,
                        placeholder: L10n.PatientSelection.Search.lastName,
                        systemImage: "person",
                        text: $viewModel.lastName,
                        textContentType: .familyName,
                        autocapitalization: .words
                    )
                    .focused($focused, equals: .lastName)

                    DOBField(viewModel: viewModel)
                }

                // OR Divider
                HStack {
                    Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                    Text(L10n.PatientSelection.Search.or)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppMetrics.spacing12)
                    Rectangle().fill(AppColors.borderSubtle).frame(height: 1)
                }

                // MRN-only search
                ETextField(
                    label: L10n.PatientSelection.Search.mrn,
                    placeholder: L10n.PatientSelection.Search.mrn,
                    systemImage: "number",
                    text: $viewModel.mrn
                )
                .focused($focused, equals: .mrn)
                .onSubmit { focused = nil; viewModel.search() }

                // Buttons
                HStack(spacing: AppMetrics.spacing12) {
                    Button(action: {
                        focused = nil
                        viewModel.search()
                    }) {
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

                    Button(action: { viewModel.clearSearch() }) {
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
            .padding(.horizontal, AppMetrics.spacing28)
        }
    }
}

// MARK: - DOB Field

private struct DOBField: View {

    @Bindable var viewModel: PatientSelectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            Text(L10n.PatientSelection.Search.dob)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppMetrics.spacing12) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.dob ?? Date() },
                        set: { viewModel.dob = $0; viewModel.dobError = nil }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                Spacer()
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        viewModel.dobError != nil
                            ? AppColors.statusCritical
                            : AppColors.borderSubtle,
                        lineWidth: AppMetrics.borderWidth
                    )
            )

            if let err = viewModel.dobError {
                Text(err)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
            }
        }
    }
}

// MARK: - Results Panel (Right)

private struct PatientResultsPanel: View {

    @Bindable var viewModel: PatientSelectionViewModel

    var body: some View {
        VStack(spacing: 0) {

            if viewModel.isSearching {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                    .scaleEffect(1.4)
                Spacer()
            } else if viewModel.hasSearched && viewModel.results.isEmpty {
                emptyResults
            } else if !viewModel.hasSearched {
                promptState
            } else {
                resultsList
            }

            // Confirm button always visible at bottom
            confirmBar
        }
    }

    // MARK: - States

    private var promptState: some View {
        VStack(spacing: AppMetrics.spacing20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.25))
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.PatientSelection.Prompt.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.PatientSelection.Prompt.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppMetrics.spacing32)
    }

    private var emptyResults: some View {
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

                ForEach(viewModel.results) { patient in
                    PatientResultCard(
                        patient: patient,
                        isSelected: viewModel.selected?.id == patient.id
                    ) {
                        viewModel.select(patient)
                    }
                }
            }
            .padding(.horizontal, AppMetrics.spacing28)
            .padding(.top, AppMetrics.spacing20)
        }
    }

    private var confirmBar: some View {
        HStack(spacing: AppMetrics.spacing12) {
            if let selected = viewModel.selected {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selected.fullName)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    if !selected.mrn.isEmpty {
                        Text(selected.mrn)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            Spacer()

            // Secondary action: create new patient
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

            // Primary action: continue to recording
            Button(action: { viewModel.confirm() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.PatientSelection.confirm)
                        .font(AppTypography.bodyMedium)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing24)
                .frame(height: AppMetrics.buttonHeight)
                .background(viewModel.canConfirm ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.35))
                .cornerRadius(AppMetrics.radiusMedium)
            }
            .disabled(!viewModel.canConfirm)
        }
        .padding(.horizontal, AppMetrics.spacing28)
        .padding(.vertical, AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .top)
    }
}

// MARK: - Patient Result Card

private struct PatientResultCard: View {

    let patient: SearchedPatient
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 48, height: 48)
                    Text(initials)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(patient.fullName)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppMetrics.spacing10) {
                        if !patient.dob.isEmpty {
                            Label(patient.dob, systemImage: "calendar")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if !patient.gender.isEmpty {
                            Text("·")
                                .foregroundStyle(AppColors.borderSubtle)
                            Text(patient.gender)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if !patient.mrn.isEmpty {
                            Text("·")
                                .foregroundStyle(AppColors.borderSubtle)
                            Text(patient.mrn)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing16)
            .background(
                isSelected
                    ? AppColors.brandPrimary.opacity(0.08)
                    : AppColors.surfaceCard
            )
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
    }

    private var initials: String {
        let f = patient.firstName.first.map(String.init) ?? ""
        let l = patient.lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
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

                        // Error banner
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

                        // Name row
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
                            .onChange(of: viewModel.createFirstName) { _, _ in
                                viewModel.createFirstNameError = nil
                            }
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
                            .onChange(of: viewModel.createLastName) { _, _ in
                                viewModel.createLastNameError = nil
                            }
                        }

                        // DOB
                        CreateDOBField(viewModel: viewModel)

                        // Gender segmented
                        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                            Text(L10n.PatientSelection.Create.gender)
                                .font(AppTypography.captionBold)
                                .foregroundStyle(AppColors.textSecondary)

                            Picker("", selection: $viewModel.createGender) {
                                ForEach(viewModel.genderOptions, id: \.self) { opt in
                                    Text(opt).tag(opt)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // MRN
                        ETextField(
                            label: L10n.PatientSelection.Create.mrn,
                            placeholder: L10n.PatientSelection.Create.mrnPlaceholder,
                            systemImage: "number",
                            text: $viewModel.createMRN,
                            errorMessage: viewModel.createMRNError
                        )
                        .focused($focused, equals: .mrn)
                        .onChange(of: viewModel.createMRN) { _, _ in
                            viewModel.createMRNError = nil
                        }

                        Spacer(minLength: AppMetrics.spacing20)
                    }
                    .padding(.horizontal, AppMetrics.spacing28)
                    .padding(.top, AppMetrics.spacing24)
                }

                footer
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
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

    // MARK: - Footer

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

            Button(action: {
                focused = nil
                viewModel.submitCreatePatient()
            }) {
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

// MARK: - Create DOB Field

private struct CreateDOBField: View {

    @Bindable var viewModel: PatientSelectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            Text(L10n.PatientSelection.Create.dob)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppMetrics.spacing12) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

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
                .datePickerStyle(.compact)

                Spacer()
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        viewModel.createDobError != nil
                            ? AppColors.statusCritical
                            : AppColors.borderSubtle,
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
