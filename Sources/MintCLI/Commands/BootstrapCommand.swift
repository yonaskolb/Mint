import MintKit
import SwiftCLI

final class BootstrapCommand: MintfileCommand {

    @Key("-o", "--overwrite", description: "Automatically overwrite a symlinked executable that is not installed by mint without asking. Either (y/n)")
    private var overwrite: Bool?

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
