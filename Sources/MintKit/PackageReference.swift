import Foundation
import PathKit

public class PackageReference {
    public var repo: String
    public var version: Revision

    public enum Revision: Equatable, ExpressibleByStringLiteral {
        public typealias StringLiteralType = String

        case tag(String)
        case branch(String)
        case commit(String)
        case unspecified
        case unknown

        var string: String {
            switch self {
            case .tag(name: let name), .branch(name: let name), .commit(hash: let name):
                return name
            case .unspecified, .unknown:
                return ""
            }
        }

        public init(stringLiteral value: String) {
            let parts = value.split(separator: ":")

            if parts.count == 1 {
                self = .branch(value)
            } else if parts.count == 2 {
                let name = String(parts[1])
                switch parts[0] {
                case "tag":
                    self = .tag(name)
                case "commit":
                    self = .commit(name)
                case "branch":
                    self = .branch(name)
                default:
                    self = .unknown
                }
            } else {
                self = .unspecified
            }
        }

        init(versionString: String) {
            self.init(stringLiteral: versionString)
        }

        var isSpecified: Bool {
            switch self {
            case .unspecified:
                return false
            default:
                return true
            }
        }
    }

    public init(repo: String, version: Revision = .unspecified) {
        self.repo = repo
        self.version = version
    }

    public convenience init(package: String) {
        let packageParts = package.components(separatedBy: "@")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let repo: String
        let version: Revision
        if packageParts.count == 3 {
            repo = [packageParts[0], packageParts[1]].joined(separator: "@")
            version = Revision(versionString: packageParts[2])
        } else if packageParts.count == 2 {
            if packageParts[1].contains(":") {
                repo = packageParts[0]
                version = Revision(versionString: packageParts[1])
            } else if packageParts[0].contains("ssh://") {
                repo = [packageParts[0], packageParts[1]].joined(separator: "@")
                version = .unspecified
            } else {
                repo = packageParts[0]
                version = Revision(versionString: packageParts[1])
            }
        } else {
            repo = package
            version = .unspecified
        }
        self.init(repo: repo, version: version)
    }

    public var namedVersion: String {
        return "\(name) \(version)"
    }

    public var name: String {
        return repo.components(separatedBy: "/").last!.replacingOccurrences(of: ".git", with: "")
    }

    public var gitPath: String {
        if let url = URL(string: repo), url.scheme != nil {
            return url.absoluteString
        } else {
            if repo.contains("@") {
                return repo
            } else if repo.contains("github.com") {
                return "https://\(repo).git"
            } else if repo.components(separatedBy: "/").first!.contains(".") {
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
