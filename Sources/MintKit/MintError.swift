import Foundation
import SwiftCLI

public enum MintError: Error, CustomStringConvertible, Equatable, LocalizedError {
    case packageNotFound(String)
    case repoNotFound(String)
    case buildError(String)
    case missingExecutable
    case invalidExecutable(String)
    case cloneError(url: String, version: String)
    case mintfileNotFound(String)
    case packageFileNotFound

    public var description: String {
        switch self {
        case let .packageNotFound(package): return "\(package.quoted) package not found"
        case let .repoNotFound(repo): return "Git repo not found at \(repo.quoted)"
        case let .cloneError(url, version): return "Couldn't clone \(url) \(version)"
        case let .buildError(error): return error
        case let .mintfileNotFound(path): return "\(path) not found"
        case let .invalidExecutable(executable): return "Couldn't find executable \(executable.quoted)"
        case .missingExecutable: return "Executable product not found"
        case .packageFileNotFound: return "Package.swift not found"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }

    public var errorDescription: String? {
        return description
    }
}
