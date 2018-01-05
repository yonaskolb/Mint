import Foundation
import Utility

class MintCommand {

    let mint: Mint
    let subparser: ArgumentParser

    init(mint: Mint, parser: ArgumentParser, name: String, description: String) {
        self.mint = mint
        subparser = parser.add(subparser: name, overview: description)
    }

    func execute(parsedArguments: ArgumentParser.Result) throws {
    }
}
