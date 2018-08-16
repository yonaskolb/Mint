import Foundation
import MintKit
import SwiftCLI

class RunCommand: PackageCommand {

    var arguments = OptionalCollectedParameter()

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "run",
                   description: "Install and then run a package",
                   parameterDescription: "The arguments can be used to specify a specific executable and it's arguments. By default the single executable in the Package.swift will be used, otherwise if there are multiple it will ask you to choose")
    }

    override func execute(package: PackageReference) throws {
        try mint.run(package: package, arguments: arguments.value)
    }
}
