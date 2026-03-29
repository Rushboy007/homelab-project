import Foundation

enum AppIconOption: String, CaseIterable {
    case `default`
    case dark
    case clearLight
    case clearDark
    case tintedLight
    case tintedDark

    var alternateIconName: String? {
        switch self {
        case .default:
            return nil
        case .dark:
            return "AppIconDark"
        case .clearLight:
            return "AppIconClearLight"
        case .clearDark:
            return "AppIconClearDark"
        case .tintedLight:
            return "AppIconTintedLight"
        case .tintedDark:
            return "AppIconTintedDark"
        }
    }

    static func fromAlternateIconName(_ name: String?) -> AppIconOption {
        switch name {
        case "AppIconDark":
            return .dark
        case "AppIconClearLight":
            return .clearLight
        case "AppIconClearDark":
            return .clearDark
        case "AppIconTintedLight":
            return .tintedLight
        case "AppIconTintedDark":
            return .tintedDark
        default:
            return .default
        }
    }
}
