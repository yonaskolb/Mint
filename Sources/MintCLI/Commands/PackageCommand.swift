import Foundation
import MintKit
import PathKit
import SwiftCLI

class PackageCommand: MintfileCommand {

    var package = Parameter()
    var silent = Flag("-s", "--silent", description: "Silences any output from Mint itself")
    var swiftCompilerFlags = VariadicKey<String>("--Xswiftc", description: "Flag passed through to all Swift compiler invocations")
    var cCompilerFlags = VariadicKey<String>("--Xcc", description: "Flag passed through to all C compiler invocations")
    var linkerFlags = VariadicKey<String>("--Xlinker", description: "Flags passed through to all linker invocations")

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
        if silent.value {
            mint.standardOut = WriteStream.null
        }

        try super.execute()

        let package = PackageReference(package: self.package.value)
        try execute(package: package)
    }

    func execute(package: PackageReference) throws {
    }
}
