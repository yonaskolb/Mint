import Foundation
import MintKit
import PathKit
import SwiftCLI

class MintCommand: Command {

    let mint: Mint
    let name: String
    let shortDescription: String
    let longDescription: String

    init(mint: Mint, name: String, description: String, longDescription: String = "") {
        self.mint = mint
        self.name = name
        shortDescription = description
        self.longDescription = longDescription
    }

    func execute() throws {
    }
}
