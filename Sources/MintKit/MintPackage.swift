import Foundation

public struct MintPackage {
    public let repo: String
    public let version: String

    public init(repo: String, version: String = "") {
        self.repo = repo
        self.version = version
    }

    public init(package: String) {
        let packageParts = package.components(separatedBy: "@")
        if packageParts.count == 3 {
            self.init(repo: [packageParts[0], packageParts[1]].joined(separator: "@"), version: packageParts[2])
        } else if packageParts.count == 2 {
            if packageParts[1].contains(":") {
                self.init(repo: [packageParts[0], packageParts[1]].joined(separator: "@"), version: "")
            } else {
                self.init(repo: packageParts[0], version: packageParts[1])
            }
        } else {
            self.init(repo: package, version: "")
        }
    }
}

extension MintPackage: Equatable {
    public static func == (lhs: MintPackage, rhs: MintPackage) -> Bool {
        return lhs.repo == rhs.repo && lhs.version == rhs.version
    }
}
