import Foundation
import PathKit

/// Contains all the paths for packages
struct PackagePath {

    var path: Path
    var package: PackageReference
    var executable: String?

    init(path: Path, package: PackageReference, executable: String? = nil) {
        self.path = path
        self.package = package
        self.executable = executable
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
    var executablePath: Path { return installPath + (executable ?? package.name) }

    func getExecutables() throws -> [String] {
        return try installPath.children()
            .filter { $0.isFile && !$0.lastComponent.hasPrefix(".") && $0.extension == nil }
            .map { $0.lastComponent }
    }

    var commandVersion: String {
        return "\(executable ?? package.name) \(package.version)"
    }

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
