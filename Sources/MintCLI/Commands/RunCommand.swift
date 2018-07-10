import Foundation
import MintKit
import SwiftCLI

class RunCommand: PackageCommand {

    var command = OptionalCollectedParameter()
    var silent = Flag("-s", "--silent", description: "Silences any output from Mint itself")

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "run",
                   description: "Install and then run a package")
    }

    override func execute() throws {
        if silent.value {
            mint.standardOut = LineStream {_ in}
        }
        try super.execute()
    }

    override func execute(repo: String, version: String) throws {
        var arguments = command.value

        // backwards compatability for arguments surrounded in quotes
        if arguments.count == 1,
            let firstArg = arguments.first,
            firstArg.contains(" ") {
            arguments = firstArg.split(separator: " ").map(String.init)
        }

        try mint.run(repo: repo, version: version, arguments: arguments)
    }
}
