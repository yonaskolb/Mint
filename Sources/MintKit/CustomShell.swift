import SwiftShell

public protocol CustomShell {
    func run(bash: String, env: [String: String], directory: String?) -> RunOutput
    func runAndPrint(bash: String, env: [String: String], directory: String?) throws
    func runAndPrint(_ executable: String, _ args: Any..., env: [String: String], directory: String?) throws
}

public extension CustomShell {
    func run(bash: String) -> RunOutput {
        return run(bash: bash, env: [:], directory: nil)
    }

    func run(bash: String, directory: String) -> RunOutput {
        return run(bash: bash, env: [:], directory: directory)
    }

    func runAndPrint(bash: String) throws {
        try runAndPrint(bash: bash, env: [:], directory: nil)
    }

    func runAndPrint(bash: String, directory: String) throws {
        try runAndPrint(bash: bash, env: [:], directory: directory)
    }

    func runAndPrint(_ executable: String, _ args: Any..., env: [String: String]) throws {
        try runAndPrint(executable, args, env: env, directory: nil)
    }
}

internal struct SyncShell: CustomShell {
    let baseContext: Context
    init(context baseContext: Context = main) {
        self.baseContext = baseContext
    }

    func run(bash: String, env: [String: String], directory: String?) -> RunOutput {
        return context(env: env, directory: directory).run(bash: bash)
    }

    func runAndPrint(bash: String, env: [String: String], directory: String?) throws {
        try context(env: env, directory: directory).runAndPrint(bash: bash)
    }

    func runAndPrint(_ executable: String, _ args: Any..., env: [String: String], directory: String?) throws {
        try context(env: env, directory: directory).runAndPrint(executable, args)
    }

    private func context(env: [String: String], directory: String?) -> CustomContext {
        var context = CustomContext(main)
        for (name, value) in env {
            context.env[name] = value
        }
        if let directory = directory {
            context.currentdirectory = directory
        }
        return context
    }
}
