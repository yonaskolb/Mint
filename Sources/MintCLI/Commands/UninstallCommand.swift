import MintKit
import SwiftCLI

class UninstallCommand: MintCommand {

    @Param var package: String

    init(mint: Mint) {
        super.init(mint: mint, name: "uninstall", description: "Uninstall a package by name")
    }

    override func execute() throws {
        try super.execute()
        try mint.uninstall(name: package)
    }
}
