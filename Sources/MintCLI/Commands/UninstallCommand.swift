import MintKit
import SwiftCLI

final class UninstallCommand: MintCommand {

    @Param
    private var package: String

    init(mint: Mint) {
        super.init(mint: mint, name: "uninstall", description: "Uninstall a package by name")
    }

    override func execute() throws {
        try super.execute()
        try mint.uninstall(name: package)
    }
}
