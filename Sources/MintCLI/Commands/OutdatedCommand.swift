
import Foundation
import MintKit
import PathKit
import SwiftCLI

class OutdatedCommand: MintfileCommand {

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "outdated",
                   description: "List all the currently installed and linked packages that are outdated.")
    }

    override func execute() throws {
        try super.execute()
        try mint.outdated()
    }
}
