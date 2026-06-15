//
//  AnalysisControlsMenu.swift
//  EKGx
//
//  Right-side slide-in controls panel with 5 actions:
//  Send to EMR · Reject ECG · Diagnosis · Visualization · Print
//

import SwiftUI

struct AnalysisControlsMenu: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { viewModel.showControlsMenu = false }

            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────
                HStack {
                    Text("Actions")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Button { viewModel.showControlsMenu = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.hapticPlain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                // ── 2 × 2 action grid ──────────────────────────────
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    let emrDisabled = viewModel.isLocalMode || viewModel.isAlreadySynced
                    let diagDisabled = viewModel.isLocalMode || viewModel.isAlreadySynced

                    actionTile(
                        icon: viewModel.isAlreadySynced ? "checkmark.seal.fill" : "arrow.up.to.line.circle.fill",
                        title: "Send to EMR",
                        subtitle: viewModel.isAlreadySynced ? "Already sent"
                                  : viewModel.isLocalMode   ? "Offline mode" : nil,
                        color: AppColors.brandPrimary,
                        filled: !emrDisabled,
                        disabled: emrDisabled
                    ) {
                        viewModel.showControlsMenu = false
                        viewModel.uploadEKG()
                    }

                    actionTile(
                        icon: "stethoscope",
                        title: "Diagnosis",
                        color: Color(red: 0.48, green: 0.36, blue: 0.90),
                        disabled: diagDisabled
                    ) {
                        viewModel.showControlsMenu = false
                        viewModel.showDiagnosisPanel = true
                    }

                    actionTile(
                        icon: "eye.circle.fill",
                        title: "Visualization",
                        color: AppColors.accentTeal
                    ) {
                        viewModel.showControlsMenu = false
                        viewModel.showVisualizationMenu = true
                    }

                    actionTile(
                        icon: "printer.fill",
                        title: "Print",
                        color: Color.orange
                    ) {
                        viewModel.showControlsMenu = false
                        printECG(
                            patient: viewModel.patient,
                            templateData: viewModel.templateData,
                            ecgData: viewModel.ecgData,
                            sampleRate: viewModel.sampleRate,
                            measurements: viewModel.measurements,
                            diagnosisLines: viewModel.diagnosisLines
                        )
                    }
                }
                .padding(16)
            }
            .frame(width: isCompact ? UIScreen.main.bounds.width - 32 : 360)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.22), radius: 40, x: 0, y: 12)
        }
    }

    // MARK: - Tile

    private func actionTile(
        icon: String,
        title: String,
        subtitle: String? = nil,
        color: Color,
        filled: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: disabled ? {} : action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(disabled
                              ? Color(UIColor.systemGray5)
                              : filled ? color : color.opacity(0.13))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(disabled
                                         ? Color.gray.opacity(0.4)
                                         : filled ? Color.white : color)
                }

                Text(title)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(disabled ? AppColors.textSecondary : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(subtitle == "Already sent"
                                         ? AppColors.statusSuccess
                                         : AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                disabled ? Color(UIColor.systemGray6)
                : filled ? color.opacity(0.07) : color.opacity(0.04)
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        disabled ? Color(UIColor.systemGray4) : color.opacity(0.18),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.hapticPlain)
        .disabled(disabled)
    }
}

// MARK: - Visualization Menu

struct VisualizationMenuSheet: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { viewModel.showVisualizationMenu = false }

            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    vizItem(icon: "chart.bar.doc.horizontal", title: "Table View", mode: .table)
                    Divider()
                    vizItem(icon: "square.3.layers.3d",       title: "Layers",     mode: .layers)
                    Divider()
                    vizItem(icon: "arrow.left.arrow.right",   title: "Standard",   mode: .standard)
                }
                .frame(width: 110)
                .background(Color.white)
                .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
                .padding(.vertical, 60)
            }
        }
    }

    private func vizItem(icon: String, title: String, mode: VisualizationMode) -> some View {
        Button {
            viewModel.visualizationMode = mode
            viewModel.showVisualizationMenu = false
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(viewModel.visualizationMode == mode
                                     ? AppColors.brandPrimary : Color.gray)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(viewModel.visualizationMode == mode
                                     ? Color.black : Color.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.hapticPlain)
    }
}

// MARK: - Reject Confirmation

struct RejectConfirmSheet: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Reject ECG?")
                    .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                    .foregroundColor(.black)
                Text("This ECG will be discarded and you will return to the dashboard.")
                    .font(AppTypography.callout)
                    .foregroundColor(Color(UIColor.darkGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        viewModel.showRejectConfirm = false
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(AppMetrics.radiusMedium)

                    Button("Reject") {
                        viewModel.confirmReject()
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(AppMetrics.radiusMedium)
                }
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Corner Radius Helper

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
