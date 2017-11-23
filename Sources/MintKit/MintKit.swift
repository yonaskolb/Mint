import ShellOut
import PathKit
import Foundation
import Rainbow

public enum MintError: Error, CustomStringConvertible, Equatable {
    case packageNotFound(String)
    case repoNotFound(String)
    case invalidCommand(String)
    case invalidRepo(String)

    public var description: String {
        switch self {
        case .packageNotFound(let package): return "\(package.quoted) package not found "
        case .repoNotFound(let repo): return "Git repo not found at \(repo.quoted)"
        case .invalidCommand(let command): return "Couldn't find command \(command)"
        case .invalidRepo(let repo): return "Invalid repo \(repo.quoted)"
        }
    }

    public static func == (lhs: MintError, rhs: MintError) -> Bool {
        return lhs.description == rhs.description
    }
}

struct MintMetadata: Codable {
    var packages: [String: String]
}

public struct Mint {

    static let path: Path = {
        var result: String = "/usr/local/lib/mint"
        if _isDebugAssertConfiguration() {
            // Prevents testing and development (debug) from interfering with files belonging to the system install (release).
            result += ".debug"
        }
        return Path(result)
    }()
    static let metadataPath = path + "metadata.json"

    static func writeMetadata(_ metadata: MintMetadata) throws {
        let data = try JSONEncoder().encode(metadata)
        try Mint.metadataPath.write(data)
    }

    static func readMetadata() throws -> MintMetadata  {
        guard Mint.metadataPath.exists else {
            return MintMetadata(packages: [:])
        }
        let data: Data = try Mint.metadataPath.read()
        return try JSONDecoder().decode(MintMetadata.self, from: data)
    }

    static func addPackage(git: String, path: Path) throws  {
        var metadata = try readMetadata()
        metadata.packages[git] = path.lastComponent
        try Mint.writeMetadata(metadata)
    }

    public static func run(repo: String, version: String, command: String) throws {
        let commandComponents = command.components(separatedBy: " ")
        let name = commandComponents.first!
        let arguments = commandComponents.count > 1 ? Array(commandComponents.suffix(from: 1)) : []
        var git = repo
        if !git.contains("/") {
            // name find repo
            let metadata = try Mint.readMetadata()
            if let map = metadata.packages.first(where: { $0.key.lowercased().contains(git.lowercased())}) {
                git = map.key
            } else {
                throw MintError.packageNotFound(git)
            }
        }
        let package = Package(repo: git, version: version, name: name)
        try run(package, arguments: arguments)
    }

    public static func run(_ package: Package, arguments: [String]) throws {
        try install(package, force: false)
        print("🌱  Running \(package.commandVersion)...")

        let output = try shellOut(to: package.commandPath.string, arguments: arguments)
        print(output)
    }

    public static func install(repo: String, version: String, command: String, force: Bool) throws {
        let name = command.components(separatedBy: " ").first!
        let package = Package(repo: repo, version: version, name: name)
        try install(package, force: force)
    }

    public static func install(_ package: Package, force: Bool = false) throws {

        if !package.repo.contains("/") {
            throw MintError.invalidRepo(package.repo)
        }
        try package.path.mkpath()

        if !force && package.commandPath.exists && !package.version.isEmpty {
            print("🌱  \(package.commandVersion) already installed".green)
            return
        }

        if !package.checkoutPath.exists {
            print("🌱  Cloning \(package.git)...")
            do {
                try shellOut(to: "git clone \(package.git) \(package.checkoutPath.lastComponent)", at: package.path.string)
            } catch {
                throw MintError.repoNotFound(package.git)
            }
        }

        try shellOut(to: "git fetch --tags", at: package.checkoutPath.string)

        if package.version.isEmpty {
            do {
                // This will exit with a non-zero status code when there are no tags
                let tag = try shellOut(to: "git describe --abbrev=0 --tags", at:  package.checkoutPath.string)

                package.version = tag
                print("🌱  Using latest tag \(tag.quoted)")
            }  catch {
                package.version = "master"
                print("🌱  Using branch \(package.version.quoted)")
            }
        }

        if !force && package.commandPath.exists { // [_Exempt from Code Coverage_] False positive in Xcode 9.1.
            print("🌱  \(package.commandVersion) already installed".green)
            return
        }

        print("🌱  Checking out \(package.gitVersion)...")
        try shellOut(to: "git checkout \(package.version)", at: package.checkoutPath.string)

        try? package.installPath.delete()
        try package.installPath.mkpath()
        print("🌱  Building \(package.name). This may take a few minutes...")
//        try shellOut(to: "swift package clean", at: package.checkoutPath.string)
        try shellOut(to: "swift build -c release", at: package.checkoutPath.string)

        print("🌱  Installing \(package.name)...")
        let toolFile = package.checkoutPath + ".build/release/\(package.name)"
        if !toolFile.exists {
            throw MintError.invalidCommand(package.name)
        }
        try toolFile.copy(package.commandPath)

        let resourcesFile = package.checkoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            print("🌱  Copying resources for \(package.name): \(resources.joined(separator: ", ")) ...")
            for resource in resources {
                let resourcePath = package.checkoutPath + resource
                if resourcePath.exists {
                    try resourcePath.copy(package.installPath + resource)
                } else {
                    print("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        try Mint.addPackage(git: package.git, path: package.path)
        print("🌱  Installed \(package.commandVersion)".green)
    }

    static func gitURLFromString(_ string: String) -> String {
        if let url = URL(string: string), url.scheme != nil {
            return url.absoluteString
        } else {
            if string.contains("github.com") {
                return "https://\(string).git"
            } else {
                return "https://github.com/\(string).git"
            }
        }
    }
}
