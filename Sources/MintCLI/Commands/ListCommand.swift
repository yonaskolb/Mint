import Foundation
import MintKit

class ListCommand: MintCommand {

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "list",
                   description: "List all the currently installed packages. Globally installed packages are marked with *")
    }

    override func execute() throws {
        try super.execute()
        try mint.listPackages()
    }
}
