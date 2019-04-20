import Foundation
import MintKit

class OutdatedCommand: MintCommand {
    
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
