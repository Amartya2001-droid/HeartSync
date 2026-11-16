import SwiftUI

enum HeartSyncBrand {
    static let name = "HeartSync"
    static let tagline = "A small pause, together."
    static let sharedDeviceNotice = "Two perspectives on the same device. Anyone using this app can read both responses. JSON backups include both, so review them before sharing."
}

struct HeartSyncBrandLockup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("HeartSyncBrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            Text(HeartSyncBrand.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(HeartSyncTheme.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("brand.name")
            Text(HeartSyncBrand.tagline)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
    }
}
