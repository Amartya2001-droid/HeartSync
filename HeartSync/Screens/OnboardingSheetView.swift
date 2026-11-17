import SwiftUI

enum OnboardingSheetMode: String, Identifiable {
    case welcome
    case emptyHistory

    var id: String { rawValue }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
}

private struct OnboardingHeader {
    let title: String
    let detail: String
    let actionTitle: String
    let skipTitle: String
}

private struct RecoveryAction: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void
}

struct OnboardingSheetView: View {
    @EnvironmentObject private var store: HeartSyncStore
    let mode: OnboardingSheetMode
    @Binding var selectedTab: HeartSyncTab
    let dismissSheet: (OnboardingSheetMode) -> Void

    private var header: OnboardingHeader {
        switch mode {
        case .welcome:
            return OnboardingHeader(
                title: "Make space for each other",
                detail: "Name how your day felt, invite your partner to add their perspective, and choose one small intention together.",
                actionTitle: "Start checking in",
                skipTitle: "Skip"
            )
        case .emptyHistory:
            return OnboardingHeader(
                title: "A fresh start for your story",
                detail: "Your saved moments are empty. Start a new check-in, restore a backup from Profile, or explore clearly labelled fictional examples.",
                actionTitle: "Start first check-in",
                skipTitle: "Not now"
            )
        }
    }

    private var recoveryActions: [RecoveryAction] {
        [
            RecoveryAction(
                id: "checkin",
                title: "Start a new first check-in",
                detail: "Log today's energy, connection, note, and intention so Home and Moments become useful again.",
                symbol: "square.and.pencil",
                action: {
                    selectedTab = .checkIn
                    dismissSheet(.emptyHistory)
                }
            ),
            RecoveryAction(
                id: "sample",
                title: "Load fictional sample data",
                detail: "Explore fictional examples. Loading them replaces the local profile and history.",
                symbol: "arrow.counterclockwise.circle.fill",
                action: {
                    store.resetDemoData()
                    selectedTab = .home
                    dismissSheet(.emptyHistory)
                }
            ),
        ]
    }

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            id: "pulse",
            title: "Start with your perspective",
            detail: "Record your energy, connection and one reflection. There is no right score to reach.",
            symbol: "heart.text.square.fill"
        ),
        OnboardingStep(
            id: "checkin",
            title: "Make room for a second perspective",
            detail: "Pass the device when your partner is ready. They enter their own response and consent before saving.",
            symbol: "slider.horizontal.3"
        ),
        OnboardingStep(
            id: "moments",
            title: "Carry one intention forward",
            detail: "Use the shared conversation prompt to listen, then revisit your check-ins in Moments.",
            symbol: "book.closed.fill"
        ),
        OnboardingStep(
            id: "demo",
            title: "Keep a copy of your story",
            detail: "Data is stored locally, with no account or partner sync. Export a JSON backup before deleting the app.",
            symbol: "sparkles.rectangle.stack.fill"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if mode == .welcome { HeartSyncBrandLockup() }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(header.title)
                            .accessibilityIdentifier(mode == .welcome ? "onboarding.welcomeTitle" : "onboarding.recoveryTitle")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(HeartSyncTheme.ink)
                        Text(header.detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        if mode == .welcome {
                            Text(HeartSyncBrand.sharedDeviceNotice)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("brand.privacy")
                        }
                    }

                    switch mode {
                    case .welcome:
                        onboardingSteps
                    case .emptyHistory:
                        recoveryCards
                    }

                    Button {
                        primaryAction()
                    } label: {
                        Text(header.actionTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("onboarding.primary")
                }
                .padding(20)
            }
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(header.skipTitle) {
                        dismissSheet(mode)
                    }
                    .foregroundStyle(HeartSyncTheme.blush)
                }
            }
        }
    }

    @ViewBuilder
    private var onboardingSteps: some View {
        ForEach(steps) { step in
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: step.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.headline)
                        .foregroundStyle(HeartSyncTheme.ink)
                    Text(step.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    private var recoveryCards: some View {
        VStack(spacing: 14) {
            ForEach(recoveryActions) { item in
                Button {
                    item.action()
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(HeartSyncTheme.ink)
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func primaryAction() {
        switch mode {
        case .welcome:
            selectedTab = .checkIn
            dismissSheet(.welcome)
        case .emptyHistory:
            selectedTab = .checkIn
            dismissSheet(.emptyHistory)
        }
    }
}
