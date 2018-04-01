import Foundation
import Utility
import PathKit

class MintCommand {

    let mint: Mint
    let subparser: ArgumentParser

    let installationPathArgument: OptionArgument<String>
    let pathArgument: OptionArgument<String>
  
    func mintPath(parsedArguments: ArgumentParser.Result) -> Path {
      return Path(parsedArguments.get(pathArgument)!)
    }
  
  func installationPath(parsedArguments: ArgumentParser.Result) -> Path {
    return Path(parsedArguments.get(installationPathArgument)!)
  }
  
    static let defaultInstallationPath: Path = "/usr/local/bin"
    static let defaultPath: Path = "/usr/local/lib/mint"
  
    init(mint: Mint, parser: ArgumentParser, name: String, description: String, installationPathArgument: OptionArgument<String>, pathArgument: OptionArgument<String>) {
        self.mint = mint
        self.subparser = parser.add(subparser: name, overview: description)
        self.installationPathArgument = installationPathArgument
        self.pathArgument = pathArgument
    }

    func execute(parsedArguments: ArgumentParser.Result) throws {}
}
