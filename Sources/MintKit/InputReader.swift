import Foundation
import SwiftCLI

struct InputReader {

    let standardOut: WritableStream
    init(standardOut: WritableStream = WriteStream.stdout) {
        self.standardOut = standardOut
    }

    func ask(_ question: String, answers: [String]) -> String {
        standardOut <<< question

        func ask() -> String {
            guard let answer = readLine() else { return "" }
            let lowercasedAnswers = answers.map { $0.lowercased() }
            if !lowercasedAnswers.contains(answer.lowercased()) {
                standardOut <<< "You must respond with one of the following:\n\(answers.joined(separator: "\n"))"
                return ask()
            }
            return answer
        }
        return ask()
    }

    func confirmation(_ question: String) -> Bool {
        return ask("\(question) (y/n)", answers: ["y", "n"]) == "y"
    }
}
