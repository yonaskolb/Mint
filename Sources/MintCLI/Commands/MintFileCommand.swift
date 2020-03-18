
import Foundation
import MintKit
import PathKit
import SwiftCLI

class MintfileCommand: MintCommand {

    @Flag("-v", "--verbose", description: "Show verbose output")
    var verbose: Bool

    @Flag("-l", "--link", description: "Install the packages of the Mintfile globally")
    var link: Bool

    @Key("-m", "--mintfile", description: "Custom path to a Mintfile. Defaults to Mintfile")
    var mintFile: String?

    override func execute() throws {
        try super.execute()

        mint.verbose = verbose
        if let mintFile = mintFile {
            mint.mintFilePath = Path(mintFile)
        }
    }
}
