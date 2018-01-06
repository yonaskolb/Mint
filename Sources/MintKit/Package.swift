import Foundation
import PathKit

public class Package {
    public var repo: String
    public var version: String
    public var name: String

    public init(repo: String, version: String, name: String) {
        self.repo = repo
        self.version = version
        self.name = name
    }

    public var commandVersion: String {
        return "\(name) \(version)"
    }
}
