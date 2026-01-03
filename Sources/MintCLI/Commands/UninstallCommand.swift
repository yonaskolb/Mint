import Foundation
import MintKit
import SwiftCLI

class UninstallCommand: MintCommand {

    @Param var package: String
    @Key("-V", "--version", description: "Specify the version to uninstall") var version: String?

    init(mint: Mint) {
        super.init(mint: mint, name: "uninstall", description: "Uninstall a package or a specific version by name")
    }

    override func execute() throws {
        try super.execute()
        try mint.uninstall(name: package, version: version)
    }
}
