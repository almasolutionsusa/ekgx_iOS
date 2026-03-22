//
//  AnalysisDiagnosisPanel.swift
//  EKGx
//
//  Slide-in diagnosis editor. Lists codes from vhECGCodes SDK grouped by category.
//  User can toggle items to add/remove from diagnosisLines, or type a custom entry.
//

import SwiftUI

struct AnalysisDiagnosisPanel: View {

    @Bindable var viewModel: AnalysisViewModel
    @State private var groups: [CodeGroup] = []
    @State private var customText: String = ""
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            HStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Diagnosis")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))

                    Divider()

                    // Custom input
                    HStack(spacing: 8) {
                        TextField("Add custom diagnosis...", text: $customText)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                        Button {
                            let trimmed = customText.trimmingCharacters(in: .whitespaces)
                            guard trimmed.count >= 3 else { return }
                            viewModel.diagnosisLines.append(trimmed)
                            customText = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(customText.count >= 3
                                                  ? AppColors.brandPrimary : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(customText.count < 3)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                    )
                    .padding(12)

                    Divider()

                    // Code list
                    List {
                        ForEach(groups, id: \.key) { group in
                            Section {
                                ForEach(group.items as? [CodeItem] ?? [], id: \.interpretationCode) { item in
                                    DiagnosisCell(
                                        text: item.itemString,
                                        isSelected: viewModel.diagnosisLines.contains(item.itemString),
                                        onToggle: {
                                            if viewModel.diagnosisLines.contains(item.itemString) {
                                                viewModel.diagnosisLines.removeAll { $0 == item.itemString }
                                            } else {
                                                viewModel.diagnosisLines.append(item.itemString)
                                            }
                                        }
                                    )
                                }
                            } header: {
                                Text(group.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                .frame(width: UIScreen.main.bounds.width * 0.38)
                .background(Color(UIColor.systemGray6))
                .offset(x: isVisible ? 0 : UIScreen.main.bounds.width)
                .animation(.easeInOut(duration: 0.3), value: isVisible)
            }
        }
        .onAppear {
            loadGroups()
            withAnimation { isVisible = true }
        }
    }

    private func dismiss() {
        withAnimation { isVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.showDiagnosisPanel = false
        }
    }

    private func loadGroups() {
        let sdk = vhECGCodes.shareCodeExchange()
        sdk.currentLanguageCode = "en"
        groups = sdk.interpretationCodesGroupsArray as? [CodeGroup] ?? []
    }
}

// MARK: - Cell

private struct DiagnosisCell: View {

    let text: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? AppColors.brandPrimary : .secondary)
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
