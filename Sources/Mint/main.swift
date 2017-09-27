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

let command = Command(usage: "mint")
command.run = { _, _  in
    print(command.helpMessage)
}

let repoHelp = "You must pass a repo either in the shorthand for of a github repo \"githubName/repo\", or a fully qualified .git path.\nAn optional version can be passed, otherwise the newest tag or master will be used"
let versionFlag = Flag(shortName: "v", longName: "version", type: String.self, description: "The version to use. Usually this is a tag, but can also be a branch. If left out will use the latest tag or master")

let nameFlag = Flag(shortName: "n", longName: "name", type: String.self, description: "The command to run")

let argsFlag = Flag(shortName: "a", longName: "args", type: String.self, description: "the arguments to pass to the command being run")

let runCommand = Command(usage: "run repo (version)", shortMessage: "Run a package", longMessage: "This will run a package tool. If it isn't installed if will do so first.\n\(repoHelp)", flags: [nameFlag, argsFlag], example: "mint run realm/swiftlint 0.22.0") { flags, args in
    guard let repo = args.first else {
        print("repo required".red)
        return
    }
    let version = args.count >= 2 ? args[1] : ""
    let name = flags.getString(name: "name")
    let arguments = flags.getString(name: "args")
    catchError {
        try Mint.run(repo: repo, version: version, name: name, arguments: arguments)
    }
}

let installCommand = Command(usage: "install repo (version)", shortMessage: "Install a package", longMessage: "This will install a package. If it's already installed no action will be taken.\n\(repoHelp)", flags: [nameFlag], example: "mint install realm/swiftlint 0.22.0") { flags, args in
    guard let repo = args.first else {
        print("repo required".red)
        return
    }
    let version = args.count >= 2 ? args[1] : ""
    let name = flags.getString(name: "name")
    catchError {
        try Mint.install(repo: repo, version: version, name: name, force: false)
    }
}

let updateCommand = Command(usage: "update repo (version)", shortMessage: "Update a package", longMessage: "This will update a package even if it's already installed.\n\(repoHelp)", flags: [nameFlag], example: "mint install realm/swiftlint 0.22.0") { flags, args in
    guard let repo = args.first else {
        print("repo required".red)
        return
    }
    let version = args.count >= 2 ? args[1] : ""
    let name = flags.getString(name: "name")
    catchError {
        try Mint.install(repo: repo, version: version, name: name, force: true)
    }
}

let bootstrapCommand = Command(usage: "bootstrap") { flags, args in

}
command.add(subCommand: runCommand)
command.add(subCommand: installCommand)
//command.add(subCommand: bootstrapCommand)

command.execute()

