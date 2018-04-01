import Foundation
import Utility
import PathKit

class MintCommand {

    let mint: Mint
    let subparser: ArgumentParser

    var path: Path? = nil
    var installationPath: Path? = nil
  
    let installationPathArgument: OptionArgument<String>
    let pathArgument: OptionArgument<String>
  
  func mintPath(parsedArguments: ArgumentParser.Result) -> Path {
    return Path(parsedArguments.get(pathArgument)!)
  }
  
    static let defaultInstallationPath: Path = "/usr/local/bin"
    static let defaultPath: Path = "/usr/local/lib/mint"
  
    init(mint: Mint, parser: ArgumentParser, name: String, description: String) {
        self.mint = mint
        self.subparser = parser.add(subparser: name, overview: description)

        self.installationPathArgument = parser.add(option: "--installPath",
                                                  shortName: "-i",
                                                  kind: String.self,
                                                  usage: "The path to install binaries to, defaults to \(MintCommand.defaultInstallationPath)")

        self.pathArgument = parser.add(option: "--path",
                                      shortName: "-p",
                                      kind: String.self,
                                      usage: "The path where built binaries are stored, defaults to \(MintCommand.defaultPath)")
      
    }

    func execute(parsedArguments: ArgumentParser.Result) throws {

      if let path = parsedArguments.get(pathArgument) {
        self.path = Path(path)
      } else {
        self.path = (path ?? MintCommand.defaultPath).absolute()
      }

      if let installationPath = parsedArguments.get(installationPathArgument) {
        self.installationPath = Path(installationPath)
      } else {
        self.installationPath = (installationPath ?? MintCommand.defaultInstallationPath).absolute()
      }
      
    }
}
