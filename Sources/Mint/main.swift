import MintKit
import Rainbow
import Foundation
import SwiftShell
import Guaka

let version = "0.6.1"

let mint = Mint(path: "/usr/local/lib/mint")

func catchError(closure: () throws -> Void) {
    do {
        try closure()
    } catch {
        if let error = error as? CommandError {
            print("🌱  \(error.description)".red)
        } else if let error = error as? SwiftShell.CommandError {
            switch error {
            case .inAccessibleExecutable(let path): main.stderror.print("Couldn't run command \(path)")
            case .returnedErrorCode(let command, _): main.stderror.print("\(command.quoted) failed")
            }
        } else if let error = error as? MintError {
            print("🌱  \(error.description)".red)
        } else {
            print("🌱  \(error.localizedDescription)".red)
        }
        exit(1)
    }
}

enum CommandError: Error, CustomStringConvertible {
    case repoRequired
    case invalidRepo(String)
    case tooManyArguments

    var description: String {
        switch self {
        case .repoRequired:
            return "Repo required"
        case let .invalidRepo(repo):
            return "The repo was invalid: \(repo)"
        case .tooManyArguments:
            return "Too many arguments. Make sure command is surrounded in quotes"
        }
    }
}

func getOptions(flags: Flags, args: [String]) throws -> (repo: String, version: String, command: String, verbose: Bool) {
    guard let repoVersion = args.first else { throw CommandError.repoRequired }
    let version: String
    let command: String
    let repoVersionParts = repoVersion.components(separatedBy: "@")
    let repo: String

    switch repoVersionParts.count {
    case 2:
        repo = repoVersionParts[0]
        version = repoVersionParts[1]
    case 1:
        repo = repoVersion
        version = ""
    default:
        throw CommandError.invalidRepo(repoVersion)
    }

    switch args.count {
    case 2:
        command = args[1]
    case 1:
        command = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
    default:
        throw CommandError.tooManyArguments
    }
    return (repo: repo, version: version, command: command, verbose: flags.getBool(name: "verbose") ?? false)
}

let versionFlag = Flag(longName: "version", value: false, description: "Prints the version")
let verboseFlag = Flag(longName: "verbose", value: false, description: "Show installation output")

let command = Command(usage: "mint", flags: [versionFlag])
command.run = { flags, _ in
    if let hasVersion = flags.getBool(name: "version"), hasVersion {
        print(version)
        return
    }
    print(command.helpMessage)
}

let commandHelp = """
This command takes allows you to specify a repo, a version and an executable command to run.

- Repo is either in shorthand for a github repo \"githubName/repo\", or a fully qualified .git path.
- An optional version can be specified by appending @version to the repo, otherwise the newest tag or master will be used.
- The second argument qualifies the command name, otherwise this will be assumed to the be the end of the repo name.
"""

let runCommand = Command(usage: "run repo (version) (command)", shortMessage: "Run a package", longMessage: "This will run a package tool. If it isn't installed if will do so first.\n\(commandHelp) The command can include any arguments and flags but the whole command must then be surrounded in quotes.", flags: [verboseFlag], example: "mint run realm/SwiftLint@0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try mint.run(repo: options.repo, version: options.version, command: options.command, verbose: options.verbose)
    }
}

let installCommand = Command(usage: "install repo (version) (command)", shortMessage: "Install a package", longMessage: "This will install a package. If it's already installed no action will be taken.\n\(commandHelp)", flags: [verboseFlag], example: "mint install realm/SwiftLint@0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try mint.install(repo: options.repo, version: options.version, command: options.command, force: false, verbose: options.verbose)
    }
}

let updateCommand = Command(usage: "update repo (version) (command)", shortMessage: "Update a package", longMessage: "This will update a package even if it's already installed.\n\(commandHelp)", flags: [verboseFlag], example: "mint install realm/SwiftLint@0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try mint.install(repo: options.repo, version: options.version, command: options.command, force: true, verbose: options.verbose)
    }
}

let listCommand = Command(usage: "list", shortMessage: "List packages", longMessage: "This lists all the currently installed packages", example: "mint list") { _, _ in
    catchError {
        try mint.listPackages()
    }
}

let bootstrapCommand = Command(usage: "bootstrap") { _, _ in
}

command.add(subCommand: runCommand)
command.add(subCommand: installCommand)
command.add(subCommand: updateCommand)
command.add(subCommand: listCommand)

command.execute()
