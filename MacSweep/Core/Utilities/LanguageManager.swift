import SwiftUI
import Combine

// MARK: - AppLanguage

/// Represents a supported app language with its locale code and native display name.
public enum AppLanguage: String, CaseIterable, Identifiable {
    // English
    case english    = "en"

    // European
    case french     = "fr"
    case german     = "de"
    case spanish    = "es"
    case italian    = "it"
    case portuguese = "pt"
    case dutch      = "nl"
    case polish     = "pl"
    case russian    = "ru"

    // Indian
    case hindi      = "hi"
    case tamil      = "ta"
    case telugu     = "te"
    case bengali    = "bn"
    case kannada    = "kn"
    case malayalam  = "ml"
    case marathi    = "mr"
    case gujarati   = "gu"

    // Chinese
    case chineseSimplified  = "zh-Hans"
    case chineseTraditional = "zh-Hant"

    // Other major
    case japanese   = "ja"
    case korean     = "ko"
    case arabic     = "ar"

    // Sinhala
    case sinhala    = "si"

    public var id: String { rawValue }

    /// The language's native display name shown in the picker.
    public var nativeName: String {
        switch self {
        case .english:            return "English"
        case .french:             return "Français"
        case .german:             return "Deutsch"
        case .spanish:            return "Español"
        case .italian:            return "Italiano"
        case .portuguese:         return "Português"
        case .dutch:              return "Nederlands"
        case .polish:             return "Polski"
        case .russian:            return "Русский"
        case .hindi:              return "हिन्दी"
        case .tamil:              return "தமிழ்"
        case .telugu:             return "తెలుగు"
        case .bengali:            return "বাংলা"
        case .kannada:            return "ಕನ್ನಡ"
        case .malayalam:          return "മലയാളം"
        case .marathi:            return "मराठी"
        case .gujarati:           return "ગુજરાતી"
        case .chineseSimplified:  return "中文（简体）"
        case .chineseTraditional: return "中文（繁體）"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .arabic:             return "العربية"
        case .sinhala:            return "සිංහල"
        }
    }

    /// A brief English group label used to group languages in the picker.
    public var groupName: String {
        switch self {
        case .english:
            return "English"
        case .french, .german, .spanish, .italian, .portuguese, .dutch, .polish, .russian:
            return "European"
        case .hindi, .tamil, .telugu, .bengali, .kannada, .malayalam, .marathi, .gujarati:
            return "Indian"
        case .chineseSimplified, .chineseTraditional:
            return "Chinese"
        case .japanese, .korean, .arabic:
            return "Other"
        case .sinhala:
            return "Sinhala"
        }
    }

    /// Initialise from a stored locale code string, defaulting to English.
    public static func from(code: String) -> AppLanguage {
        AppLanguage(rawValue: code) ?? .english
    }
}

// MARK: - LanguageManager

/// Singleton that manages in-app language preference.
/// On language change the preference is persisted and an app restart is
/// required for macOS to load the new bundle language resources.
@MainActor
public final class LanguageManager: ObservableObject {

    public static let shared = LanguageManager()

    // The UserDefaults key used to store the user's language choice.
    private static let userDefaultsKey = "AppSelectedLanguageCode"

    @Published public private(set) var currentLanguage: AppLanguage

    private init() {
        let savedCode = UserDefaults.standard.string(forKey: Self.userDefaultsKey) ?? "en"
        currentLanguage = AppLanguage.from(code: savedCode)
    }

    // MARK: - Public API

    /// Call once at app startup (before any window is shown) to apply the saved language.
    public func applyOnLaunch() {
        let code = UserDefaults.standard.string(forKey: Self.userDefaultsKey) ?? "en"
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    /// Change the app language. Saves the preference and returns `true` if a restart
    /// is required (i.e., the language actually changed).
    @discardableResult
    public func setLanguage(_ language: AppLanguage) -> Bool {
        guard language != currentLanguage else { return false }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        return true
    }
}
