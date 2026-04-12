import Foundation

/// Controls whether the app runs in local-only mode (China Mainland)
/// or full cloud-sync mode (International).
enum AppMode: String {
    case local = "local"   // 中国大陆 — SwiftData only, no Firebase
    case cloud = "cloud"   // International — Firebase + SwiftData

    // MARK: - Persistence
    private static let modeKey     = "appMode"
    private static let shownKey    = "hasShownRegionSelector"

    /// The currently selected mode, defaulting to cloud if unset.
    static var current: AppMode {
        AppMode(rawValue: UserDefaults.standard.string(forKey: modeKey) ?? "") ?? .cloud
    }

    /// Persist the user's choice and mark the selector as shown.
    static func set(_ mode: AppMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
        UserDefaults.standard.set(true,          forKey: shownKey)
    }

    /// True once the user has made their first region choice.
    /// Resets whenever the app is re-installed (UserDefaults cleared).
    static var hasBeenChosen: Bool {
        UserDefaults.standard.bool(forKey: shownKey)
    }

    // MARK: - Helpers
    var isLocal: Bool { self == .local }
    var isCloud: Bool { self == .cloud }
}
