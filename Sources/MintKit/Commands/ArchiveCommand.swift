//
//  ArchiveCommand.swift
//  MintKit
//
//  Created by Toshihiro Suzuki on 2018/02/17.
//

import Foundation
import Utility

class ArchiveCommand: PackageCommand {

//    var executablesArgument: PositionalArgument<[String]>!
    private let arguments: [String]

    init(mint: Mint, parser: ArgumentParser, arguments: [String]) {
        self.arguments = arguments

        super.init(
            mint: mint,
            parser: parser,
            name: "archive",
            description: "Archive your package to support binary install. Upload generated .zip file to your github release page."
        )

//        executablesArgument = subparser.add(positional: "executable(s)", kind: [String].self, optional: false, strategy: .remaining, usage: "The executable name(s) to archive. First one will be the prefix of the generated zip file.")
    }

    override func execute(parsedArguments: ArgumentParser.Result) throws {
//        let arguments = parsedArguments.get

        try mint.archive(executableNames: arguments.dropFirst().map { $0 })
    }
}
