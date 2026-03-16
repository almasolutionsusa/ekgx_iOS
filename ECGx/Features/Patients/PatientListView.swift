//
//  PatientListView.swift
//  ECGx
//
//  Patient list — iPad landscape kiosk screen.
//
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │  [← Back]   Patients (12)          [🔍 Search bar]        [+ Add]      │
//  ├─────────────────────────────────────────────────────────────────────────┤
//  │                                                                         │
//  │  ┌──────────────────────────────┐   ┌──────────────────────────────┐   │
//  │  │  JH  James Hartwell         │   │  MS  Margaret Schultz        │   │
//  │  │      Male · 59 yrs          │   │      Female · 46 yrs         │   │
//  │  │      MRN-88210              │   │      MRN-88211               │   │
//  │  └──────────────────────────────┘   └──────────────────────────────┘   │
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
                patientContent
            }
        }
        .sheet(isPresented: $viewModel.showAddPatient) {
            AddPatientSheet(isPresented: $viewModel.showAddPatient)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var patientContent: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                .scaleEffect(1.4)
            Spacer()
        } else if viewModel.filteredPatients.isEmpty {
            emptyState
        } else {
            patientGrid
        }
    }

    // MARK: - Patient Grid

    private var patientGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppMetrics.spacing16),
                    GridItem(.flexible(), spacing: AppMetrics.spacing16),
                    GridItem(.flexible(), spacing: AppMetrics.spacing16),
                ],
                spacing: AppMetrics.spacing16
            ) {
                ForEach(viewModel.filteredPatients) { patient in
                    PatientCard(patient: patient) {
                        viewModel.selectPatient(patient)
                    }
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
            Image(systemName: viewModel.searchQuery.isEmpty ? "person.2.slash" : "magnifyingglass")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))

            VStack(spacing: AppMetrics.spacing8) {
                Text(viewModel.searchQuery.isEmpty ? L10n.Patients.Empty.noPatients : L10n.Patients.Empty.noResults)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.searchQuery.isEmpty
                     ? L10n.Patients.Empty.noPatientsSubtitle
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
}

// MARK: - Navigation Bar

private struct PatientListNavBar: View {

    @Bindable var viewModel: PatientListViewModel

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {

            // Back
            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Home.Nav.menuButton)
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.borderSubtle.opacity(0.5))
                .cornerRadius(AppMetrics.radiusMedium)
            }

            // Title + count
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Patients.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Patients.Nav.totalCount(viewModel.totalCount))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Search bar
            PatientSearchBar(
                query: $viewModel.searchQuery,
                onSearch: { viewModel.searchPatients() },
                onClear: { viewModel.clearSearch() }
            )
            .frame(width: 340)

            // Add patient
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
    let onSearch: () -> Void
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
                .onSubmit { onSearch() }
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

// MARK: - Patient Card

private struct PatientCard: View {

    let patient: Patient
    let onTap: () -> Void

    @State private var isPressed = false

    // Consistent accent color per patient based on their ID
    private var avatarColor: Color {
        let colors: [Color] = [
            AppColors.brandPrimary,
            AppColors.brandSecondary,
            AppColors.statusInfo,
            AppColors.statusSuccess,
            Color(red: 0.45, green: 0.31, blue: 0.82),  // purple
            Color(red: 0.90, green: 0.45, blue: 0.20),  // amber
        ]
        let index = abs((patient.id ?? 0)) % colors.count
        return colors[index]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {

                // Top accent strip + avatar
                HStack(alignment: .center, spacing: AppMetrics.spacing16) {
                    // Avatar circle
                    ZStack {
                        Circle()
                            .fill(avatarColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Text(patient.initials)
                            .font(AppTypography.title3)
                            .foregroundStyle(avatarColor)
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(patient.fullName)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: AppMetrics.spacing6) {
                            Text(patient.genderDisplay)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Text("·")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.borderSubtle)
                            Text(patient.age)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.borderSubtle)
                }
                .padding(.horizontal, AppMetrics.spacing20)
                .padding(.top, AppMetrics.spacing20)

                // Divider
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                    .padding(.horizontal, AppMetrics.spacing20)
                    .padding(.top, AppMetrics.spacing16)

                // Footer: IDs
                HStack(spacing: AppMetrics.spacing16) {
                    if let mrn = patient.medicalRecordNumber {
                        PatientBadge(icon: "number", label: mrn, color: AppColors.textSecondary)
                    }
                    if let pid = patient.patientId {
                        PatientBadge(icon: "person.badge.key", label: pid, color: AppColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppMetrics.spacing20)
                .padding(.vertical, AppMetrics.spacing14)
            }
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? -0.02 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Patient Badge

private struct PatientBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AppMetrics.spacing4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(label)
                .font(AppTypography.caption)
        }
        .foregroundStyle(color)
    }
}

// MARK: - Add Patient Sheet

private struct AddPatientSheet: View {

    @Binding var isPresented: Bool

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var birthDate = ""
    @State private var gender: Gender = .male
    @State private var mrn = ""

    enum Gender: String, CaseIterable {
        case male   = "Male"
        case female = "Female"
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Sheet header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                            Text(L10n.Patients.Add.sheetTitle)
                                .font(AppTypography.title2)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(L10n.Patients.Add.sheetSubtitle)
                                .font(AppTypography.callout)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()

                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(AppColors.borderSubtle.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppMetrics.spacing40)
                    .padding(.top, AppMetrics.spacing32)
                    .padding(.bottom, AppMetrics.spacing28)

                    // Divider
                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(height: 1)
                        .padding(.horizontal, AppMetrics.spacing40)

                    // ── Form fields
                    VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                        // Row 1: First + Last name
                        HStack(spacing: AppMetrics.spacing16) {
                            ETextField(
                                label: L10n.Patients.Add.firstName,
                                placeholder: L10n.Patients.Add.firstNamePH,
                                systemImage: "person",
                                text: $firstName,
                                textContentType: .givenName,
                                autocapitalization: .words
                            )
                            ETextField(
                                label: L10n.Patients.Add.lastName,
                                placeholder: L10n.Patients.Add.lastNamePH,
                                systemImage: nil,
                                text: $lastName,
                                textContentType: .familyName,
                                autocapitalization: .words
                            )
                        }

                        // Row 2: DOB + Gender
                        HStack(alignment: .top, spacing: AppMetrics.spacing16) {
                            ETextField(
                                label: L10n.Patients.Add.dateOfBirth,
                                placeholder: L10n.Patients.Add.dateOfBirthPH,
                                systemImage: "calendar",
                                text: $birthDate
                            )

                            // Gender toggle
                            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                                Text(L10n.Patients.Add.gender.uppercased())
                                    .font(AppTypography.captionBold)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .tracking(0.5)

                                HStack(spacing: AppMetrics.spacing8) {
                                    ForEach(Gender.allCases, id: \.self) { option in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) { gender = option }
                                        } label: {
                                            Text(option.rawValue)
                                                .font(AppTypography.callout)
                                                .foregroundStyle(gender == option ? .white : AppColors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: AppMetrics.textFieldHeight)
                                                .background(gender == option ? AppColors.brandPrimary : AppColors.surfaceCard)
                                                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                                        .strokeBorder(
                                                            gender == option ? AppColors.brandPrimary : AppColors.borderSubtle,
                                                            lineWidth: AppMetrics.borderWidth
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Row 3: MRN
                        ETextField(
                            label: L10n.Patients.Add.mrn,
                            placeholder: L10n.Patients.Add.mrnPH,
                            systemImage: "number",
                            text: $mrn
                        )
                    }
                    .padding(.horizontal, AppMetrics.spacing40)
                    .padding(.top, AppMetrics.spacing28)

                    // ── Actions
                    HStack(spacing: AppMetrics.spacing12) {
                        SecondaryButton(title: L10n.Patients.Add.cancelButton) { isPresented = false }
                        PrimaryButton(title: L10n.Patients.Add.submitButton, isLoading: false) {
                            // TODO: Wire to API
                            isPresented = false
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacing40)
                    .padding(.top, AppMetrics.spacing32)
                    .padding(.bottom, AppMetrics.spacing40)
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    PatientListView(viewModel: PatientListViewModel(router: router))
        .environment(router)
}
