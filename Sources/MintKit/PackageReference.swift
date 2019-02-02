import Foundation
import PathKit

public class PackageReference {
    public var repo: String
    public var version: String
    public private(set) var packagePath: String

    public init(repo: String, version: String = "", packagePath: String = ".") {
        self.repo = repo
        self.version = version
        self.packagePath = packagePath
    }

    public convenience init(package: String) {
        let pathComponents = package.components(separatedBy: "=>")
        let packagePath = pathComponents.count == 2 ? pathComponents[1] : "."
        let repoAndVersionPackage = pathComponents.count == 2 ? pathComponents[0] : package
        let packageParts = repoAndVersionPackage.components(separatedBy: "@")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let repo: String
        let version: String
        if packageParts.count == 3 {
            repo = [packageParts[0], packageParts[1]].joined(separator: "@")
            version = packageParts[2]
        } else if packageParts.count == 2 {
            if packageParts[1].contains(":") {
                repo = [packageParts[0], packageParts[1]].joined(separator: "@")
                version = ""
            } else if packageParts[0].contains("ssh://") {
                repo = [packageParts[0], packageParts[1]].joined(separator: "@")
                version = ""
            } else {
                repo = packageParts[0]
                version = packageParts[1]
            }
        } else {
            repo = repoAndVersionPackage
            version = ""
        }
        self.init(repo: repo, version: version, packagePath: packagePath)
    }

    public var namedVersion: String {
        return "\(name) \(version)"
    }

    public var name: String {
        return repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
    }

    public var gitPath: String {
        if let url = URL(string: repo), url.scheme != nil {
            return url.absoluteString
        } else {
            if repo.contains("@") {
                return repo
            } else if repo.contains("github.com") {
                return "https://\(repo).git"
            } else if repo.contains(".") {
                return "https://\(repo)"
            } else {
                return "https://github.com/\(repo).git"
            }
        }
    }

    var repoPath: String {
        return gitPath
            .components(separatedBy: "://").last!
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".git", with: "")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "@", with: "_")
    }
}

extension PackageReference: Equatable {
    public static func == (lhs: PackageReference, rhs: PackageReference) -> Bool {
        return lhs.repo == rhs.repo && lhs.version == rhs.version
    }
}
