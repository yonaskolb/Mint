import Foundation
import MintKit

class UpdateCommand: MintCommand {
    
    init(mint: Mint) {
        super.init(mint: mint,
                   name: "update",
                   description: "Updates all currently installed and linked packages that are outdated.")
    }
    
    override func execute() throws {
        try super.execute()
        try mint.update()
    }
}
