import Foundation
import MintKit
import SwiftCLI
import Utility

class InstallCommand: PackageCommand {

    let executable = OptionalParameter()
    let preventGlobal = Flag("-p", "--prevent-global", description: "Whether to prevent global installation")
    let force = Flag("-u", "--update", description: "Force a reinstall if the package is already installed", defaultValue: false)

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "install",
                   description: "Install a package. If the version is already installed no action will be taken",
                   parameterDescription: "By default all the executable products from the Package.swift are installed. The executable parameter can be used to link just a single executable globally.")
    }

    override func execute(package: PackageReference) throws {
        let global = !preventGlobal.value
        try mint.install(package: package, executable: executable.value, update: force.value, global: global)
    }
}
