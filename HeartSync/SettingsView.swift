import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @AppStorage("heartsync.shouldShowOnboarding") private var shouldShowOnboarding = true
    @State private var partnerName = ""
    @State private var milestone = ""
    @State private var supportFocus = ""
    @State private var saveMessage = ""
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Partner profile") {
                    TextField("Partner name", text: $partnerName)
                    TextField("Current milestone", text: $milestone)
                    TextField("Support focus", text: $supportFocus, axis: .vertical)

                    Button("Save profile") {
                        store.updatePartner(
                            name: partnerName.isEmpty ? "Jordan" : partnerName,
                            milestone: milestone.isEmpty ? "This week’s reset" : milestone,
                            supportFocus: supportFocus.isEmpty ? "More honest daily check-ins" : supportFocus
                        )
                        saveMessage = "Profile updated for your next demo."
                    }
                    .foregroundStyle(HeartSyncTheme.blush)

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Demo presets") {
                    ForEach(HeartSyncStore.demoPresets) { preset in
                        Button {
                            store.applyPreset(preset)
                            partnerName = preset.partnerName
                            milestone = preset.milestone
                            supportFocus = preset.supportFocus
                            saveMessage = "Loaded the \(preset.title) preset."
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                Text(preset.supportFocus)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Demo controls") {
                    Button("Reset sample data") {
                        showResetConfirmation = true
                    }
                    .foregroundStyle(.red)

                    Button("Replay onboarding") {
                        shouldShowOnboarding = true
                        saveMessage = "Onboarding will open again."
                    }
                }

                Section("Share weekly summary") {
                    Text(store.weeklyStory)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ShareLink(
                        item: store.weeklySummaryText,
                        subject: Text(store.weeklySummaryTitle),
                        message: Text("Shared from HeartSync")
                    ) {
                        Label("Share current summary", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        store.copyWeeklySummaryToClipboard()
                        saveMessage = "Weekly summary copied."
                    } label: {
                        Label("Copy summary text", systemImage: "doc.on.doc")
                    }
                }

                Section("Demo readiness") {
                    ForEach(store.demoReadinessItems) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.isReady ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                                .foregroundStyle(item.isReady ? HeartSyncTheme.sage : HeartSyncTheme.coral)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("MVP scope") {
                    Label("Daily check-in with local persistence", systemImage: "checkmark.circle.fill")
                    Label("Dashboard with pulse, streak, and recent moments", systemImage: "checkmark.circle.fill")
                    Label("Simple profile tuning for demo customization", systemImage: "checkmark.circle.fill")
                    Label("Preset switching for different presentation scenarios", systemImage: "checkmark.circle.fill")
                    Label("Lightweight first-run onboarding", systemImage: "checkmark.circle.fill")
                    Label("Shareable weekly summary text", systemImage: "checkmark.circle.fill")
                }

                Section("Not in this week’s build") {
                    Label("Accounts and cloud sync", systemImage: "minus.circle")
                    Label("Push notifications", systemImage: "minus.circle")
                    Label("Multi-user collaboration or backend APIs", systemImage: "minus.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .confirmationDialog(
                "Reset HeartSync sample data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset sample data", role: .destructive) {
                    store.resetDemoData()
                    partnerName = store.partner.name
                    milestone = store.partner.milestone
                    supportFocus = store.partner.supportFocus
                    saveMessage = "Sample data restored."
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces the current profile and check-in history with the default demo scenario.")
            }
            .onAppear {
                partnerName = store.partner.name
                milestone = store.partner.milestone
                supportFocus = store.partner.supportFocus
                saveMessage = ""
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(HeartSyncStore())
    }
}
