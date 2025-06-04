import Foundation
import SwiftCLI

extension Input {

    static func readOption(options: [String], prompt: String) -> String {
        let optionsString = options.enumerated()
            .map { "  \($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = "\(prompt)\n\(optionsString)\n"

        let validation: Validation<String> = .custom("Couldn't parse option") { input in
            if let index = Int(input), index > 0, index <= options.count {
                return true
            }
            return options.contains(input)
        }

        let value = Input.readObject(prompt: prompt, secure: false, validation: [validation])
        if options.contains(value) {
            return value
        } else if let index = Int(value) {
            return options[index - 1]
        } else {
            return value
        }
    }

    static func confirmation(_ question: String) -> Bool {
        readBool(prompt: "\(question) (y/n)")
    }
}
