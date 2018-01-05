import Foundation
import Utility

class InstallCommand: _InstallCommand {

    init(mint: Mint, parser: ArgumentParser) {
        super.init(mint: mint, parser: parser, name: "install", description: "Installs a package. If the version is already installed no action will be taken")
    }

    override func execute(parsedArguments: ArgumentParser.Result, repo: String, version: String, verbose: Bool, executable: String?, global: Bool) throws {
        try mint.install(repo: repo, version: version, command: executable, force: false, verbose: verbose, global: global)
    }
}
