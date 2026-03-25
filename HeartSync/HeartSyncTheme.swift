import SwiftUI

enum HeartSyncTheme {
    static let canvasTop = Color(red: 0.97, green: 0.91, blue: 0.89)
    static let canvasBottom = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let card = Color.white.opacity(0.76)
    static let cardBorder = Color.white.opacity(0.55)
    static let blush = Color(red: 0.88, green: 0.39, blue: 0.42)
    static let coral = Color(red: 0.96, green: 0.55, blue: 0.43)
    static let sage = Color(red: 0.44, green: 0.65, blue: 0.55)
    static let ink = Color(red: 0.18, green: 0.14, blue: 0.14)

    static let background = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = LinearGradient(
        colors: [blush, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
