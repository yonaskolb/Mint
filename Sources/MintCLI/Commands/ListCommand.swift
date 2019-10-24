import Foundation
import MintKit
import SwiftCLI

class ListCommand: MintfileCommand {

    var dump = Flag("-d", "--dump", description: "Creates a Mintfile from all the installed packages", defaultValue:  false)
    var force = Flag("-f", "--force", description: "Overwrite the Mintfile if it already exists", defaultValue:  false)


    init(mint: Mint) {
        super.init(mint: mint,
                   name: "list",
                   description: "List all the currently installed packages. Globally linked packages are marked with *")
    }

    override func execute() throws {
        try super.execute()

        if (dump.value) {
            try mint.dump(force: force.value)
        } else {
            try mint.listPackages()
        }
    }
}
