import Foundation
import MintKit
import SwiftCLI

class UninstallCommand: MintCommand {

    var package = Parameter()

    init(mint: Mint) {
        super.init(mint: mint, name: "uninstall", description: "Uninstall a package by name")
    }

    override func execute() throws {
        try super.execute()
        let package = self.package.value
        try mint.uninstall(name: package)
    }
}
