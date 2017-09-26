import MintKit
import Rainbow
import Foundation
import ShellOut

do {
    try Mint.execute()
} catch {
    if let error = error as? ShellOutError {
        let message = "Error: \(error.message)".red
        print("🌱  \(message)\n\(error.output)")
    } else {
        print("🌱  Error: \(error)".red)
    }
    exit(1)
}
