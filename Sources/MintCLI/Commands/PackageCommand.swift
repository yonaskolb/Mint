import Foundation
import MintKit
import PathKit
import SwiftCLI

class PackageCommand: MintCommand {

    var verbose = Flag("-v", "--verbose", description: "Show verbose output", defaultValue: false)
    var package = Parameter()

    init(mint: Mint, name: String, description: String, parameterDescription: String? = nil) {
        var longDescription = """
        \(description)
        
        The package can be a shorthand for a github repo \"githubName/repo\", or a fully qualified .git path.
        An optional version can be specified by appending @version to the repo, otherwise the newest tag will be used (or master if no tags are found)
        """
        if let parameterDescription = parameterDescription {
            longDescription += "\n\n\(parameterDescription)"
        }

        super.init(mint: mint, name: name, description: description, longDescription: longDescription)
    }

    override func execute() throws {
        try super.execute()
        mint.verbose = verbose.value

        var mintPackage = MintPackage(package: package.value)

        if mintPackage.version.isEmpty, let mintfile = Mintfile.default() {
            // set version to version from mintfile
            if let package = mintfile.package(for: mintPackage.repo), !package.version.isEmpty {
                mintPackage = package
                mint.standardOut <<< "🌱  Using \"\(package.repo)\" \"\(package.version)\" from Mintfile."
            }
        }

        try execute(repo: mintPackage.repo, version: mintPackage.version)
    }

    func execute(repo: String, version: String) throws {
    }
}
