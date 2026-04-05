import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var store: HeartSyncStore
    @State private var showSavedState = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Daily relationship check-in")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(HeartSyncTheme.ink)

                    Text("Keep it light. The goal is awareness, not perfection.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    sliderCard(
                        title: "How is your energy today?",
                        subtitle: "Low energy is useful to name early so support can be more intentional.",
                        value: $store.todayEnergy,
                        accent: HeartSyncTheme.coral
                    )

                    sliderCard(
                        title: "How connected do you feel?",
                        subtitle: "This helps spot drift before it turns into distance.",
                        value: $store.todayConnection,
                        accent: HeartSyncTheme.blush
                    )

                    if let todayCheckIn = store.todayCheckIn {
                        existingCheckInCard(todayCheckIn)
                    }

                    reflectionCard

                    Button {
                        store.submitCheckIn()
                        showSavedState = true
                    } label: {
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(HeartSyncTheme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .padding(.bottom, 28)
            }
            .background(HeartSyncTheme.background.ignoresSafeArea())
            .navigationTitle("Check-In")
            .onAppear {
                showSavedState = false
            }
        }
    }

    private var buttonTitle: String {
        if showSavedState {
            return "Saved for today"
        }

        return store.hasCompletedTodayCheckIn ? "Update today’s check-in" : "Save today’s check-in"
    }

    private func existingCheckInCard(_ checkIn: DailyCheckIn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Already checked in today")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            Text("You can adjust the sliders or replace the note and intention below. Saving again will update today’s entry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Label("Energy \(checkIn.energy)/5", systemImage: "bolt.heart.fill")
                Label("Connection \(checkIn.connection)/5", systemImage: "heart.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(HeartSyncTheme.blush)
        }
        .padding(20)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What mattered today?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            TextField("One sentence about the day, tension, or a bright moment", text: $store.todayNote, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            suggestionRow(
                title: "Quick reflection prompts",
                suggestions: store.notePromptSuggestions,
                action: store.applyNoteSuggestion
            )

            TextField("Today’s intention", text: $store.todayIntention, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            suggestionRow(
                title: "Quick intention ideas",
                suggestions: store.intentionSuggestions,
                action: store.applyIntentionSuggestion
            )
        }
        .padding(20)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }

    private func suggestionRow(
        title: String,
        suggestions: [PromptSuggestion],
        action: @escaping (PromptSuggestion) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions) { suggestion in
                        Button {
                            action(suggestion)
                            showSavedState = false
                        } label: {
                            Text(suggestion.text)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(HeartSyncTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func sliderCard(title: String, subtitle: String, value: Binding<Double>, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(HeartSyncTheme.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))/5")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(accent)
            }

            Slider(value: value, in: 1...5, step: 1)
                .tint(accent)

            HStack {
                Text("Needs care")
                Spacer()
                Text("Steady")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
    }
}

struct CheckInView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInView()
            .environmentObject(HeartSyncStore())
    }
}
