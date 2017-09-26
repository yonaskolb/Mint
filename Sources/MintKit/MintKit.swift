import ShellOut
import PathKit
import Foundation
import Rainbow

public enum MintError: Error, CustomStringConvertible {
    case packageNotFound(String)
    case repoNotFound(String)

    public var description: String {
        switch self {
        case .packageNotFound(let package): return "Package not found \(package)"
        case .repoNotFound(let repo): return "Git repo not found \(repo)"
        }
    }
}

public struct Mint {

    static let path: Path = "/usr/local/Mint"

    public static func execute(_ arguments: [String] = CommandLine.arguments) throws {
        guard arguments.count > 1 else {
            print("valid commands are run and install")
            return
        }
        var arguments = arguments
        _ = arguments[0]
        let command = arguments[1]
        arguments = Array(arguments[2...])

        if command == "run" {
            try run(arguments)
        } else if command == "install" {
            try install(arguments)
        } else {
            print("valid commands are run and install")
        }
    }

    public static func run(_ arguments: [String]) throws {
        guard arguments.count >= 3 else {
            print("must provide git, version and name")
            return
        }
        let git = arguments[0]
        let version = arguments[1]
        let name = arguments[2]
        let arguments = Array(arguments[3...])
        let package = Package(name: name, git: git, version: version)
        try run(package, arguments: arguments)
    }

    public static func install(_ arguments: [String]) throws {
        guard arguments.count >= 3 else {
            print("must provide git, version and name")
            return
        }
        let git = arguments[0]
        let version = arguments[1]
        let name = arguments[2]
        let package = Package(name: name, git: git, version: version)
        try install(package)
    }

    public static func run(_ package: Package, arguments: [String]) throws {
        if !package.commandPath.exists {
            try install(package)
        }
        print("🌱  Running \(package.versionName)...".green)
        let output = try shellOut(to: package.commandPath.string, arguments: arguments)
        print(output)
    }

    public static func install(_ package: Package) throws {

        try package.path.mkpath()

        guard !package.commandPath.exists || package.version == "master"  else {
            print("🌱  \(package.versionName) already installed".green)
            return
        }

        if package.checkoutPath.exists {
            print("🌱  Checking out \(package.versionName)...".green)
            try shellOut(to: "git fetch", at: package.checkoutPath.string)
            try shellOut(to: "git checkout \(package.version)", at: package.checkoutPath.string)
        } else {
            print("🌱  Cloning \(package.git.absoluteString)...".green)
            do {
                try shellOut(to: "git clone \(package.git) \(package.checkoutPath.lastComponent)", at: package.path.string)
            } catch {
                throw MintError.repoNotFound(package.git.absoluteString)
            }
        }

        try package.versionPath.mkpath()
        print("🌱  Building \(package.name)...".green)
        try shellOut(to: "swift package clean", at: package.checkoutPath.string)
        try shellOut(to: "swift build -c release", at: package.checkoutPath.string)

        print("🌱  Installing \(package.name)...".green)
        let toolFile = package.checkoutPath + ".build/Release/\(package.name)"
        try toolFile.copy(package.commandPath)

        let resourcesFile = package.checkoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            print("🌱  Copying resources for \(package.name)...".green)
            for resource in resources {
                let resourcePath = package.checkoutPath + resource
                if resourcePath.exists {
                    print("copy \(resource)")
                    try resourcePath.copy(package.versionPath + resource)
                } else {
                    print("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        print("🌱  Installed \(package.versionName)".green)
    }

    static func gitURLFromString(_ string: String) -> URL {
        if let url = URL(string: string), url.scheme != nil {
            return url
        } else {
            if string.contains("github.com") {
                return URL(string: "https://\(string).git")!
            } else {
                return URL(string: "https://github.com/\(string).git")!
            }
        }
    }
}

public struct Package {
    public var name: String
    public var git: URL
    public var version: String

    public init(name: String, git: String, version: String?) {
        self.name = name
        self.git = Mint.gitURLFromString(git)
        if let url = URL(string: git), url.scheme != nil {
            self.git = url
        } else {
            if git.contains("github.com") {
                self.git = URL(string: "https://\(git).git")!
            } else {
                self.git = URL(string: "https://github.com/\(git).git")!
            }
        }
        self.version = version ?? "master"
    }

    public var versionName: String {
        return "\(name) \(version)"
    }

    var path: Path {
        return Mint.path + git.absoluteString
            .replacingOccurrences(of: git.scheme! + "://", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".git", with: "")
    }

    var checkoutPath: Path { return path + "checkout" }
    var versionPath: Path { return path + "build" + version }
    var commandPath: Path { return versionPath + name }
}
