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

    var body: some View {
        ZStack {
            // Dim background — tap to close
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { viewModel.showControlsMenu = false }

            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    menuItem(
                        icon: viewModel.isAlreadySynced ? "checkmark.circle" : "arrow.up.circle",
                        title: "Send to EMR",
                        subtitle: viewModel.isLocalMode ? "Offline" : (viewModel.isAlreadySynced ? "Sent" : nil),
                        disabled: viewModel.isLocalMode || viewModel.isAlreadySynced,
                        action: {
                            viewModel.showControlsMenu = false
                            viewModel.uploadEKG()
                        }
                    )
                    Divider()
                    menuItem(
                        icon: "book",
                        title: "Diagnosis",
                        disabled: viewModel.isLocalMode || viewModel.isAlreadySynced,
                        action: {
                            viewModel.showControlsMenu = false
                            viewModel.showDiagnosisPanel = true
                        }
                    )
                    Divider()
                    menuItem(icon: "eye",             title: "Visualization", action: {
                        viewModel.showControlsMenu = false
                        viewModel.showVisualizationMenu = true
                    })
                    Divider()
                    menuItem(icon: "printer",         title: "Print",        action: {
                        viewModel.showControlsMenu = false
                        printECG(
                            patient: viewModel.patient,
                            templateData: viewModel.templateData,
                            ecgData: viewModel.ecgData,
                            sampleRate: viewModel.sampleRate,
                            measurements: viewModel.measurements,
                            diagnosisLines: viewModel.diagnosisLines
                        )
                    })
                }
                .frame(width: 110)
                .background(Color.white)
                .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                .shadow(color: .black.opacity(0.15), radius: 12, x: -4, y: 0)
            }
        }
    }

    private func menuItem(
        icon: String,
        title: String,
        subtitle: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: disabled ? {} : action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(disabled ? Color.gray.opacity(0.5) : AppColors.brandPrimary)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(disabled ? Color.gray.opacity(0.5) : Color.primary)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppColors.statusSuccess)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
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
        .buttonStyle(.plain)
    }
}

// MARK: - Reject Confirmation

struct RejectConfirmSheet: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Reject ECG?")
                    .font(AppTypography.title2)
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
