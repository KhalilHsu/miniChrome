import Foundation

enum L10n {
    private static let languageKey = "appLanguage"

    static func tr(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: languageKey) ?? "zh-Hans"
        return tr(key, language: language)
    }

    static func tr(_ key: String, language: String) -> String {
        if language == "en" {
            return key
        }

        let resolvedLanguage = language == "system" ? "zh-Hans" : language
        guard let path = Bundle.main.path(forResource: resolvedLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }

    static func format(_ key: String, language: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key, language: language), locale: Locale.current, arguments: arguments)
    }
}
