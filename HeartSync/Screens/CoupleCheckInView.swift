import SwiftUI

/// Shared-device flow: consent is explicit and no remote partner connection is implied.
struct CoupleCheckInView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @Environment(\.dismiss) private var dismiss
    @State private var energy = 3
    @State private var connection = 3
    @State private var note = ""
    @State private var intention = ""
    @State private var consent = false
    @State private var isEditing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Check in together")
                        .font(.largeTitle.bold())
                    Text("This is a shared-device check-in, not a synced account. Both reflections stay on this device and are visible in this app and its backups.")
                }
                if let entry = store.todayCheckIn {
                    Section("Your perspective") {
                        response(energy: entry.energy, connection: entry.connection, note: entry.note, intention: entry.intention)
                    }
                    if let partner = entry.partnerResponse, !isEditing {
                        Section("\(store.partner.name)'s perspective") {
                            response(energy: partner.energy, connection: partner.connection, note: partner.note, intention: partner.intention)
                        }
                        if let summary = CoupleDailySummary(entry: entry) {
                            Section("A conversation, not a score") {
                                Text(summary.conversationPrompt)
                                    .accessibilityIdentifier("couple.summary")
                                Text("Connection difference: \(summary.connectionGap) out of 4. Different feelings are an invitation to listen, not a verdict on your relationship.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button("Edit partner’s response") {
                            energy = partner.energy
                            connection = partner.connection
                            note = partner.note
                            intention = partner.intention
                            consent = false
                            isEditing = true
                        }
                    } else {
                        Section("Pass the device to \(store.partner.name)") {
                            Text("Only enter your own response. You can take a break or close this without saving.")
                            Stepper("Energy: \(energy)/5", value: $energy, in: 1...5)
                                .accessibilityIdentifier("couple.energy")
                            Stepper("Connection: \(connection)/5", value: $connection, in: 1...5)
                                .accessibilityIdentifier("couple.connection")
                            TextField("What mattered to you? (optional)", text: $note, axis: .vertical)
                                .accessibilityIdentifier("couple.note")
                            TextField("One intention (optional)", text: $intention, axis: .vertical)
                                .accessibilityIdentifier("couple.intention")
                            Toggle("I’m adding my own response and agree to share it on this device", isOn: $consent)
                                .accessibilityIdentifier("couple.consent")
                            Button("Save partner’s check-in") {
                                if store.submitPartnerCheckIn(energy: energy, connection: connection, note: note, intention: intention) {
                                    isEditing = false
                                    errorMessage = nil
                                } else {
                                    errorMessage = "Today's first check-in is no longer available. Close this screen and save a fresh check-in."
                                }
                            }
                            .disabled(!consent)
                            .accessibilityIdentifier("couple.save")
                            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                        }
                    }
                } else {
                    ContentUnavailableView("Start with your check-in", systemImage: "heart.text.square", description: Text("Save your daily reflection in Check-In, then return here to add your partner's perspective."))
                }
            }
            .navigationTitle("Together")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func response(energy: Int, connection: Int, note: String, intention: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Energy \(energy)/5 · Connection \(connection)/5").font(.headline)
            Text(note.isEmpty ? "No reflection added." : note)
            if !intention.isEmpty { Label(intention, systemImage: "sparkles") }
        }
        .accessibilityElement(children: .combine)
    }
}
