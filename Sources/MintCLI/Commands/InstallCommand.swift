import Foundation
import MintKit
import SwiftCLI
import Utility

class InstallCommand: InstallOrUpdateCommand {

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "install",
                   description: "Install a package. If the version is already installed no action will be taken",
                   update: false
        )
    }
}

class UpdateCommand: InstallOrUpdateCommand {

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "update",
                   description: "Update a package even if it's already installed",
                   update: true
        )
    }
}

class InstallOrUpdateCommand: PackageCommand {

    var executable = OptionalParameter()
    var preventGlobal = Flag("-p", "--prevent-global", description: "Whether to prevent global installation")

    var update: Bool

    init(mint: Mint, name: String, description: String, update: Bool) {
        self.update = update
        super.init(mint: mint,
                   name: name,
                   description: description,
                   parameterDescription: "The executable to install defaults to the repo name")
    }

    override func execute(package: PackageReference) throws {
        let global = !preventGlobal.value
        try mint.install(package: package, executable: executable.value, update: update, global: global)
    }
}
