import Foundation
import Utility

class InstallCommand: InstallOrUpdateCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(
            mint: mint,
            parser: parser,
            name: "install",
            description: "Installs a package. If the version is already installed no action will be taken",
            update: false
        )
    }
}

class UpdateCommand: InstallOrUpdateCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(
            mint: mint,
            parser: parser,
            name: "update",
            description: "Updates a package even if it's already installed",
            update: true
        )
    }
}

class InstallOrUpdateCommand: PackageCommand {

    var executableArgument: PositionalArgument<String>!
    var globalArgument: OptionArgument<Bool>!

    var update: Bool

    init(mint: Mint, parser: ArgumentParser, name: String, description: String, update: Bool) {
        self.update = update
        super.init(mint: mint, parser: parser, name: name, description: description)
        executableArgument = subparser.add(positional: "executable", kind: String.self, optional: true, usage: "The executable to install")
        globalArgument = subparser.add(option: "--global", shortName: "-g", kind: Bool.self, usage: "The executable to install")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
        let executable = parsedArguments.get(executableArgument)
        let global = parsedArguments.get(globalArgument) ?? false

        try mint.install(repo: repo, version: version, command: executable, update: update, verbose: verbose, global: global)
    }
}
