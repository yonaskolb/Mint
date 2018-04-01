import Foundation
import Utility

class ListCommand: MintCommand {

  init(mint: Mint, parser: ArgumentParser, installationPathArgument: OptionArgument<String>, pathArgument: OptionArgument<String>) {

        let description = """
        List all the currently installed packages
        Globally installed packages are marked with *
        """
        
        super.init(mint: mint, parser: parser, name: "list", description: description, installationPathArgument: installationPathArgument, pathArgument: pathArgument)
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
      try super.execute(parsedArguments: parsedArguments)
      try mint.listPackages(mintPath: mintPath(parsedArguments: parsedArguments), installationPath: installationPath(parsedArguments: parsedArguments))
    }
}
