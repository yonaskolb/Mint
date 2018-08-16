enum Message: CustomStringConvertible {
    case executableIsNonMintFileWarning(String)
    case executableIsNonMintSymlinkWarning(path: String, symlink: String)
    case manpageIsNonMintFileWarning(String)
    case manpageIsNonMintSymlinkWarning(path: String, symlink: String)

    var description: String {
        switch self {
        case .executableIsNonMintFileWarning(let path):
            return commonMessageForNonMintFileWarning("An executable", path: path)
        case .executableIsNonMintSymlinkWarning(let path, let symlink):
            return commonMessageForNonMintSymlinkWarning("An executable", path: path, symlink: symlink)
        case .manpageIsNonMintFileWarning(let path):
            return commonMessageForNonMintFileWarning("A manpage", path: path)
        case .manpageIsNonMintSymlinkWarning(let path, let symlink):
            return commonMessageForNonMintSymlinkWarning("A manpage", path: path, symlink: symlink)
        }
    }
}

private func commonMessageForNonMintFileWarning(_ prefix: String, path: String) -> String {
    return "\(prefix) that was not installed by mint already exists at \(path)."
}

private func commonMessageForNonMintSymlinkWarning(_ prefix: String, path: String, symlink: String) -> String {
    return "\(prefix) that was not installed by mint already exists at \(path) that is symlinked to \(symlink)."
}

func message(_ message: Message) -> String {
    return message.description
}
