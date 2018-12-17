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
    case packageReadError( String)

    public var description: String {
        switch self {
        case .packageNotFound(let package): return "\(package.quoted) package not found"
        case .repoNotFound(let repo): return "Git repo not found at \(repo.quoted)"
        case .cloneError(let package): return "Couldn't clone \(package.gitPath) \(package.version)"
        case .mintfileNotFound(let path): return "\(path) not found"
        case .invalidExecutable(let executable): return "Couldn't find executable \(executable.quoted)"
        case .missingExecutable(let package): return "Executable product not found in \(package.namedVersion)"
        case .packageResolveError(let package): return "Failed to resolve \(package.namedVersion) with SPM"
        case .packageBuildError(let package): return "Failed to build \(package.namedVersion) with SPM"
        case .packageReadError(let error): return "Failed to read Package.swift file:\n\(error)"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }

    public var errorDescription: String? {
        return description
    }
}
