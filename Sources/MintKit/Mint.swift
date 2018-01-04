import Foundation
import PathKit
import Rainbow
import SwiftShell
import Utility

public struct Mint {

    public static let version = "0.6.1"

    let path: Path

    var packagesPath: Path {
        return path + "packages"
    }

    var installsPath: Path {
        return path + "installs"
    }

    var metadataPath: Path {
        return path + "metadata.json"
    }

    public init(path: Path) {
        self.path = path
    }

    struct Metadata: Codable {
        var packages: [String: String]
    }

    func writeMetadata(_ metadata: Metadata) throws {
        let data = try JSONEncoder().encode(metadata)
        try metadataPath.write(data)
    }

    func readMetadata() throws -> Metadata {
        guard metadataPath.exists else {
            return Metadata(packages: [:])
        }
        let data: Data = try metadataPath.read()
        return try JSONDecoder().decode(Metadata.self, from: data)
    }

    func addPackage(git: String, path: Path) throws {
        var metadata = try readMetadata()
        metadata.packages[git] = path.lastComponent
        try writeMetadata(metadata)
    }

    func getPackageGit(name: String) throws -> String? {
        let metadata = try readMetadata()
        return metadata.packages.first(where: { $0.key.lowercased().contains(name.lowercased()) })?.key
    }

    @discardableResult
    public func listPackages() throws -> [String: [String]] {
        guard packagesPath.exists else {
            print("No mint packages installed")
            return [:]
        }

        var versionsByPackage: [String: [String]] = [:]
        let packages: [String] = try packagesPath.children().filter { $0.isDirectory }.map { packagePath in
            let versions = try (packagePath + "build").children().sorted().map { $0.lastComponent }
            let packageName = String(packagePath.lastComponent.split(separator: "_").last!)
            var package = "  \(packageName)"
            for version in versions {
                package += "\n    - \(version)"
                versionsByPackage[packageName, default: []].append(version)
            }
            return package
        }

        print("Installed mint packages:\n\(packages.sorted().joined(separator: "\n"))")
        return versionsByPackage
    }

    @discardableResult
    public func run(repo: String, version: String, verbose: Bool = false, arguments: [String]? = nil) throws -> Package {
        let guessedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        let name = arguments?.first ?? guessedCommand
        var arguments = arguments ?? [guessedCommand]
        arguments = arguments.count > 1 ? Array(arguments.dropFirst()) : []
        var git = repo
        if !git.contains("/") {
            // find repo
            if let existingGit = try getPackageGit(name: git) {
                git = existingGit
            } else {
                throw MintError.packageNotFound(git)
            }
        }
        let package = Package(repo: git, version: version, name: name)
        try run(package, arguments: arguments, verbose: verbose)
        return package
    }

    public func run(_ package: Package, arguments: [String], verbose: Bool) throws {
        try install(package, force: false, verbose: verbose, global: false)
        print("🌱  Running \(package.commandVersion)...")

        var context = CustomContext(main)
        context.env["MINT"] = "YES"
        context.env["RESOURCE_PATH"] = ""

        let packagePath = PackagePath(path: packagesPath, package: package)
        try context.runAndPrint(packagePath.commandPath.string, arguments)
    }

    @discardableResult
    public func install(repo: String, version: String, command: String?, force: Bool = false, verbose: Bool = false, global: Bool = false) throws -> Package {
        let guessedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        let name = command ?? guessedCommand
        let package = Package(repo: repo, version: version, name: name)
        try install(package, force: force, verbose: verbose, global: global)
        return package
    }

    public func install(_ package: Package, force: Bool = false, verbose: Bool = false, global: Bool = false) throws {

        if !package.repo.contains("/") {
            throw MintError.invalidRepo(package.repo)
        }

        let packagePath = PackagePath(path: packagesPath, package: package)

        if package.version.isEmpty {
            // we don't have a specific version, let's get the latest tag
            print("🌱  Finding latest version of \(package.name)")
            let tagOutput = main.run(bash: "git ls-remote --tags --refs \(packagePath.gitPath)")

            if !tagOutput.succeeded {
                throw MintError.repoNotFound(packagePath.gitPath)
            }
            let tagReferences = tagOutput.stdout
            if tagReferences.isEmpty {
                package.version = "master"
            } else {
                let tags = tagReferences.split(separator: "\n").map { String($0.split(separator: "\t").last!.split(separator: "/").last!) }
                let versions = Git.convertTagsToVersionMap(tags)
                if let latestVersion = versions.keys.sorted().last, let tag = versions[latestVersion] {
                    package.version = tag
                } else {
                    package.version = "master"
                }
            }

            print("🌱  Using \(package.name) \(package.version.quoted)")
        }

        if !force && packagePath.commandPath.exists {
            print("🌱  \(package.commandVersion) already installed".green)
            if global {
                try installGlobal(packagePath: packagePath)
            }
            return
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + packagePath.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()
        print("🌱  Cloning \(packagePath.gitPath) \(package.version.quoted)...")
        do {
            try runCommand("git clone --depth 1 -b \(package.version) \(packagePath.gitPath) \(packagePath.repoPath)", at: checkoutPath, verbose: verbose)
        } catch {
            throw MintError.repoNotFound(packagePath.gitPath)
        }

        try? packagePath.installPath.delete()
        try packagePath.installPath.mkpath()
        print("🌱  Building \(package.name). This may take a few minutes...")
        try runCommand("swift build -c release", at: packageCheckoutPath, verbose: verbose)

        print("🌱  Installing \(package.name)...")
        let toolFile = packageCheckoutPath + ".build/release/\(package.name)"
        if !toolFile.exists {
            throw MintError.invalidCommand(package.name)
        }
        try toolFile.copy(packagePath.commandPath)

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
                    try resourcePath.copy(packagePath.installPath + resource)
                } else {
                    print("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        try addPackage(git: packagePath.gitPath, path: packagePath.packagePath)
        print("🌱  Installed \(package.commandVersion)".green)

        if global {
            try installGlobal(packagePath: packagePath)
        }

        try? packageCheckoutPath.delete()
    }

    func installGlobal(packagePath: PackagePath) throws {

        let installPath = installsPath + packagePath.package.name
        try installsPath.mkpath()

        // copy to global installs
        try? installPath.delete()
        let output = main.run(bash: "ln -s \(packagePath.commandPath.absolute().string) \(installPath.absolute().string)")
        guard output.succeeded else {
            print("🌱  Could not install \(packagePath.package.commandVersion) globally")
            return
        }

        let exportCommand = "export PATH=\"\(installsPath):$PATH\""

        // add $PATH to current shell
        // FIXME: this doesn't seem to work
        main.run(bash: exportCommand)

        // add $PATH to common files
        let exportSection = "# Register Mint install path\n\(exportCommand)"

        let files = [
            "~/.bash_profile",
            "~/.bashrc",
            "~/.zshenv",
        ]

        try files.forEach {
            let file = Path($0).absolute()
            if file.exists {
                let existingString: String = try file.read()
                if !existingString.contains(exportSection) {
                    let newString = "\(existingString)\n\n\(exportSection)"
                    try file.write(newString)
                    print("🌱  Added mint install $PATH to \(file.string)")
                }
            }
        }
    }

    public func uninstall(name: String) throws {

        // find packages
        var metadata = try readMetadata()
        let packages = metadata.packages.filter { $0.key.lowercased().contains(name.lowercased()) }

        // remove package
        switch packages.count {
        case 0:
            print("🌱  \(name.quoted) package was not found".red)
        case 1:
            let package = packages.first!.value
            let packagePath = packagesPath + package
            try? packagePath.delete()
            print("🌱  \(name) was uninstalled")
        default:
            // TODO: ask for user input about which to delete
            for package in packages {
                let packagePath = packagesPath + package.value
                try? packagePath.delete()
            }

            print("🌱  \(packages.count) packages that matched the name \(name.quoted) were uninstalled")
        }

        // remove metadata
        for (key, _) in packages {
            metadata.packages[key] = nil
        }
        try writeMetadata(metadata)

        // remove global install
        let executablePath = installsPath + name
        try? executablePath.delete()
    }

    private func runCommand(_ command: String, at: Path, verbose: Bool) throws {
        var context = CustomContext(main)
        context.currentdirectory = at.string
        if verbose {
            try context.runAndPrint(bash: command)
        } else {
            let output = context.run(bash: command)
            if let error = output.error {
                throw error
            }
        }
    }
}
