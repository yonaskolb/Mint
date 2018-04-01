import Foundation
import Utility

class RunCommand: PackageCommand {

    var commandArgument: PositionalArgument<[String]>!

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "run", description: "Install and then run a package")
        commandArgument = subparser.add(positional: "command", kind: [String].self, optional: true, strategy: .remaining, usage: "The command to run. This will default to the package name")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool) throws {
      try super.execute(parsedArguments: parsedArguments, repo: repo, version: version, verbose: verbose)
      
      var arguments = parsedArguments.get(commandArgument)

        // backwards compatability for arguments surrounded in quotes
        if let args = arguments,
            args.count == 1,
            let firstArg = args.first,
            firstArg.contains(" ") {
            arguments = firstArg.split(separator: " ").map(String.init)
        }
      
      try mint.run(repo: repo, version: version, verbose: verbose, mintPath: self.mintPath(parsedArguments: parsedArguments), installPath: self.installationPath!, arguments: arguments)
    }
}
