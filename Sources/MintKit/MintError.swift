import Foundation
import SwiftCLI

public enum MintError: Error, CustomStringConvertible, Equatable, LocalizedError {
    case packageNotFound(String)
    case repoNotFound(String)
    case missingExecutable(PackageReference)
    case invalidExecutable(String)
    case cloneError(PackageReference)
    case mintfileNotFound(String)
    case packageResolveError(PackageReference)
    case packageBuildError(PackageReference)
    case packageReadError(String)
    case packageNotInstalled(PackageReference)
    case inconsistentCache(String)

    public var description: String {
        switch self {
        case let .packageNotFound(package): "\(package.quoted) package not found"
        case let .repoNotFound(repo): "Git repo not found at \(repo.quoted)"
        case let .cloneError(package): "Couldn't clone \(package.gitPath) \(package.version)"
        case let .mintfileNotFound(path): "\(path) not found"
        case let .invalidExecutable(executable): "Couldn't find executable \(executable.quoted)"
        case let .missingExecutable(package): "Executable product not found in \(package.namedVersion)"
        case let .packageResolveError(package): "Failed to resolve \(package.namedVersion) with SPM"
        case let .packageBuildError(package): "Failed to build \(package.namedVersion) with SPM"
        case let .packageReadError(error): "Failed to read Package.swift file:\n\(error)"
        case let .packageNotInstalled(package): "\(package.namedVersion) not installed"
        case let .inconsistentCache(error): "Inconsistent cache, clear it up.\nError: \(error)"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        lhs.description == rhs.description
    }

    public var errorDescription: String? {
        description
    }
}
