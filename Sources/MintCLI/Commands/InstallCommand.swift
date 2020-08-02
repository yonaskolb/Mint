import Foundation
import MintKit
import SwiftCLI

class InstallCommand: PackageCommand {

    @Param var executable: String?

    @Flag("-n", "--no-link", description: "Whether to prevent global linkage")
    var noLink: Bool

    @Flag("-f", "--force", description: "Force a reinstall even if the package is already installed")
    var force: Bool

    @Flag("-o", "--overwrite", description: "Force overwriting a package even if it is already installed globally")
    var overwrite: Bool

    init(mint: Mint) {
        super.init(mint: mint,
                   name: "install",
                   description: "Install a package. If the version is already installed no action will be taken",
                   parameterDescription: "By default all the executable products from the Package.swift are installed. The executable parameter can be used to link just a single executable globally.")
    }

    override func execute(package: PackageReference) throws {
        let link = !noLink
        try mint.install(package: package, executable: executable, force: force, link: link, overwrite: overwrite)
    }
}
