import Foundation
import PathKit

public class PackageReference {
    public var repo: String
    public var version: String

    public init(repo: String, version: String = "") {
        self.repo = repo
        self.version = version
    }

    public convenience init(package: String) {
        let packageParts = package.components(separatedBy: "@")
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
            } else {
                repo = packageParts[0]
                version = packageParts[1]
            }
        } else {
            repo = package
            version = ""
        }
        self.init(repo: repo, version: version)
    }

    public var namedVersion: String {
        return "\(name) \(version)"
    }

    public var name: String {
        return repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
    }
}

extension PackageReference: Equatable {
    public static func == (lhs: PackageReference, rhs: PackageReference) -> Bool {
        return lhs.repo == rhs.repo && lhs.version == rhs.version
    }
}

