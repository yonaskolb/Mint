import Foundation
import MintKit
import PathKit
import SwiftCLI

class PackageCommand: MintfileCommand {

    var package = Parameter()

    init(mint: Mint, name: String, description: String, parameterDescription: String? = nil) {
        var longDescription = """
        \(description)
        
        The package can be a shorthand for a github repo \"githubName/repo\", or a fully qualified .git path.
        An optional version can be specified by appending @version to the repo, otherwise the newest tag will be used (or master if no tags are found.)
        """
        if let parameterDescription = parameterDescription {
            longDescription += "\n\n\(parameterDescription)"
        }

        super.init(mint: mint, name: name, description: description, longDescription: longDescription)
    }

    override func execute() throws {
        try super.execute()

        var package = PackageReference(package: self.package.value)

        if package.version.isEmpty,
            mint.mintFilePath.exists,
            let mintfile = try? Mintfile(path: mint.mintFilePath) {
            // set version to version from mintfile
            if let mintFilePackage = mintfile.package(for: package.repo), !mintFilePackage.version.isEmpty {
                package = mintFilePackage
                mint.standardOut <<< "🌱  Using \"\(package.repo)\" \"\(package.version)\" from Mintfile."
            }
        }

        try execute(package: package)
    }

    func execute(package: PackageReference) throws {
    }
}
