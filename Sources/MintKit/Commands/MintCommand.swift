import Foundation
import PathKit
import Utility

class MintCommand {

    let mint: Mint
    let subparser: ArgumentParser

    init(mint: Mint, parser: ArgumentParser, name: String, description: String) {
        self.mint = mint
        subparser = parser.add(subparser: name, overview: description)
    }

    func execute(parsedArguments: ArgumentParser.Result) throws {
        if let mintPath = ProcessInfo.processInfo.environment["MINT_PATH"], !mintPath.isEmpty {
            mint.path = Path(mintPath)
        }
        if let mintInstallPath = ProcessInfo.processInfo.environment["MINT_INSTALL_PATH"], !mintInstallPath.isEmpty {
            mint.installationPath = Path(mintInstallPath)
        }
    }
}
