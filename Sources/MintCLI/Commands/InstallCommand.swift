import Foundation
import MintKit
import SwiftCLI
import Utility

class InstallCommand: PackageCommand {

    let executable = OptionalParameter()
    let noLink = Flag("-n", "--no-link", description: "Whether to prevent global linkage")
    let force = Flag("-f", "--force", description: "Force a reinstall even if the package is already installed", defaultValue: false)

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "install",
                   description: "Install a package. If the version is already installed no action will be taken",
                   parameterDescription: "By default all the executable products from the Package.swift are installed. The executable parameter can be used to link just a single executable globally.")
    }

    override func execute(package: PackageReference) throws {
        let link = !noLink.value
        try mint.install(package: package, executable: executable.value, force: force.value, link: link)
    }
}
