//
//  AppContentViews.swift
//  EKGx
//
//  FAQ, Indications for Use, and Support screens.
//  All share AppContentViewModel.
//

import SwiftUI

// MARK: - Shared Nav Bar

private struct ContentNavBar: View {

    let title: String
    let subtitle: String
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            Button(action: onBack) {
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
                Text(title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
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

// MARK: - FAQView

struct FAQView: View {

    @State private var viewModel: AppContentViewModel
    @State private var expandedId: Int? = nil

    init(viewModel: AppContentViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ContentNavBar(
                    title: L10n.Menu.faq,
                    subtitle: L10n.FAQ.Nav.subtitle,
                    onBack: { viewModel.navigateBack() }
                )
                content
            }
        }
        .onAppear { viewModel.loadFaq() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isFaqLoading {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                .scaleEffect(1.4)
            Spacer()
        } else if let error = viewModel.faqError {
            errorState(error) { viewModel.loadFaq() }
        } else if viewModel.faqEntries.isEmpty {
            emptyState(icon: "text.bubble", message: L10n.FAQ.empty)
        } else {
            ScrollView {
                LazyVStack(spacing: AppMetrics.spacing10) {
                    ForEach(Array(viewModel.faqEntries.enumerated()), id: \.offset) { index, entry in
                        FAQRow(entry: entry, isExpanded: expandedId == index) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedId = expandedId == index ? nil : index
                            }
                        }
                    }
                }
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, AppMetrics.spacing24)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - FAQ Row

private struct FAQRow: View {

    let entry: FaqEntry
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppMetrics.spacing16) {
                    Text(entry.question ?? "")
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }
                .padding(.horizontal, AppMetrics.spacing24)
                .padding(.vertical, AppMetrics.spacing20)

                if isExpanded, let answer = entry.answer, !answer.isEmpty {
                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.5))
                        .frame(height: 1)
                        .padding(.horizontal, AppMetrics.spacing24)

                    Text(answer)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, AppMetrics.spacing24)
                        .padding(.vertical, AppMetrics.spacing16)
                }
            }
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(
                        isExpanded ? AppColors.brandPrimary.opacity(0.4) : AppColors.borderSubtle.opacity(0.5),
                        lineWidth: isExpanded ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                    )
            )
        }
        .buttonStyle(.hapticPlain)
    }
}

// MARK: - IndicationsForUseView

struct IndicationsForUseView: View {

    @State private var viewModel: AppContentViewModel

    init(viewModel: AppContentViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ContentNavBar(
                    title: L10n.Menu.indicationsForUse,
                    subtitle: L10n.IFU.Nav.subtitle,
                    onBack: { viewModel.navigateBack() }
                )
                content
            }
        }
        .onAppear { viewModel.loadIfu() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isIfuLoading {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                .scaleEffect(1.4)
            Spacer()
        } else if let error = viewModel.ifuError {
            errorState(error) { viewModel.loadIfu() }
        } else if let ifu = viewModel.ifuContent {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
                    // Version + date header
                    if let version = ifu.version, let date = ifu.effectiveDate {
                        HStack(spacing: AppMetrics.spacing16) {
                            Label(L10n.IFU.version(version), systemImage: "tag")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Text("·").foregroundStyle(AppColors.borderSubtle)
                            Label(L10n.IFU.effective(date), systemImage: "calendar")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppMetrics.spacing24)
                        .padding(.vertical, AppMetrics.spacing12)
                        .background(AppColors.surfaceCard)
                        .cornerRadius(AppMetrics.radiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .strokeBorder(AppColors.borderSubtle.opacity(0.5), lineWidth: AppMetrics.borderWidth)
                        )
                    }

                    // Body text
                    if let text = ifu.text, !text.isEmpty {
                        Text(text)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .padding(AppMetrics.spacing24)
                            .background(AppColors.surfaceCard)
                            .cornerRadius(AppMetrics.radiusLarge)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                                    .strokeBorder(AppColors.borderSubtle.opacity(0.5), lineWidth: AppMetrics.borderWidth)
                            )
                    }
                }
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, AppMetrics.spacing24)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
        } else {
            emptyState(icon: "doc.text", message: L10n.IFU.empty)
        }
    }
}

// MARK: - SupportView

struct SupportView: View {

    @State private var viewModel: AppContentViewModel
    @FocusState private var focused: SupportField?

    enum SupportField { case subject, message, phone }

    init(viewModel: AppContentViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                ContentNavBar(
                    title: L10n.Menu.support,
                    subtitle: L10n.Support.Nav.subtitle,
                    onBack: { viewModel.navigateBack() }
                )

                if viewModel.submitSuccess {
                    successState
                } else {
                    formContent
                }
            }
        }
    }

    // MARK: - Form

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                // Error banner
                if let error = viewModel.submitError {
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

                // Required fields
                Text(L10n.Support.Section.issue)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)

                ETextField(
                    label: L10n.Support.Field.subject,
                    placeholder: L10n.Support.Field.subjectPH,
                    systemImage: "text.alignleft",
                    text: $viewModel.supportSubject,
                    errorMessage: viewModel.subjectError
                )
                .focused($focused, equals: .subject)
                .onChange(of: viewModel.supportSubject) { _, _ in viewModel.subjectError = nil }
                .onSubmit { focused = .message }

                VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                    Text(L10n.Support.Field.message.uppercased())
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                        .tracking(0.5)

                    TextEditor(text: $viewModel.supportMessage)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textPrimary)
                        .focused($focused, equals: .message)
                        .frame(minHeight: 140)
                        .padding(AppMetrics.spacing14)
                        .background(AppColors.surfaceCard)
                        .cornerRadius(AppMetrics.radiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .strokeBorder(
                                    viewModel.messageError != nil
                                        ? AppColors.statusCritical
                                        : (focused == .message ? AppColors.borderFocused : AppColors.borderSubtle),
                                    lineWidth: focused == .message ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                                )
                        )
                        .onChange(of: viewModel.supportMessage) { _, _ in viewModel.messageError = nil }

                    if let err = viewModel.messageError {
                        Text(err)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.statusCritical)
                    }
                }

                // Optional contact fields
                Text(L10n.Support.Field.contactSection)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppMetrics.spacing4)

                ETextField(
                    label: L10n.Support.Field.phone,
                    placeholder: L10n.Support.Field.phonePH,
                    systemImage: "phone",
                    text: $viewModel.supportContactPhone,
                    textContentType: .telephoneNumber
                )
                .focused($focused, equals: .phone)
                .frame(maxWidth: 380)

                // Submit
                Button(action: { focused = nil; viewModel.submitSupport() }) {
                    HStack(spacing: AppMetrics.spacing8) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text(L10n.Support.Submit.button)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing32)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.brandPrimary)
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .disabled(viewModel.isSubmitting)
                .padding(.top, AppMetrics.spacing8)
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing24)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Success State

    private var successState: some View {
        VStack(spacing: AppMetrics.spacing20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(AppColors.statusSuccess)
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Support.Success.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Support.Success.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(L10n.Support.Success.backButton) { viewModel.navigateBack() }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing48)
    }
}

// MARK: - Shared Helpers

private func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: AppMetrics.spacing16) {
        Spacer()
        Image(systemName: icon)
            .font(.system(size: 64, weight: .light))
            .foregroundStyle(AppColors.textSecondary.opacity(0.4))
        Text(message)
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, AppMetrics.spacing48)
}

private func errorState(_ message: String, retry: @escaping () -> Void) -> some View {
    VStack(spacing: AppMetrics.spacing20) {
        Spacer()
        Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 64, weight: .light))
            .foregroundStyle(AppColors.statusCritical.opacity(0.6))
        Text(message)
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
        Button(L10n.Common.retry, action: retry)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppColors.brandPrimary)
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, AppMetrics.spacing48)
}
