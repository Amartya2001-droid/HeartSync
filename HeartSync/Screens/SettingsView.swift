import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @AppStorage("heartsync.shouldShowOnboarding") private var shouldShowOnboarding = true
    @FocusState private var profileField: ProfileField?
    private enum ProfileField: Hashable { case name, milestone, focus, backup }
    @State private var partnerName = ""
    @State private var milestone = ""
    @State private var supportFocus = ""
    @State private var showBackupExporter = false
    @State private var showBackupImporter = false
    @State private var isReadingBackupFile = false
    @State private var backupDocument: HeartSyncBackupDocument?
    @State private var backupFileMessage = ""
    @State private var backupImportText = ""
    @State private var backupCopyMessage = ""
    @State private var backupRestoreMessage = ""
    @State private var saveMessage = ""
    @State private var showResetConfirmation = false
    @State private var showClearHistoryConfirmation = false
    @State private var showRecoveryResetConfirmation = false
    @State private var showRestoreBackupConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                if let message = store.recoveryMessage {
                    Section("Recover local data") {
                        Text(message)
                        Button("Start fresh", role: .destructive) { showRecoveryResetConfirmation = true }
                            .accessibilityIdentifier("recovery.startFresh")
                    }
                }

                Section("Partner profile") {
                    TextField("Partner name", text: $partnerName)
                        .focused($profileField, equals: .name)
                        .accessibilityLabel("Partner name")
                        .accessibilityIdentifier("profile.name")
                    TextField("Current milestone", text: $milestone)
                        .focused($profileField, equals: .milestone)
                        .accessibilityIdentifier("profile.milestone")
                    TextField("Support focus", text: $supportFocus, axis: .vertical)
                        .focused($profileField, equals: .focus)
                        .accessibilityIdentifier("profile.focus")

                    Button("Save profile") {
                        profileField = nil
                        let saved = store.updatePartner(name: partnerName, milestone: milestone, supportFocus: supportFocus)
                        saveMessage = saved ? "Profile saved locally." : "Profile was not saved. Use a name of 1–200 characters, milestone up to 500 and support focus up to 2,000. Resolve any data-recovery warning first."
                    }
                    .foregroundStyle(HeartSyncTheme.ink)
                    .disabled(store.recoveryMessage != nil)
                    .accessibilityIdentifier("profile.save")

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .accessibilityIdentifier("profile.status")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Demo presets") {
                    ForEach(HeartSyncStore.demoPresets) { preset in
                        Button {
                            guard store.applyPreset(preset) else { saveMessage = "Preset was not saved. Resolve data recovery first."; return }
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

                .disabled(store.recoveryMessage != nil)

                Section("Current scenario") {
                    Text(store.currentScenarioSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Current scenario")
                        .accessibilityValue(store.currentScenarioSummary.replacingOccurrences(of: "\n", with: ". "))

                    Button {
                        store.copyCurrentScenarioToClipboard()
                        saveMessage = "Current scenario copied."
                    } label: {
                        Label("Copy current scenario", systemImage: "rectangle.on.rectangle")
                    }
                }

                Section("Demo controls") {
                    Button("Reset sample data") {
                        showResetConfirmation = true
                    }
                    .foregroundStyle(.red)
                    .disabled(store.recoveryMessage != nil)
                    .accessibilityIdentifier("data.resetSamples")

                    Button("Replay onboarding") {
                        shouldShowOnboarding = true
                        saveMessage = "Onboarding will open again."
                    }
                }

                Section("Share weekly summary") {
                    Text("\(store.weeklyDateRangeLabel): \(store.weeklyStory)")
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

                Section("Presenter handoff") {
                    Text("Copy a short talk track that matches the current app state and latest demo flow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        store.copyPresenterTalkTrackToClipboard()
                        saveMessage = "Presenter talk track copied."
                    } label: {
                        Label("Copy presenter talk track", systemImage: "quote.bubble")
                    }

                    Button {
                        store.copyLatestMomentToClipboard()
                        saveMessage = "Latest moment copied."
                    } label: {
                        Label("Copy latest moment", systemImage: "doc.text")
                    }

                    Button {
                        store.copyFullHistoryToClipboard()
                        saveMessage = "Full moments history copied."
                    } label: {
                        Label("Copy full moments history", systemImage: "archivebox")
                    }
                }

                Section("Data safety") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: store.exportStatus.isCurrent ? "externaldrive.fill.badge.checkmark" : "externaldrive.badge.exclamationmark")
                            .foregroundStyle(store.exportStatus.isCurrent ? HeartSyncTheme.sage : HeartSyncTheme.coral)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.exportStatus.title)
                                .font(.subheadline.weight(.semibold))
                            Text(store.exportStatus.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(store.lastBackupExportLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Data safety")
                    .accessibilityValue("\(store.exportStatus.title). \(store.exportStatus.detail). \(store.lastBackupExportLabel)")

                    Button {
                        guard let document = store.prepareBackupFile() else {
                            backupFileMessage = "A backup file could not be prepared. Resolve recovery warnings or invalid draft values, and keep the JSON snapshot within the 5 MB limit."
                            return
                        }
                        backupDocument = document
                        showBackupExporter = true
                    } label: {
                        Label("Save backup file", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.recoveryMessage != nil || isReadingBackupFile)
                    .accessibilityIdentifier("backup.exportFile")

                    Button {
                        profileField = nil
                        showBackupImporter = true
                    } label: {
                        Label("Open backup file for review", systemImage: "folder")
                    }
                    .disabled(isReadingBackupFile)
                    .accessibilityIdentifier("backup.importFile")

                    Text("Files contain both responses as readable JSON. Review the destination before saving or sharing. Opening a file only loads a preview; it does not restore data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if isReadingBackupFile { ProgressView("Reading backup file…") }
                    if !backupFileMessage.isEmpty {
                        Text(backupFileMessage)
                            .font(.footnote)
                            .accessibilityIdentifier("backup.fileStatus")
                    }

                    Button {
                        backupCopyMessage = store.copyBackupExportToClipboard() ? "Backup export copied. Store it somewhere safe; the clipboard is not a permanent backup." : "Backup was not copied. Resolve data recovery or invalid draft values first."
                    } label: {
                        Label("Copy backup export (JSON)", systemImage: "externaldrive")
                    }
                    .accessibilityIdentifier("backup.copy")
                    if !backupCopyMessage.isEmpty {
                        Text(backupCopyMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("backup.status")
                    }

                    Button {
                        backupRestoreMessage = ""
                        backupImportText = UIPasteboard.general.string ?? ""
                        saveMessage = backupImportText.isEmpty ? "Clipboard did not contain backup text." : "Backup text pasted from clipboard."
                    } label: {
                        Label("Paste copied backup", systemImage: "doc.on.clipboard")
                    }
                    .accessibilityIdentifier("backup.paste")

                    TextEditor(text: $backupImportText)
                        .focused($profileField, equals: .backup)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
                        )
                        .accessibilityLabel("Backup JSON input")
                        .accessibilityIdentifier("backup.input")
                        .disabled(isReadingBackupFile)

                    Text(store.backupPreviewSummary(for: backupImportText))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        backupRestoreMessage = ""
                        showRestoreBackupConfirmation = true
                    } label: {
                        Label("Restore reviewed backup", systemImage: "arrow.clockwise")
                    }
                    .disabled(isReadingBackupFile || backupImportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("backup.restore")
                    if !backupRestoreMessage.isEmpty {
                        Text(backupRestoreMessage)
                            .font(.footnote)
                            .accessibilityIdentifier("backup.restoreStatus")
                    }
                }

                Section("Local demo data") {
                    Text("HeartSync stores the profile, draft, and moments locally on this device for a reliable no-backend demo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        saveMessage = store.clearDraft() ? "Current check-in draft cleared." : "Draft was not cleared. Resolve data recovery first."
                    } label: {
                        Label("Clear current draft", systemImage: "eraser")
                    }
                    .disabled(store.recoveryMessage != nil)
                    .accessibilityIdentifier("data.clearDraft")

                    Button("Clear all moments history") {
                        showClearHistoryConfirmation = true
                    }
                    .foregroundStyle(.red)
                    .disabled(store.recoveryMessage != nil)
                    .accessibilityIdentifier("data.clearHistory")
                }

                Section("Demo readiness") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: store.isDemoReady ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(store.isDemoReady ? HeartSyncTheme.sage : HeartSyncTheme.coral)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.demoReadinessSummary)
                                .font(.subheadline.weight(.semibold))
                            Text(store.isDemoReady ? "You can present from the current state." : "Resolve the pending items below before a live demo.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Demo readiness")
                    .accessibilityValue("\(store.demoReadinessSummary). \(store.isDemoReady ? "You can present from the current state." : "Resolve the pending items before a live demo.")")

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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(item.title)
                        .accessibilityValue(item.isReady ? "Ready. \(item.detail)" : "Needs attention. \(item.detail)")
                    }
                }

                Section("Release info") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HeartSyncTheme.ink)
                        Text(bundleIdentifier)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Local-first release with backup export/restore and store-level XCTest coverage.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Release info")
                    .accessibilityValue("Version \(appVersion), build \(buildNumber), bundle identifier \(bundleIdentifier).")

                    Button {
                        store.copyReleaseSummaryToClipboard(
                            appVersion: appVersion,
                            buildNumber: buildNumber,
                            bundleIdentifier: bundleIdentifier
                        )
                        saveMessage = "Release summary copied."
                    } label: {
                        Label("Copy release summary", systemImage: "shippingbox")
                    }
                }

                Section("Launch review") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: launchReviewItems.allSatisfy(\.isReady) ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(launchReviewItems.allSatisfy(\.isReady) ? HeartSyncTheme.sage : HeartSyncTheme.coral)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.launchReviewSummary(
                                appVersion: appVersion,
                                buildNumber: buildNumber,
                                bundleIdentifier: bundleIdentifier
                            ))
                            .font(.subheadline.weight(.semibold))
                            Text("Use this quick pass before demo handoff, packaging, or a release review.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Launch review")
                    .accessibilityValue(store.launchReviewSummary(
                        appVersion: appVersion,
                        buildNumber: buildNumber,
                        bundleIdentifier: bundleIdentifier
                    ))

                    ForEach(launchReviewItems) { item in
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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(item.title)
                        .accessibilityValue(item.isReady ? "Ready. \(item.detail)" : "Needs attention. \(item.detail)")
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

                Section("About HeartSync") {
                    HeartSyncBrandLockup()
                    Text(HeartSyncBrand.sharedDeviceNotice)
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                    Text("No account or partner sync. Reflection prompts are not medical advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .fileExporter(isPresented: $showBackupExporter, document: backupDocument,
                          contentType: .json, defaultFilename: "HeartSync-backup") { result in
                switch result {
                case .success:
                    if let document = backupDocument, store.completeBackupFileExport(document) {
                        backupFileMessage = "Backup file saved. Keep it somewhere safe; it includes both responses."
                    } else {
                        backupFileMessage = "The snapshot file was saved, but current data changed or needs recovery. Export again before calling the backup current."
                    }
                case .failure(let error):
                    backupFileMessage = fileFailureMessage(error, operation: "Save")
                }
                backupDocument = nil
            }
            .fileImporter(isPresented: $showBackupImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): loadBackupFile(url)
                case .failure(let error): backupFileMessage = fileFailureMessage(error, operation: "Open")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { profileField = nil }
                        .accessibilityIdentifier("profile.keyboardDone")
                }
            }
            .confirmationDialog("Start fresh?", isPresented: $showRecoveryResetConfirmation, titleVisibility: .visible) {
                Button("Keep unreadable copy and start fresh", role: .destructive) { store.startFreshAfterRecovery() }
                    .accessibilityIdentifier("recovery.confirmFresh")
            } message: {
                Text("This replaces the active local state with an empty history. The unreadable state is kept on this device for troubleshooting; it is not a usable backup.")
            }
            .confirmationDialog(
                "Reset HeartSync sample data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset sample data", role: .destructive) {
                    guard store.resetDemoData() else { saveMessage = "Sample data was not loaded. Resolve data recovery first."; return }
                    partnerName = store.partner.name
                    milestone = store.partner.milestone
                    supportFocus = store.partner.supportFocus
                    saveMessage = "Sample data restored."
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces the current profile and check-in history with the default demo scenario.")
            }
            .confirmationDialog(
                "Restore HeartSync backup?",
                isPresented: $showRestoreBackupConfirmation,
                titleVisibility: .visible
            ) {
                Button("Restore backup", role: .destructive) {
                    let result = store.restoreFromBackupText(backupImportText)
                    if result.isSuccess {
                        partnerName = store.partner.name
                        milestone = store.partner.milestone
                        supportFocus = store.partner.supportFocus
                        backupImportText = ""
                    }
                    backupRestoreMessage = "\(result.title): \(result.detail)"
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces the current local profile, moments, and draft state with the pasted backup.")
            }
            .confirmationDialog(
                "Clear all saved moments?",
                isPresented: $showClearHistoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear history", role: .destructive) {
                    saveMessage = store.clearAllHistory() ? "All moments history cleared." : "History was not cleared. Resolve data recovery or invalid draft values first."
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every saved check-in from local history but keeps the current profile and draft.")
            }
            .onAppear {
                partnerName = store.partner.name
                milestone = store.partner.milestone
                supportFocus = store.partner.supportFocus
                saveMessage = ""
            }
        }
    }

    private func loadBackupFile(_ url: URL) {
        isReadingBackupFile = true
        backupRestoreMessage = ""
        backupFileMessage = "Reading the selected file. Saved data has not changed."
        Task { @MainActor in
            defer { isReadingBackupFile = false }
            do {
                let text = try await Task.detached(priority: .userInitiated) {
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    return try HeartSyncBackupDocument.readContents(from: url)
                }.value
                guard store.canReviewBackupText(text) else { throw BackupFileError.invalidBackup }
                backupImportText = text
                backupFileMessage = "File loaded for review. Saved data has not changed. Read the preview, then choose Restore reviewed backup if you want to replace local data."
            } catch {
                backupImportText = ""
                backupFileMessage = "File was not loaded: \(error.localizedDescription) Saved data has not changed."
            }
        }
    }

    private func fileFailureMessage(_ error: Error, operation: String) -> String {
        let failure = error as NSError
        if failure.domain == NSCocoaErrorDomain && failure.code == NSUserCancelledError {
            return "\(operation) cancelled. The existing preview and saved data were not changed."
        }
        return "Could not \(operation.lowercased()) the backup file: \(error.localizedDescription) Saved data has not changed."
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.amartyakarmakar.heartsync"
    }

    private var launchReviewItems: [LaunchReviewItem] {
        store.launchReviewItems(
            appVersion: appVersion,
            buildNumber: buildNumber,
            bundleIdentifier: bundleIdentifier
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HeartSyncPreview {
            SettingsView()
        }
    }
}
