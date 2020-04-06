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
    case packageBuildError(PackageReference, PackageType)
    case packageReadError(String)
    case packageNotInstalled(PackageReference)
    case repoNotSupported(String)

    public var description: String {
        switch self {
        case let .packageNotFound(package): return "\(package.quoted) package not found"
        case let .repoNotFound(repo): return "Git repo not found at \(repo.quoted)"
        case let .cloneError(package): return "Couldn't clone \(package.gitPath) \(package.version)"
        case let .mintfileNotFound(path): return "\(path) not found"
        case let .invalidExecutable(executable): return "Couldn't find executable \(executable.quoted)"
        case let .missingExecutable(package): return "Executable product not found in \(package.namedVersion)"
        case let .packageResolveError(package): return "Failed to resolve \(package.namedVersion) with SPM"
        case let .packageBuildError(package, type): return "Failed to build \(package.namedVersion) with \(type.packageManager)"
        case let .packageReadError(error): return "Failed to read Package.swift file:\n\(error)"
        case let .packageNotInstalled(package): return "\(package.namedVersion) not installed"
        case let .repoNotSupported(repo): return "Repository '\(repo)' does not contain a supported package. Supported package types: \(PackageType.allCases.map { $0.rawValue }.joined(separator: " ,"))"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }

    public var errorDescription: String? {
        return description
    }
}
