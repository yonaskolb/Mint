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
        let versionArgument = parser.add(option: "--version", shortName: "-v", kind: Bool.self, usage: "Prints the current version of Mint")

        let commands: [String: MintCommand] = [
            "run": RunCommand(mint: mint, parser: parser),
            "install": InstallCommand(mint: mint, parser: parser),
            "update": UpdateCommand(mint: mint, parser: parser),
            "uninstall": UninstallCommand(mint: mint, parser: parser),
            "list": ListCommand(mint: mint, parser: parser),
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
