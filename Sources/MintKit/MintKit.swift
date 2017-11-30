import ShellOut
import PathKit
import Foundation
import Rainbow

public enum MintError: Error, CustomStringConvertible {
    case packageNotFound(String)
    case repoNotFound(String)
    case invalidCommand(String)
    case invalidRepo(String)

    public var description: String {
        switch self {
        case let .packageNotFound(package): return "\(package.quoted) package not found "
        case let .repoNotFound(repo): return "Git repo not found at \(repo.quoted)"
        case let .invalidCommand(command): return "Couldn't find command \(command)"
        case let .invalidRepo(repo): return "Invalid repo \(repo.quoted)"
        }
    }
}

struct MintMetadata: Codable {
    var packages: [String: String]
}

public struct Mint {

    static let mintPath: Path = "/usr/local/lib/mint"
    static let packagesPath: Path = mintPath + "packages"
    static let metadataPath = mintPath + "metadata.json"

    static func writeMetadata(_ metadata: MintMetadata) throws {
        let data = try JSONEncoder().encode(metadata)
        try Mint.metadataPath.write(data)
    }

    static func readMetadata() throws -> MintMetadata {
        guard Mint.metadataPath.exists else {
            return MintMetadata(packages: [:])
        }
        let data: Data = try Mint.metadataPath.read()
        return try JSONDecoder().decode(MintMetadata.self, from: data)
    }

    static func addPackage(git: String, path: Path) throws {
        var metadata = try readMetadata()
        metadata.packages[git] = path.lastComponent
        try Mint.writeMetadata(metadata)
    }

    public static func listPackages() throws {
        guard packagesPath.exists else {
            print("No mint packages installed")
            return
        }

        let packages: [String] = try packagesPath.children().filter { $0.isDirectory }.map { packagePath in
            let versions = try (packagePath + "build").children().sorted()
            let packageName = packagePath.lastComponent.split(separator: "_").last!
            var package = "  \(packageName)"
            for version in versions {
                package += "\n    - \(version.lastComponent)"
            }
            return package
        }

        print("Installed mint packages:\n\(packages.sorted().joined(separator: "\n"))")
    }

    public static func run(repo: String, version: String, command: String) throws {
        let commandComponents = command.components(separatedBy: " ")
        let name = commandComponents.first!
        let arguments = commandComponents.count > 1 ? Array(commandComponents.suffix(from: 1)) : []
        var git = repo
        if !git.contains("/") {
            // name find repo
            let metadata = try Mint.readMetadata()
            if let map = metadata.packages.first(where: { $0.key.lowercased().contains(git.lowercased()) }) {
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

        if package.version.isEmpty {
            // we don't have a specific version, let's get the latest tag
            let tags = try shellOut(to: "git ls-remote --tags \(package.git)")
            if tags.isEmpty {
                package.version = "master"
                print("🌱  Using \(package.name) \(package.version.quoted)")
            } else {
                let latestTag = String(tags.split(separator: "\n").last!.split(separator: "\t").last!.split(separator: "/").last!)
                package.version = latestTag
                print("🌱  Using latest tag \(latestTag.quoted)")
            }
        }

        if !force && package.commandPath.exists {
            print("🌱  \(package.commandVersion) already installed".green)
            return
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + package.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()
        print("🌱  Cloning \(package.git) \(package.version.quoted)...")
        do {
            try shellOut(to: "git clone --depth 1 -b \(package.version) \(package.git) \(package.repoPath)", at: checkoutPath.string)
        } catch {
            throw MintError.repoNotFound(package.git)
        }

        try? package.installPath.delete()
        try package.installPath.mkpath()
        print("🌱  Building \(package.name). This may take a few minutes...")
        //        try shellOut(to: "swift package clean", at: package.checkoutPath.string)
        try shellOut(to: "swift build -c release", at: packageCheckoutPath.string)

        print("🌱  Installing \(package.name)...")
        let toolFile = packageCheckoutPath + ".build/release/\(package.name)"
        if !toolFile.exists {
            throw MintError.invalidCommand(package.name)
        }
        try toolFile.copy(package.commandPath)

        let resourcesFile = packageCheckoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            print("🌱  Copying resources for \(package.name): \(resources.joined(separator: ", ")) ...")
            for resource in resources {
                let resourcePath = packageCheckoutPath + resource
                if resourcePath.exists {
                    try resourcePath.copy(package.installPath + resource)
                } else {
                    print("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        try Mint.addPackage(git: package.git, path: package.path)
        print("🌱  Installed \(package.commandVersion)".green)

        try? packageCheckoutPath.delete()
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
