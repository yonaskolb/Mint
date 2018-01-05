import Foundation
import Utility

class UpdateCommand: _InstallCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "update", description: "Updates a package even if it's already installed")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool, executable: String?, global: Bool) throws {

        try mint.install(repo: repo, version: version, command: executable, force: true, verbose: verbose, global: global)
    }
}

class _InstallCommand: PackageCommand {

    var executableArgument: PositionalArgument<String>!
    var globalArgument: OptionArgument<Bool>!

    override init(mint: Mint, parser: ArgumentParser, name: String, description: String) {
        super.init(mint: mint, parser: parser, name: name, description: description)
        executableArgument = subparser.add(positional: "executable", kind: String.self, optional: true, usage: "The executable to install")
        globalArgument = subparser.add(option: "--global", shortName: "-g", kind: Bool.self, usage: "The executable to install")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
        let executable = parsedArguments.get(executableArgument)
        let global = parsedArguments.get(globalArgument) ?? false

        try execute(parsedArguments: parsedArguments, repo: repo, version: version, verbose: verbose, executable: executable, global: global)
    }

    func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool, executable: String?, global: Bool) throws {
    }
}
