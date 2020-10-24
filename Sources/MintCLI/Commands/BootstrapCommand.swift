
import Foundation
import MintKit
import PathKit
import SwiftCLI

class BootstrapCommand: MintfileCommand {

    @Key("-o", "--overwrite", description: "Automatically overwrite a symlinked executable that is not installed by mint without asking. Either (y/n)")
    var overwrite: Bool?

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "bootstrap",
                   description: "Installs all the packages in a Mintfile")
    }

    override func execute() throws {
        try super.execute()
        try mint.bootstrap(link: link, overwrite: overwrite)
    }
}
