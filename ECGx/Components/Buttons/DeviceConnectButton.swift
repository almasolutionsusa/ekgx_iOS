//
//  DeviceConnectButton.swift
//  ECGx
//
//  Compact device connection status button.
//  Shows state (disconnected / searching / connected) and triggers connect/disconnect.
//

import SwiftUI

struct DeviceConnectButton: View {

    let state: DeviceConnectionState
    let onTap: () -> Void

    @State private var searchPulse: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing8) {
                // State icon
                ZStack {
                    if state == .searching {
                        Circle()
                            .fill(state.color.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .scaleEffect(searchPulse ? 1.5 : 1.0)
                            .opacity(searchPulse ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 0.9).repeatForever(autoreverses: false),
                                value: searchPulse
                            )
                    }
                    Image(systemName: state.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(state.color)
                }
                .frame(width: 20, height: 20)

                // Label
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.label)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(state.color)

                    if state == .disconnected {
                        Text(L10n.Home.Device.tapToConnect)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                // Connected indicator dot
                if state == .connected {
                    Circle()
                        .fill(AppColors.statusSuccess)
                        .frame(width: 6, height: 6)
                        .shadow(color: AppColors.statusSuccess, radius: 3)
                }
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing10)
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .fill(state.color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .strokeBorder(state.color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: state)
        .onAppear {
            if state == .searching { searchPulse = true }
        }
        .onChange(of: state) { _, newState in
            searchPulse = (newState == .searching)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DeviceConnectButton(state: .disconnected, onTap: {})
        DeviceConnectButton(state: .searching,    onTap: {})
        DeviceConnectButton(state: .connected,    onTap: {})
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
