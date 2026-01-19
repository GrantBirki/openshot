import Foundation

enum BuildInfo {
    static let appVersion: String? = appVersionValue()
    static let gitSHA: String? = gitSHAValue()

    static let displayVersion: String = {
        if let version = appVersion {
            return "v\(version)"
        }
        return "v0.0.0"
    }()

    static let shortGitSHA: String = {
        if let sha = gitSHA {
            if sha.count >= 8 {
                return String(sha.prefix(8))
            }
            return sha
        }
        return "--------"
    }()

    private static func appVersionValue() -> String? {
        let candidates = [
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            ProcessInfo.processInfo.environment["MARKETING_VERSION"],
            ProcessInfo.processInfo.environment["CURRENT_PROJECT_VERSION"],
        ]

        for candidate in candidates {
            if let sanitized = sanitize(candidate) {
                return sanitized
            }
        }

        return nil
    }

    private static func gitSHAValue() -> String? {
        let candidates = [
            Bundle.main.object(forInfoDictionaryKey: "GIT_SHA") as? String,
            Bundle.main.object(forInfoDictionaryKey: "GitCommit") as? String,
            ProcessInfo.processInfo.environment["GIT_SHA"],
        ]

        for candidate in candidates {
            if let sanitized = sanitize(candidate) {
                return sanitized
            }
        }

        return nil
    }

    private static func sanitize(_ value: String?) -> String? {
        guard var value else { return nil }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if value.contains("$(") {
            return nil
        }
        if value.lowercased() == "unknown" {
            return nil
        }
        return value
    }
}
