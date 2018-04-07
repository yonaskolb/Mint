import Foundation
import Utility

class ListCommand: MintCommand {

    init(mint: Mint, parser: ArgumentParser) {

        let description = "List all the currently installed packages. Globally installed packages are marked with *"

        super.init(mint: mint, parser: parser, name: "list", description: description)
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
        try super.execute(parsedArguments: parsedArguments)
        try mint.listPackages()
    }
}
