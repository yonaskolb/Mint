import Foundation
import Utility

class InstallCommand: InstallOrUpdateCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(
            mint: mint,
            parser: parser,
            name: "install",
            description: "Install a package. If the version is already installed no action will be taken",
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
            description: "Update a package even if it's already installed",
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
        globalArgument = subparser.add(option: "--global", shortName: "-g", kind: Bool.self, usage: "Whether to install the executable globally. Defaults to true")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
        try super.execute(parsedArguments: parsedArguments, repo: repo, version: version, verbose: verbose)
      
        let executable = parsedArguments.get(executableArgument)
        let global = parsedArguments.get(globalArgument) ?? true

      try mint.install(repo: repo, version: version, mintPath: self.mintPath(parsedArguments: parsedArguments), installationPath:self.installationPath!, command: executable, update: update, verbose: verbose, global: global)
    }
}
