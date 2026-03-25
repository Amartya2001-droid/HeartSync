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

                    reflectionCard

                    Button {
                        store.submitCheckIn()
                        showSavedState = true
                    } label: {
                        Text(showSavedState ? "Saved for today" : "Save today’s check-in")
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

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What mattered today?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(HeartSyncTheme.ink)

            TextField("One sentence about the day, tension, or a bright moment", text: $store.todayNote, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            TextField("Today’s intention", text: $store.todayIntention, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(16)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(20)
        .background(HeartSyncTheme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(HeartSyncTheme.cardBorder, lineWidth: 1)
        )
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
