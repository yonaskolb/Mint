import Foundation
import MintKit
import Rainbow
import SwiftCLI

let mint = Mint()
let mintInterface = MintCLI(mint: mint)
do {
    try mintInterface.execute(arguments: Array(ProcessInfo.processInfo.arguments.dropFirst()))
} catch {

    if let error = error as? CLI.Error {
        WriteStream.stderr <<< "Couldn't run command:\n\(error.message ?? "")"
    } else if let error = error as? MintError {
        WriteStream.stderr <<< error.description.red
    } else if error._domain == NSCocoaErrorDomain {
        WriteStream.stderr <<< "\(error.localizedDescription)".red
    } else {
        WriteStream.stderr <<< "\(error)"
    }
    exit(1)
}
