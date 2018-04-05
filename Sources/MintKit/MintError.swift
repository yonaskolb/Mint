import Foundation

public enum MintError: Error, CustomStringConvertible, Equatable, LocalizedError {
    case packageNotFound(String)
    case repoNotFound(String)
    case invalidCommand(String)
    case invalidRepo(String)
    case buildError(Error, String)

    public var description: String {
        switch self {
        case let .packageNotFound(package): return "\(package.quoted) package not found "
        case let .repoNotFound(repo): return "Git repo not found at \(repo.quoted)"
        case let .invalidCommand(command): return "Couldn't find command \(command)"
        case let .invalidRepo(repo): return "Invalid repo \(repo.quoted)"
        case let .buildError(_, reason): return "Build error:\n\(reason)"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }

    public var errorDescription: String? {
        return description
    }
}
