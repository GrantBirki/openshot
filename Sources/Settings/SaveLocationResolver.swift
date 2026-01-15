import Foundation

enum SaveLocationResolver {
    static func resolve(option: SaveLocationOption, customPath: String) -> URL {
        let fileManager = FileManager.default
        let defaultURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

        switch option {
        case .downloads:
            return defaultURL
        case .desktop:
            return fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        case .documents:
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .custom:
            let trimmed = customPath.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return defaultURL
            }

            let expanded = (trimmed as NSString).expandingTildeInPath
            if !(expanded as NSString).isAbsolutePath {
                return defaultURL
            }

            let customURL = URL(fileURLWithPath: expanded)
            return customURL.standardizedFileURL.resolvingSymlinksInPath()
        }
    }
}
