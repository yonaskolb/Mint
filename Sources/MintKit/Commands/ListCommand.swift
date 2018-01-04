import Foundation
import Utility

class ListCommand: MintCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "list", description: "Lists all the currently installed packages")
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
        try mint.listPackages()
    }
}
