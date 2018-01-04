import Foundation
import Utility

class RunCommand: PackageCommand {

    var commandArgument: PositionalArgument<[String]>!

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "run", description: "Installs and then runs a package")
        commandArgument = subparser.add(positional: "command", kind: [String].self, optional: true, strategy: .remaining, usage: "The command to run. This will default to the package name")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
        let arguments = parsedArguments.get(commandArgument)
        try mint.run(repo: repo, version: version, verbose: verbose, arguments: arguments)
    }
}
