import Foundation
import Utility

class UninstallCommand: MintCommand {

    var packageArgument: PositionalArgument<String>!

    init(mint: Mint, parser: ArgumentParser, installationPathArgument: OptionArgument<String>, pathArgument: OptionArgument<String>) {
        super.init(mint: mint, parser: parser, name: "uninstall", description: "Uninstall a package by name", installationPathArgument: installationPathArgument, pathArgument: pathArgument)
        packageArgument = subparser.add(positional: "name", kind: String.self, optional: false, usage: "The name of the package to uninstall")
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
      try super.execute(parsedArguments: parsedArguments)
      let package = parsedArguments.get(packageArgument)!
        try mint.uninstall(name: package, installPath: installationPath(parsedArguments: parsedArguments), mintPath: mintPath(parsedArguments: parsedArguments))
    }
}
