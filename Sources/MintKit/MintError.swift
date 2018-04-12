import Foundation

public enum MintError: Error, CustomStringConvertible, Equatable, LocalizedError {
    case packageNotFound(String)
    case repoNotFound(String)
    case invalidCommand(String)
    case invalidRepo(String)
    case buildError(error: Error, stderror: String, stdout: String)

    public var description: String {
        switch self {
        case let .packageNotFound(package): return "\(package.quoted) package not found ".red
        case let .repoNotFound(repo): return "Git repo not found at \(repo.quoted)".red
        case let .invalidCommand(command): return "Couldn't find command \(command)".red
        case let .invalidRepo(repo): return "Invalid repo \(repo.quoted)".red
        case let .buildError(_, stderr, stdout): return "Build error:".red + "\n\(stderr)\(stdout.isEmpty ? "" : "\n\nFull output:\n")\(stdout)"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }

    public var errorDescription: String? {
        return description
    }
}
