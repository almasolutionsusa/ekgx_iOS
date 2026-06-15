//
//  WaitingListView.swift
//  EKGx
//
//  Local patient waiting queue with drag-to-reorder and swipe actions.
//

import SwiftUI

// MARK: - Root View

struct WaitingListView: View {

    @State private var viewModel: WaitingListViewModel
    @State private var isReordering = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isCompact: Bool { sizeClass == .compact }

    init(viewModel: WaitingListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                mainContent
            }

            // iPad overlay only
            if viewModel.showAddPatient && !isCompact {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { viewModel.closeAddPatient() }

                AddPatientSheet(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.showAddPatient)
        // iPhone: present as sheet
        .sheet(isPresented: Binding(
            get: { isCompact && viewModel.showAddPatient },
            set: { if !$0 { viewModel.closeAddPatient() } }
        )) {
            AddPatientSheet(viewModel: viewModel)
        }
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
        .onAppear { viewModel.activate() }
        .onDisappear { viewModel.deactivate() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            // Title block — truly centered
            VStack(spacing: 2) {
                Text(L10n.WaitingList.title)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)

                if viewModel.activeCount > 0 {
                    Text(navSubtitle)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)

            // Left + Right controls
            HStack {
                // Back
                Button { viewModel.navigateBack() } label: {
                    if isCompact {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text(L10n.Common.back)
                                .font(AppTypography.callout)
                        }
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, AppMetrics.spacing16)
                        .padding(.vertical, AppMetrics.spacing8)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .cornerRadius(AppMetrics.radiusMedium)
                    }
                }
                .buttonStyle(.hapticPlain)

                Spacer()

                if isReordering {
                    navReorderDoneButton
                } else {
                    navNormalButtons
                }
            }
        }
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing32)
        .frame(height: isCompact ? 52 : AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var navReorderDoneButton: some View {
        Button { withAnimation { isReordering = false } } label: {
            Text(L10n.Common.done)
                .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.accentTeal)
                .padding(.horizontal, AppMetrics.spacing14)
                .frame(height: 38)
                .background(AppColors.accentTeal.opacity(0.1))
                .cornerRadius(AppMetrics.radiusMedium)
        }
        .buttonStyle(.hapticPlain)
    }

    private var navNormalButtons: some View {
        HStack(spacing: isCompact ? AppMetrics.spacing8 : AppMetrics.spacing12) {
            if viewModel.hasDone {
                if isCompact {
                    Button { withAnimation { viewModel.clearDone() } } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.statusCritical)
                            .frame(width: 38, height: 38)
                            .background(AppColors.statusCritical.opacity(0.08))
                            .cornerRadius(AppMetrics.radiusMedium)
                    }
                    .buttonStyle(.hapticPlain)
                } else {
                    Button(L10n.WaitingList.clearDone) { withAnimation { viewModel.clearDone() } }
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.statusCritical)
                        .padding(.horizontal, AppMetrics.spacing12)
                        .padding(.vertical, AppMetrics.spacing8)
                        .background(AppColors.statusCritical.opacity(0.08))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
            }

            if viewModel.activePatients.count > 1 {
                Button { withAnimation { isReordering = true } } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: isCompact ? 15 : 14, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            }

            if isCompact {
                Button { viewModel.openAddPatient() } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(AppColors.accentTeal)
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            } else {
                Button { viewModel.openAddPatient() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus").font(.system(size: 14, weight: .semibold))
                        Text(L10n.WaitingList.addPatient).font(AppTypography.callout)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.accentTeal)
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            }
        }
    }

    private var navSubtitle: String {
        let waiting    = viewModel.activePatients.filter { $0.status == .waiting }.count
        let inProgress = viewModel.activePatients.filter { $0.status == .inProgress }.count
        var parts: [String] = []
        if waiting    > 0 { parts.append("\(waiting) waiting") }
        if inProgress > 0 { parts.append("\(inProgress) in progress") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.patients.isEmpty {
            emptyState
        } else {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                List {
                    // Active section
                    if !viewModel.activePatients.isEmpty {
                        Section {
                            ForEach(Array(viewModel.activePatients.enumerated()), id: \.element.id) { idx, patient in
                                WaitingPatientRow(
                                    patient:  patient,
                                    position: idx + 1,
                                    now:      context.date,
                                    onStart:  { viewModel.startEKG(for: patient) },
                                    onDone:   { viewModel.markDone(id: patient.id) },
                                    onRemove: { viewModel.remove(id: patient.id) }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation { viewModel.markDone(id: patient.id) }
                                    } label: {
                                        Label(L10n.WaitingList.markDone, systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { viewModel.remove(id: patient.id) }
                                    } label: {
                                        Label(L10n.Common.remove, systemImage: "trash.fill")
                                    }
                                }
                            }
                            .onMove { source, dest in
                                viewModel.move(from: source, to: dest)
                            }
                        } header: {
                            queueSectionHeader(
                                title: L10n.WaitingList.sectionActive,
                                count: viewModel.activePatients.count
                            )
                        }
                    }

                    // Done section
                    if viewModel.hasDone {
                        Section {
                            ForEach(viewModel.donePatients) { patient in
                                WaitingPatientRow(
                                    patient:  patient,
                                    position: 0,
                                    now:      context.date,
                                    onStart:  {},
                                    onDone:   { viewModel.markWaiting(id: patient.id) },
                                    onRemove: { viewModel.remove(id: patient.id) }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation { viewModel.markWaiting(id: patient.id) }
                                    } label: {
                                        Label(L10n.WaitingList.restore, systemImage: "arrow.uturn.left.circle.fill")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { viewModel.remove(id: patient.id) }
                                    } label: {
                                        Label(L10n.Common.remove, systemImage: "trash.fill")
                                    }
                                }
                            }
                        } header: {
                            queueSectionHeader(
                                title: L10n.WaitingList.sectionDone,
                                count: viewModel.donePatients.count
                            )
                        }
                    }
                }
                .listStyle(.plain)
                .background(AppColors.surfaceBackground)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func queueSectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
            Text("\(count)")
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(AppColors.borderSubtle.opacity(0.6))
                .cornerRadius(8)
            Spacer()
        }
        .padding(.top, AppMetrics.spacing16)
        .padding(.bottom, AppMetrics.spacing8)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.accentTeal.opacity(0.08))
                    .frame(width: isCompact ? 96 : 120, height: isCompact ? 96 : 120)
                Image(systemName: "list.clipboard")
                    .font(.system(size: isCompact ? 40 : 52, weight: .light))
                    .foregroundStyle(AppColors.accentTeal.opacity(0.5))
            }

            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.WaitingList.emptyTitle)
                    .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.WaitingList.emptySubtitle)
                    .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: isCompact ? 300 : 340)
            }

            Button { viewModel.openAddPatient() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text(L10n.WaitingList.addFirstPatient)
                }
                .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing14)
                .background(AppColors.accentTeal)
                .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.hapticPlain)

            Spacer()
        }
    }
}

// MARK: - Patient Row

private struct WaitingPatientRow: View {

    let patient:  WaitingPatient
    let position: Int
    let now:      Date
    let onStart:  () -> Void
    let onDone:   () -> Void
    let onRemove: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    private var isDone: Bool { patient.status == .done }

    // Single accent — only in-progress gets brandPrimary, everything else is neutral
    private var stripColor: Color {
        switch patient.status {
        case .waiting:    return AppColors.borderSubtle
        case .inProgress: return AppColors.accentTeal
        case .done:       return Color.clear
        }
    }

    var body: some View {
        Button {
            guard !isDone else { return }
            onStart()
        } label: {
            HStack(spacing: AppMetrics.spacing12) {

                // Left status strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(stripColor)
                    .frame(width: 3)
                    .padding(.vertical, 6)

                // Position badge
                positionBadge

                // Avatar
                ZStack {
                    Circle()
                        .fill(AppColors.accentTeal.opacity(isDone ? 0.05 : 0.10))
                        .frame(width: isCompact ? 40 : 46, height: isCompact ? 40 : 46)
                    Text(patient.initials)
                        .font(AppTypography.calloutBold)
                        .foregroundStyle(isDone ? AppColors.textSecondary : AppColors.accentTeal)
                }

                // Patient info
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                        .foregroundStyle(isDone ? AppColors.textSecondary : AppColors.textPrimary)
                        .strikethrough(isDone, color: AppColors.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        if !patient.mrn.isEmpty {
                            Text("#\(patient.mrn)")
                            dot
                        }
                        Text(patient.genderInitial)
                        dot
                        Text(patient.age)
                        dot
                        Text(patient.elapsedText(relativeTo: now))
                    }
                    .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Status indicator
                statusIndicator
            }
            .padding(.leading, AppMetrics.spacing10)
            .padding(.trailing, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing16)
            .padding(.vertical, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing14)
            .background(AppColors.surfaceElevatedOverride)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .stroke(AppColors.borderSubtle.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isDone ? 0 : 0.04), radius: 4, x: 0, y: 2)
            .opacity(isDone ? 0.55 : 1)
        }
        .buttonStyle(.hapticPlain)
    }

    @ViewBuilder
    private var positionBadge: some View {
        let badgeSize: CGFloat = isCompact ? 26 : 30
        if isDone {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isCompact ? 18 : 22))
                .foregroundStyle(AppColors.textSecondary.opacity(0.45))
                .frame(width: badgeSize, height: badgeSize)
        } else {
            Text("\(position)")
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: badgeSize, height: badgeSize)
                .background(AppColors.surfaceBackground)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch patient.status {
        case .inProgress:
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.accentTeal)
        case .waiting:
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.35))
        case .done:
            EmptyView()
        }
    }

    private var dot: some View {
        Circle()
            .fill(AppColors.textSecondary.opacity(0.35))
            .frame(width: 3, height: 3)
    }
}

// MARK: - Add Patient Sheet

private struct AddPatientSheet: View {

    @Bindable var viewModel: WaitingListViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        if isCompact {
            sheetCore
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            sheetCore
                .frame(width: 560, height: 500)
                .cornerRadius(AppMetrics.radiusLarge)
                .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 10)
        }
    }

    private var sheetCore: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.WaitingList.addTitle)
                        .font(isCompact ? AppTypography.phoneTitle : AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.WaitingList.addSubtitle)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button { viewModel.closeAddPatient() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.hapticPlain)
            }
            .padding(AppMetrics.spacing24)

            // Search bar
            HStack(spacing: AppMetrics.spacing10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
                TextField(L10n.WaitingList.searchPlaceholder, text: $viewModel.addSearchText)
                    .font(isCompact ? AppTypography.phoneBody : AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                if !viewModel.addSearchText.isEmpty {
                    Button { viewModel.addSearchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.hapticPlain)
                }
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing12)
            .background(AppColors.surfaceBackground)
            .cornerRadius(AppMetrics.radiusMedium)
            .padding(.horizontal, AppMetrics.spacing24)

            Divider()
                .padding(.top, AppMetrics.spacing16)

            // Patient list
            if viewModel.isLoadingAddPatients {
                Spacer()
                ProgressView()
                    .tint(AppColors.accentTeal)
                Spacer()
            } else if viewModel.filteredAddPatients.isEmpty {
                Spacer()
                VStack(spacing: AppMetrics.spacing12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    Text(L10n.WaitingList.noPatients)
                        .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.filteredAddPatients) { patient in
                            addPatientRow(patient)
                        }
                    }
                    .padding(.vertical, AppMetrics.spacing8)
                }
            }
        }
        .background(AppColors.surfaceCard)
    }

    private func addPatientRow(_ patient: LocalPatient) -> some View {
        let inQueue = viewModel.isInQueue(patient)
        return HStack(spacing: AppMetrics.spacing14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.accentTeal.opacity(0.1))
                    .frame(width: 42, height: 42)
                Text(patient.initials)
                    .font(AppTypography.calloutBold)
                    .foregroundStyle(AppColors.accentTeal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(patient.fullName)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                    .foregroundStyle(inQueue ? AppColors.textSecondary : AppColors.textPrimary)
                HStack(spacing: 6) {
                    if !patient.mrn.isEmpty {
                        Text("MRN: \(patient.mrn)")
                    }
                    Text("·")
                    Text(patient.genderDisplay)
                    Text("·")
                    Text(patient.age)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Action
            if inQueue {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(L10n.WaitingList.alreadyInQueue)
                        .font(AppTypography.captionBold)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.08))
                .cornerRadius(AppMetrics.radiusMedium)
            } else {
                Button { viewModel.addToQueue(patient) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text(L10n.WaitingList.add)
                            .font(AppTypography.captionBold)
                    }
                    .foregroundStyle(AppColors.accentTeal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppColors.accentTeal.opacity(0.1))
                    .cornerRadius(AppMetrics.radiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .stroke(AppColors.accentTeal.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing20)
        .padding(.vertical, AppMetrics.spacing12)
        .background(
            inQueue
                ? AppColors.surfaceBackground.opacity(0.5)
                : AppColors.surfaceCard
        )
    }
}
