import Foundation
import MintKit
import SwiftCLI

class WhichCommand: PackageCommand {

    @Param var executable: String?

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "which",
                   description: "Prints the full path to the installed executable")
    }

    override func execute(package: PackageReference) throws {
        let executablePath = try mint.getExecutablePath(package: package, executable: executable)
        mint.standardOut.print(executablePath.absolute().string)
    }
}
