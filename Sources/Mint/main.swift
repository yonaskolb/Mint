import MintKit
import Rainbow
import Foundation
import ShellOut
import Guaka

func catchError(closure: () throws -> ()) {
    do {
        try closure()
    } catch {
        if let error = error as? ShellOutError {
            if !error.message.isEmpty {
                print(error.message.red)
            }
            if !error.output.isEmpty {
                print(error.output)
            }
        } else {
            print("🌱  Error: \(error)".red)
        }
        exit(1)
    }
}

enum CommandError: Error, CustomStringConvertible {
    case repoRequired
    case commandNotParsed
    case tooManyArguments

    var description: String {
        switch self {
        case .repoRequired:
            return "Repo required"
        case .commandNotParsed:
            return "Version and command couldn't be automatically parsed. Please pass \"\" for version"
        case .tooManyArguments:
            return "Too many arguments. Make sure command is surrounded in quotes"
        }
    }
}

func getOptions(flags: Flags, args: [String]) throws -> (repo: String, version: String, command: String) {
    guard let repo = args.first else { throw CommandError.repoRequired }
    var version: String = ""
    let command: String
    let extractedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!.lowercased()

    switch args.count {
    case 3:
        version = args[1]
        command = args[2]
    case 2:
        let argument = args[1]
        let string = argument.components(separatedBy: " ").first!
        if string == extractedCommand {
            // string is a command
            command = argument
            version = ""
        } else if string.contains(".") || string == "master" {
            // string is version
            version = string
            command = extractedCommand
        } else {
            throw CommandError.commandNotParsed
        }
    case 1:
        command = extractedCommand
    default:
        throw CommandError.tooManyArguments
    }
    return (repo: repo, version: version, command: command)
}

let command = Command(usage: "mint")
command.run = { _, _  in
    print(command.helpMessage)
}

let commandHelp = """
This command takes between 1 and 3 arguments: repo, version and command.

- You must pass a repo either in the shorthand for of a github repo \"githubName/repo\", or a fully qualified .git path.
- An optional version can be passed, otherwise the newest tag or master will be used.
- An optional command qualifies the command name, otherwise this will be assumed to the be the end of the repo name.
"""

let runCommand = Command(usage: "run repo (version) (command)", shortMessage: "Run a package", longMessage: "This will run a package tool. If it isn't installed if will do so first.\n\(commandHelp) The command can include any arguments and flags but the whole command must then be surrounded in quotes.", example: "mint run realm/swiftlint 0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try Mint.run(repo: options.repo, version: options.version, command: options.command)
    }
}

let installCommand = Command(usage: "install repo (version) (command)", shortMessage: "Install a package", longMessage: "This will install a package. If it's already installed no action will be taken.\n\(commandHelp)", example: "mint install realm/swiftlint 0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try Mint.install(repo: options.repo, version: options.version, command: options.command, force: false)
    }
}

let updateCommand = Command(usage: "update repo (version) (command)", shortMessage: "Update a package", longMessage: "This will update a package even if it's already installed.\n\(commandHelp)", example: "mint install realm/swiftlint 0.22.0") { flags, args in
    catchError {
        let options = try getOptions(flags: flags, args: args)
        try Mint.install(repo: options.repo, version: options.version, command: options.command, force: true)
    }
}

let bootstrapCommand = Command(usage: "bootstrap") { flags, args in

}
command.add(subCommand: runCommand)
command.add(subCommand: installCommand)
command.add(subCommand: updateCommand)

command.execute()

