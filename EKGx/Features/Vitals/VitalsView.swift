import SwiftUI

// MARK: - VitalsView

struct VitalsView: View {

    @State var viewModel: VitalsViewModel

    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                patientCard
                content
            }
        }
        .sheet(isPresented: $vm.showConnectSheet) {
            if let vital = viewModel.selectedVital {
                DeviceConnectSheet(vital: vital, viewModel: viewModel)
            }
        }
        .onAppear { viewModel.activate() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            Text(viewModel.facilityName)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button(action: viewModel.navigateBack) {
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

                Spacer()

                Button(action: viewModel.openExams) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)

                        if viewModel.examCount > 0 {
                            Text("\(viewModel.examCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 17, height: 17)
                                .background(AppColors.brandPrimary)
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        HStack(spacing: AppMetrics.spacing16) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.18))
                    .frame(width: 56, height: 56)
                Text(viewModel.patient.initials)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.brandPrimary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: AppMetrics.spacing16) {
                    if !viewModel.patient.birthDate.isEmpty {
                        Label("\(viewModel.patient.birthDate) · \(viewModel.patient.age)", systemImage: "calendar")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if !viewModel.patient.gender.isEmpty {
                        Label(viewModel.patient.genderDisplay, systemImage: "person.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if let mrn = viewModel.patient.medicalRecordNumber, !mrn.isEmpty {
                    Label("MRN \(mrn)", systemImage: "number")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(spacing: AppMetrics.spacing16) {
                // Top row: wide cards (ekg + echo)
                let wideVitals = VitalType.allCases.filter(\.isWideCard)
                HStack(spacing: AppMetrics.spacing16) {
                    ForEach(wideVitals) { type in
                        VitalCard(
                            type: type,
                            state: viewModel.connectionState(for: type),
                            onTap: { handleTap(type) },
                            onConnectTap: { viewModel.openConnectSheet(for: type) }
                        )
                    }
                }

                // 3-column grid for remaining vitals
                let gridVitals = VitalType.allCases.filter { !$0.isWideCard }
                let columns = Array(repeating: GridItem(.flexible(), spacing: AppMetrics.spacing16), count: 3)
                LazyVGrid(columns: columns, spacing: AppMetrics.spacing16) {
                    ForEach(gridVitals) { type in
                        VitalCard(
                            type: type,
                            state: viewModel.connectionState(for: type),
                            onTap: { handleTap(type) },
                            onConnectTap: { viewModel.openConnectSheet(for: type) }
                        )
                    }
                }
            }
            .padding(AppMetrics.spacing16)
        }
    }

    private func handleTap(_ type: VitalType) {
        guard type.isAvailable else { return }
        switch type {
        case .ekg: viewModel.startEKG()
        default:   break
        }
    }
}

// MARK: - Vital Card

private struct VitalCard: View {

    let type: VitalType
    let state: DeviceConnectionState
    let onTap: () -> Void
    let onConnectTap: () -> Void

    private var badgeLabel: String {
        switch state {
        case .connected:    return "Connected"
        case .searching:    return "Searching..."
        case .connecting:   return "Connecting..."
        case .disconnected: return "Connect"
        }
    }

    private var badgeColor: Color {
        switch state {
        case .connected:              return AppColors.statusSuccess
        case .searching, .connecting: return AppColors.statusWarning
        case .disconnected:           return AppColors.statusCritical
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: onTap) {
                VStack(spacing: AppMetrics.spacing12) {
                    Spacer()
                    Image(systemName: type.icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(type.iconColor)
                    if type.usesLogoImage {
                        AppImages.logo
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                    } else {
                        Text(type.title)
                            .font(AppTypography.bodySemibold)
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
//            .disabled(!type.isAvailable)

            // Tappable status badge
            Button(action: onConnectTap) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 9, height: 9)
                    Text(badgeLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.30))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(AppMetrics.spacing12)
        }
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusLarge)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

// MARK: - Device Connect Sheet

private struct DeviceConnectSheet: View {

    let vital: VitalType
    @State var viewModel: VitalsViewModel
    @Environment(\.dismiss) private var dismiss

    private var state: DeviceConnectionState { viewModel.connectionState(for: vital) }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing32) {
                header
                statusBlock
                actionButtons
                Spacer()
            }
            .padding(AppMetrics.spacing32)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Connect Device")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(vital.connectDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusBlock: some View {
        VStack(spacing: AppMetrics.spacing16) {
            DeviceConnectButton(state: state) {
                state == .disconnected ? viewModel.connect() : viewModel.disconnect()
            }
            .frame(maxWidth: .infinity)

            if let name = viewModel.connectedDeviceName(for: vital) {
                Label(name, systemImage: "checkmark.seal.fill")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.statusSuccess)
            }
        }
    }

    private var isBusy: Bool { state == .searching || state == .connecting }

    private var actionButtons: some View {
        VStack(spacing: AppMetrics.spacing12) {
            Button(action: viewModel.connect) {
                HStack(spacing: AppMetrics.spacing10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Connect \(vital.title) Device")
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(isBusy ? AppColors.brandPrimary.opacity(0.4) : AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.plain)
            .disabled(isBusy)

            Button(action: viewModel.connectDemo) {
                HStack(spacing: AppMetrics.spacing10) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Use Demo Device")
                        .font(AppTypography.bodyMedium)
                }
                .foregroundStyle(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary.opacity(0.10))
                .cornerRadius(AppMetrics.radiusMedium)
                .overlay(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(AppColors.brandPrimary.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isBusy)

            if state != .disconnected {
                Button(action: { viewModel.disconnect(); dismiss() }) {
                    Text("Disconnect")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.statusCritical)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
