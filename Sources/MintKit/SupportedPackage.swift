import Foundation

public enum PackageType: String, CaseIterable {
    case swift
    case gem

    public var packageManager: String {
        switch self {
        case .gem:
            return "gem"

        case .swift:
            return "SPM"
        }
    }
}
