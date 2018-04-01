import Basic
import Foundation
import Utility

public class MintInterace {

    let mint: Mint

    public init(mint: Mint) {
      self.mint = mint
    }

    public func execute(arguments: [String]) throws {
        let parser = ArgumentParser(commandName: "mint", usage: "[subcommand]", overview: "Run and install Swift Package Manager executables")
        let versionArgument = parser.add(option: "--version", shortName: "-v", kind: Bool.self, usage: "Print the current version of Mint")
      
        let installationPathArgument = parser.add(option: "--installPath",
                                                 shortName: "-i",
                                                 kind: String.self,
                                                 usage: "The path to install binaries to, defaults to \(MintCommand.defaultInstallationPath)")
      
        let pathArgument = parser.add(option: "--path",
                                     shortName: "-p",
                                     kind: String.self,
                                     usage: "The path where built binaries are stored, defaults to \(MintCommand.defaultPath)")

        let commands: [String: MintCommand] = [
          "run": RunCommand(mint: mint, parser: parser, installationPathArgument: installationPathArgument,
                            pathArgument: pathArgument),
          "install": InstallCommand(mint: mint, parser: parser, installationPathArgument: installationPathArgument,
                                    pathArgument: pathArgument),
          "update": UpdateCommand(mint: mint, parser: parser,installationPathArgument: installationPathArgument,
                                  pathArgument: pathArgument),
          "uninstall": UninstallCommand(mint: mint, parser: parser,installationPathArgument: installationPathArgument,
                                        pathArgument: pathArgument),
          "list": ListCommand(mint: mint, parser: parser,installationPathArgument: installationPathArgument,
                              pathArgument: pathArgument),
        ]

        let parsedArguments = try parser.parse(arguments)

        if let printVersion = parsedArguments.get(versionArgument), printVersion == true {
            print(Mint.version)
            return
        }

        if let subParser = parsedArguments.subparser(parser),
            let command = commands[subParser] {
            try command.execute(parsedArguments: parsedArguments)
        } else {
            parser.printUsage(on: stdoutStream)
        }
    }
}
