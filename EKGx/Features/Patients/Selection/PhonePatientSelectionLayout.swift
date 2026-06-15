//
//  PhonePatientSelectionLayout.swift
//  EKGx
//
//  Single-column patient selection screen for iPhone.
//

import SwiftUI

struct PhonePatientSelectionLayout: View {

    @Bindable var viewModel: PatientSelectionViewModel
    @State private var searchMode: SearchMode = .name
    @State private var showQRScanner = false

    enum SearchMode: CaseIterable {
        case name, mrn
        var displayTitle: String {
            switch self {
            case .name: return L10n.PatientSelection.Search.nameSegment
            case .mrn:  return L10n.PatientSelection.Search.mrnSegment
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                phoneNavBar
                phoneSearchSection
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                phonePatientList
            }

            createFAB
                .padding(.trailing, AppMetrics.spacing20)
                .padding(.bottom, AppMetrics.spacing20)
        }
        .background(AppColors.surfaceBackground)
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { scanned in
                viewModel.searchMRN = scanned
                showQRScanner = false
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Nav Bar

    private var phoneNavBar: some View {
        ZStack {
            Text(L10n.PatientSelection.Nav.title)
                .font(AppTypography.phoneBodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            HStack(spacing: AppMetrics.spacing8) {
                Button(action: viewModel.openMenu) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)

                Spacer()

                Button(action: viewModel.navigateToWaitingList) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)

                        if viewModel.waitingListBadgeCount > 0 {
                            Text("\(viewModel.waitingListBadgeCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppColors.brandPrimary)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(.hapticPlain)

                Button(action: viewModel.logout) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.statusCritical)
                        .frame(width: 38, height: 38)
                        .background(AppColors.statusCritical.opacity(0.08))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .frame(height: 52)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Search Section

    private var phoneSearchSection: some View {
        VStack(spacing: AppMetrics.spacing10) {
            modeToggle
            if searchMode == .name {
                nameFields
            } else {
                mrnFields
            }
            if viewModel.isSearchActive {
                Button(action: viewModel.clearSearch) {
                    HStack(spacing: AppMetrics.spacing6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.PatientSelection.Search.clearButton)
                            .font(AppTypography.phoneCaption)
                    }
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .padding(.vertical, AppMetrics.spacing12)
        .background(AppColors.surfaceBackground)
    }

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Button {
                    if searchMode != mode {
                        searchMode = mode
                        viewModel.clearSearch()
                    }
                } label: {
                    Text(mode.displayTitle)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(searchMode == mode ? AppColors.ecgBackground : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(searchMode == mode ? AppColors.accentTeal : Color.clear)
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
                .animation(.easeInOut(duration: 0.15), value: searchMode)
            }
        }
        .padding(4)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusMedium + 4)
    }

    private var nameFields: some View {
        VStack(spacing: AppMetrics.spacing10) {
            ETextField(
                placeholder: L10n.PatientSelection.Search.firstName,
                systemImage: "person",
                text: $viewModel.searchFirstName,
                autocapitalization: .characters
            )
            ETextField(
                placeholder: L10n.PatientSelection.Search.lastName,
                systemImage: "person",
                text: $viewModel.searchLastName,
                autocapitalization: .characters
            )
            DOBTextField(date: $viewModel.searchDob)
        }
    }

    private var mrnFields: some View {
        VStack(spacing: AppMetrics.spacing10) {
            ETextField(
                label: L10n.PatientSelection.Search.mrn,
                placeholder: L10n.PatientSelection.Search.mrnPlaceholder,
                systemImage: "number",
                text: $viewModel.searchMRN
            )
            Button { showQRScanner = true } label: {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .medium))
                    Text(L10n.PatientSelection.Search.scanQRCode)
                        .font(AppTypography.phoneBody)
                }
                .foregroundStyle(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppMetrics.spacing10)
                .background(AppColors.brandPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                .overlay(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium).stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.hapticPlain)
        }
    }

    // MARK: - Patient List

    private var phonePatientList: some View {
        Group {
            if viewModel.filteredPatients.isEmpty && !viewModel.isSearchActive {
                phoneEmptyState
            } else if viewModel.filteredPatients.isEmpty && viewModel.isSearchActive {
                ScrollView {
                    phoneCreateCell
                        .padding(AppMetrics.spacing16)
                }
                .ignoresSafeArea(.keyboard)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppMetrics.spacing10) {
                        ForEach(viewModel.filteredPatients) { patient in
                            PatientRow(
                                patient: patient,
                                isSelected: viewModel.selected?.id == patient.id,
                                examCount: viewModel.examCount(for: patient),
                                onEdit:       { viewModel.openEditPatient(patient) },
                                onHistoryTap: { viewModel.navigateToHistory(patient) }
                            ) {
                                viewModel.navigateToVitals(patient)
                            }
                        }
                        if viewModel.isSearchActive {
                            phoneCreateCell
                        }
                        Color.clear.frame(height: 88)
                    }
                    .padding(AppMetrics.spacing16)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }

    private var phoneEmptyState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.25))
            Text(L10n.PatientSelection.Prompt.title)
                .font(AppTypography.phoneTitle)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(L10n.PatientSelection.Prompt.subtitle)
                .font(AppTypography.phoneCallout)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phoneCreateCell: some View {
        Button(action: viewModel.openCreatePatientWithSearchData) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.10))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    let name = "\(viewModel.searchFirstName) \(viewModel.searchLastName)"
                        .trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        Text(name)
                            .font(AppTypography.phoneBodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    if !viewModel.searchMRN.isEmpty {
                        Label(viewModel.searchMRN, systemImage: "number")
                            .font(AppTypography.phoneCaption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(CompactLabelStyle())
                    }
                    Text(L10n.PatientSelection.CreateCell.hint)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.brandPrimary)
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.brandPrimary)
            }
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing12)
            .background(AppColors.brandPrimary.opacity(0.04))
            .cornerRadius(AppMetrics.radiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(AppColors.brandPrimary.opacity(0.35))
            )
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: - FAB

    private var createFAB: some View {
        Button(action: viewModel.openCreatePatient) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.brandPrimary)
                .clipShape(Circle())
                .shadow(color: AppColors.brandPrimary.opacity(0.45), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.hapticPlain)
    }
}
