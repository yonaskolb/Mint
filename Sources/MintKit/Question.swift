import Foundation

struct Question {

    let printer: (String) -> Void
    init(printer: @escaping (String) -> Void = { print($0) }) {
        self.printer = printer
    }

    func ask(_ question: String, answers: [String]) -> String {
        printer(question)

        func ask() -> String {
            guard let answer = readLine() else { return "" }
            let lowercasedAnswers = answers.map { $0.lowercased() }
            if !lowercasedAnswers.contains(answer.lowercased()) {
                print("You must respond with one of the following:\n\(answers.joined(separator: "\n"))")
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
