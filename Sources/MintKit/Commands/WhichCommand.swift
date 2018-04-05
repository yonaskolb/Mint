import Foundation
import Utility

class WhichCommand: PackageCommand {

    var commandArgument: PositionalArgument<String>!

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "which", description: "Print the full path to installed binary")
        commandArgument = subparser.add(positional: "command", kind: String.self, optional: true, usage: "The command to run. This will default to the package name")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
        let command = parsedArguments.get(commandArgument)
        let path = try mint.which(repo: repo, version: version, command: command)

        print(path)
    }
}
