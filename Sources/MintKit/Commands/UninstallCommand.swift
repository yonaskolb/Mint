import Foundation
import Utility

class UninstallCommand: MintCommand {

    var packageArgument: PositionalArgument<String>!

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "uninstall", description: "Uninstall a package by name")
        packageArgument = subparser.add(positional: "name", kind: String.self, optional: false, usage: "The name of the package to uninstall")
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
        let package = parsedArguments.get(packageArgument)!
        try mint.uninstall(name: package)
    }
}
