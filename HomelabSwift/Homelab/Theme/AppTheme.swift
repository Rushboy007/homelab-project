import SwiftUI

// MARK: - Semantic colors (map exactly from constants/themes.ts)
// All colors use light/dark adaptive Color sets

enum AppTheme {
    // Accent
    static let accent = Color("AccentColor")

    // Semantic status colors
    static var running: Color { Color(hex: "#3FB950") }      // dark: #3FB950 / light: #2DA44E
    static var stopped: Color { Color(hex: "#F85149") }      // dark: #F85149 / light: #CF222E
    static var paused: Color { Color(hex: "#D29922") }       // dark: #D29922 / light: #BF8700
    static var created: Color { Color(hex: "#58A6FF") }      // dark: #58A6FF / light: #0969DA
    static var info: Color { Color(hex: "#58A6FF") }
    static var danger: Color { Color(hex: "#F85149") }
    static var warning: Color { Color(hex: "#D29922") }

    // Background & surface (used for content areas not covered by glass)
    static var background: Color { Color(.systemGroupedBackground) }
    static var surface: Color { Color(.secondarySystemGroupedBackground) }

    // Text
    static var textSecondary: Color { Color(.secondaryLabel) }
    static var textMuted: Color { Color(.tertiaryLabel) }

    // Corner radii
    static let cardRadius: CGFloat = 20
    static let smallRadius: CGFloat = 12
    static let pillRadius: CGFloat = 100

    // Spacing
    static let padding: CGFloat = 16
    static let innerPadding: CGFloat = 12
    static let gridSpacing: CGFloat = 12

    // MARK: - Container status color

    static func statusColor(for state: String) -> Color {
        switch state.lowercased() {
        case "running":                    return running
        case "exited", "dead":             return stopped
        case "paused":                     return paused
        case "created", "restarting":      return created
        default:                           return .gray
        }
    }

    // MARK: - System status for Beszel

    static func systemStatusColor(online: Bool) -> Color {
        online ? running : stopped
    }
}

// MARK: - Adaptive status color (light/dark aware)

extension Color {
    static func adaptiveStatusColor(for state: String) -> Color {
        AppTheme.statusColor(for: state)
    }
}
