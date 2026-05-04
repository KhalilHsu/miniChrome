import Foundation

enum L10n {
    private static let languageKey = "appLanguage"

    static func tr(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: languageKey) ?? "system"
        guard language != "system",
              let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }
}
