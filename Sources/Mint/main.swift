import Foundation
import MintKit
import Rainbow
import SwiftShell

do {
    let mint = Mint()
    let mintInterface = MintInterace(mint: mint)
    try mintInterface.execute(arguments: Array(ProcessInfo.processInfo.arguments.dropFirst()))
} catch {
    if let error = error as? SwiftShell.CommandError {
        switch error {
        case let .inAccessibleExecutable(path): main.stderror.print("Couldn't run command \(path)")
        case let .returnedErrorCode(command, _): break
        }
    } else if error._domain == NSCocoaErrorDomain {
        print("🌱  \(error.localizedDescription)".red)
    } else {
        print("🌱  \(error)".red)
    }
    exit(1)
}
