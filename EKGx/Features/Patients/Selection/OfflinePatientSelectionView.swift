

 //
//  OfflinePatientSelectionView.swift
//  EKGx
//
//  Patient selection in offline mode.
//  Shows locally saved patients only — no API calls made.
//

import SwiftUI

struct OfflinePatientSelectionView: View {

    @State private var viewModel: OfflinePatientSelectionViewModel

    init(viewModel: OfflinePatientSelectionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .background(AppColors.surfaceCard)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                HStack(spacing: 0) {
                    patientList
                        .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(width: 1)

                    rightPanel
                        .frame(width: 360)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreatePatient) {
            OfflineCreatePatientSheet(viewModel: viewModel)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
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
                Text("Offline Mode — Local Patients")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusWarning)
            }

            Spacer()

            // Offline badge
            Label("Offline", systemImage: "wifi.slash")
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.statusWarning)
                .padding(.horizontal, AppMetrics.spacing12)
                .padding(.vertical, AppMetrics.spacing6)
                .background(AppColors.statusWarning.opacity(0.1))
                .cornerRadius(AppMetrics.radiusMedium)
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
    }

    // MARK: - Patient List

    private var patientList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Saved Patients")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(viewModel.patients.count)")
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppMetrics.spacing28)
            .padding(.top, AppMetrics.spacing24)
            .padding(.bottom, AppMetrics.spacing16)

            if viewModel.patients.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: AppMetrics.spacing8) {
                        ForEach(viewModel.patients) { patient in
                            OfflinePatientRow(
                                patient: patient,
                                isSelected: viewModel.selected?.id == patient.id,
                                onTap: { viewModel.select(patient) }
                            )
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacing20)
                    .padding(.bottom, AppMetrics.spacing20)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.35))
            Text("No local patients yet")
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            Text("Create a patient below to proceed with the recording.")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.spacing32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, AppMetrics.spacing40)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: AppMetrics.spacing24) {
            Spacer()

            // Patient preview when selected
            if let patient = viewModel.selected {
                VStack(spacing: AppMetrics.spacing12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.brandPrimary)
                            .frame(width: 64, height: 64)
                        Text(patient.initials)
                            .font(.custom("Montserrat-SemiBold", size: 22))
                            .foregroundStyle(.white)
                    }
                    Text(patient.fullName)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(spacing: AppMetrics.spacing8) {
                        Text(patient.genderDisplay)
                        Text("·")
                        Text(patient.age)
                        if !patient.mrn.isEmpty {
                            Text("·")
                            Text(patient.mrn)
                        }
                    }
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppMetrics.spacing24)
                .frame(maxWidth: .infinity)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                        .stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1.5)
                )
                .padding(.horizontal, AppMetrics.spacing28)
            } else {
                VStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    Text("Select a patient from the list")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppMetrics.spacing28)
            }

            Spacer()

            // Action buttons
            VStack(spacing: AppMetrics.spacing12) {
                Button(action: { viewModel.confirm() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.PatientSelection.confirm)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(viewModel.canConfirm ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.35))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .disabled(!viewModel.canConfirm)

                Button(action: { viewModel.openCreatePatient() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Create New Patient")
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(AppColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.brandPrimary.opacity(0.08))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
            }
            .padding(.horizontal, AppMetrics.spacing28)
            .padding(.bottom, AppMetrics.spacing28)
        }
    }
}

// MARK: - Patient Row

private struct OfflinePatientRow: View {

    let patient: LocalPatient
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing14) {
                // Left accent
                if isSelected {
                    Rectangle()
                        .fill(AppColors.brandPrimary)
                        .frame(width: 4)
                        .cornerRadius(2)
                }

                // Avatar
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Text(patient.initials)
                        .font(.custom("Montserrat-SemiBold", size: 16))
                        .foregroundStyle(isSelected ? .white : AppColors.brandPrimary)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(patient.fullName)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(spacing: 5) {
                        Text(patient.genderDisplay)
                        Text("·")
                        Text(patient.age)
                        if !patient.mrn.isEmpty {
                            Text("·")
                            Text(patient.mrn)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.brandPrimary)
                }
            }
            .padding(.vertical, AppMetrics.spacing12)
            .padding(.trailing, AppMetrics.spacing16)
            .padding(.leading, isSelected ? 0 : AppMetrics.spacing16)
            .background(
                isSelected
                    ? AppColors.brandPrimary.opacity(0.07)
                    : AppColors.surfaceCard
            )
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .stroke(
                        isSelected ? AppColors.brandPrimary.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.hapticPlain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Create Patient Sheet

private struct OfflineCreatePatientSheet: View {

    @Bindable var viewModel: OfflinePatientSelectionViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppMetrics.spacing20) {
                    ETextField(
                        label: L10n.PatientSelection.Search.firstName,
                        placeholder: L10n.PatientSelection.Search.firstName,
                        systemImage: "person",
                        text: $viewModel.createFirstName,
                        errorMessage: viewModel.createFirstNameError,
                        textContentType: .givenName,
                        autocapitalization: .characters
                    )
                    .onChange(of: viewModel.createFirstName) { _, _ in viewModel.createFirstNameError = nil }

                    ETextField(
                        label: L10n.PatientSelection.Search.lastName,
                        placeholder: L10n.PatientSelection.Search.lastName,
                        systemImage: "person",
                        text: $viewModel.createLastName,
                        errorMessage: viewModel.createLastNameError,
                        textContentType: .familyName,
                        autocapitalization: .characters
                    )
                    .onChange(of: viewModel.createLastName) { _, _ in viewModel.createLastNameError = nil }

                    // Date of Birth
                    DOBTextField(
                        label: L10n.PatientSelection.Search.dob,
                        date: Binding(
                            get: { viewModel.createDob },
                            set: { viewModel.createDob = $0; viewModel.createDobError = nil }
                        ),
                        errorMessage: viewModel.createDobError
                    )

                    // Gender Picker
                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        Text(L10n.PatientSelection.Create.gender)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.textSecondary)
                        Picker("", selection: $viewModel.createGender) {
                            ForEach(viewModel.genderOptions, id: \.self) { g in
                                Text(g).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    ETextField(
                        label: L10n.PatientSelection.Search.mrn,
                        placeholder: L10n.PatientSelection.Search.mrn,
                        systemImage: "number",
                        text: $viewModel.createMRN
                    )

                    Spacer(minLength: AppMetrics.spacing20)
                }
                .padding(AppMetrics.spacing24)
            }
            .navigationTitle("New Local Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.PatientSelection.Create.cancel) { viewModel.cancelCreatePatient() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.PatientSelection.Create.submit) { viewModel.submitCreatePatient() }
                        .font(AppTypography.bodyMedium)
                }
            }
        }
    }
}
