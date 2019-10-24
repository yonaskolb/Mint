import Foundation
import MintKit
import PathKit
import SwiftCLI

class MintfileCommand: MintCommand {

    var verbose = Flag("-v", "--verbose", description: "Show verbose output", defaultValue: false)
    var link = Flag("-l", "--link", description: "Install the packages of the Mintfile globally", defaultValue: false)
    var mintFile = Key<String>("-m", "--mintfile", description: "Custom path to a Mintfile. Defaults to Mintfile")

    override func execute() throws {
        try super.execute()

        mint.verbose = verbose.value
        if let mintFile = mintFile.value {
            mint.mintFilePath = Path(mintFile)
        }
    }
}
