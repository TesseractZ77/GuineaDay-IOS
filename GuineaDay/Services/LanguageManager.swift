// LanguageManager.swift
// GuineaDay
//
// Manages app language (English / Simplified Chinese).
// Language is stored in UserDefaults so it persists across launches.
// Changing `language` triggers instant UI re-render via @Published + EnvironmentObject.

import SwiftUI
import Combine

// MARK: - Language enum

enum AppLanguage: String, CaseIterable {
    case english          = "en"
    case simplifiedChinese = "zh-Hans"

    var displayName: String {
        switch self {
        case .english:           return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

// MARK: - Manager

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var language: AppLanguage

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        language = AppLanguage(rawValue: saved) ?? .english
    }

    func set(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
    }

    /// Convenience: true when Simplified Chinese is active.
    var isZh: Bool { language == .simplifiedChinese }
}
