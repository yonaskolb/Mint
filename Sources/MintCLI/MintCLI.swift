import Foundation
import MintKit
import PathKit
import SwiftCLI

public class MintCLI {

    private let version = "0.17.5"

    private let mint: Mint
    private let cli: CLI

    public init() {

        var mintPath: Path = "~/.mint"
        var linkPath: Path = "~/.mint/bin"

        if let path = ProcessInfo.processInfo.environment["MINT_PATH"], !path.isEmpty {
            mintPath = Path(path)
        }
        if let path = ProcessInfo.processInfo.environment["MINT_LINK_PATH"], !path.isEmpty {
            linkPath = Path(path)
        }

        mint = Mint(path: mintPath, linkPath: linkPath)

        cli = CLI(name: "mint", version: version, description: "Run and install Swift Package Manager executables", commands: [
            RunCommand(mint: mint),
            InstallCommand(mint: mint),
            UninstallCommand(mint: mint),
            ListCommand(mint: mint),
            BootstrapCommand(mint: mint),
            WhichCommand(mint: mint),
        ])
    }

    public func execute(arguments: [String]? = nil) {
        let status: Int32
        if let arguments = arguments {
            status = cli.go(with: arguments)
        } else {
            status = cli.go()
        }
        exit(status)
    }
}

extension MintError: ProcessError {

    public var message: String? {
        "🌱  \(description.red)"
    }

    public var exitStatus: Int32 { 1 }
}
