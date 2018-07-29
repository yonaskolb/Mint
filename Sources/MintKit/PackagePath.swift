import Foundation
import PathKit

/// Contains all the paths for packages
struct PackagePath {

    let path: Path
    let package: Package

    init(path: Path, package: Package) {
        self.path = path
        self.package = package
    }

    var gitPath: String { return PackagePath.gitURLFromString(package.repo) }

    var repoPath: String {
        return gitPath
            .components(separatedBy: "://").last!
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".git", with: "")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "@", with: "_")
    }

    var packagePath: Path { return path + repoPath }
    var installPath: Path { return packagePath + "build" + package.version }
    var commandPath: Path { return installPath + package.name }
    var manpagesPath: Path { return installPath + "share/man" }

    static func gitURLFromString(_ string: String) -> String {
        if let url = URL(string: string), url.scheme != nil {
            return url.absoluteString
        } else {
            if string.contains("@") {
                return string
            } else if string.contains("github.com") {
                return "https://\(string).git"
            } else if string.contains(".") {
                return "https://\(string)"
            } else {
                return "https://github.com/\(string).git"
            }
        }
    }
}
