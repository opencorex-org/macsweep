import SwiftUI
import Combine

// MARK: - AppLanguage

/// Represents a supported app language with its locale code and native display name.
public enum AppLanguage: String, CaseIterable, Identifiable {
    public static let preferenceKey = "AppSelectedLanguageCode"

    // English
    case english    = "en"

    // European
    case french     = "fr"
    case german     = "de"
    case spanish    = "es"
    case italian    = "it"
    case portuguese = "pt"
    case portugueseBrazil = "pt-BR"
    case dutch      = "nl"
    case polish     = "pl"
    case russian    = "ru"
    case bulgarian  = "bg"
    case croatian   = "hr"
    case czech      = "cs"
    case danish     = "da"
    case estonian   = "et"
    case finnish    = "fi"
    case greek      = "el"
    case hungarian  = "hu"
    case irish      = "ga"
    case latvian    = "lv"
    case lithuanian = "lt"
    case maltese    = "mt"
    case romanian   = "ro"
    case slovak     = "sk"
    case slovenian  = "sl"
    case swedish    = "sv"

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
        case .portuguese:         return "Português (Portugal)"
        case .portugueseBrazil:   return "Português (Brasil)"
        case .dutch:              return "Nederlands"
        case .polish:             return "Polski"
        case .russian:            return "Русский"
        case .bulgarian:          return "Български"
        case .croatian:           return "Hrvatski"
        case .czech:              return "Čeština"
        case .danish:             return "Dansk"
        case .estonian:           return "Eesti"
        case .finnish:            return "Suomi"
        case .greek:              return "Ελληνικά"
        case .hungarian:          return "Magyar"
        case .irish:              return "Gaeilge"
        case .latvian:            return "Latviešu"
        case .lithuanian:         return "Lietuvių"
        case .maltese:            return "Malti"
        case .romanian:           return "Română"
        case .slovak:             return "Slovenčina"
        case .slovenian:          return "Slovenščina"
        case .swedish:            return "Svenska"
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
        case .french, .german, .spanish, .italian, .portuguese, .portugueseBrazil,
             .dutch, .polish, .russian, .bulgarian, .croatian, .czech, .danish,
             .estonian, .finnish, .greek, .hungarian, .irish, .latvian,
             .lithuanian, .maltese, .romanian, .slovak, .slovenian, .swedish:
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
/// Single source of truth for the in-app locale. Views observe this object,
/// while persistence remains an implementation detail of the store.
@MainActor
public final class LocalizationStore: ObservableObject {
    @Published public private(set) var language: AppLanguage
    private let defaults: UserDefaults

    public var locale: Locale { Locale(identifier: language.rawValue) }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedCode = defaults.string(forKey: AppLanguage.preferenceKey) ?? AppLanguage.english.rawValue
        self.language = AppLanguage.from(code: savedCode)
    }

    public func select(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        defaults.set(language.rawValue, forKey: AppLanguage.preferenceKey)
    }
}
