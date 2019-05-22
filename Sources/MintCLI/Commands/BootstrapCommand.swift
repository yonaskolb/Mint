
import Foundation
import MintKit
import PathKit
import SwiftCLI

class BootstrapCommand: MintfileCommand {

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "bootstrap",
                   description: "Installs all the packages in a Mintfile")
    }

    override func execute() throws {
        try super.execute()
        try mint.bootstrap(link: link.value)
    }
}
