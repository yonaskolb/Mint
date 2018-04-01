import Foundation
import PathKit
import Rainbow
import SwiftShell
import Utility

public class Mint {

    public static let version = "0.7.1"

//    let path: Path
//    let installationPath: Path
//
    func packagesPath(for path: Path) -> Path {
        return path + "packages"
    }

    func metadataPath(for path: Path) -> Path {
        return path + "metadata.json"
    }


//    public init(path: Path = "/usr/local/lib/mint", installationPath: Path = "/usr/local/bin") {
//        self.path = path.absolute()
//        self.installationPath = installationPath.absolute()
//    }
    var standardOutput: (String) -> Void
    var errorOutput: (String) -> Void

    public init(
//        path: Path = "/usr/local/lib/mint",
//        installationPath: Path = "/usr/local/bin",
        standardOutput: @escaping (String) -> Void = { string in
            print(string)
        },
        errorOutput: @escaping (String) -> Void = { string in
            print(string)
        }) {
        self.standardOutput = standardOutput
        self.errorOutput = errorOutput
//        self.path = path.absolute()
//        self.installationPath = installationPath.absolute()
    }

    struct Metadata: Codable {
        var packages: [String: String]
    }

    func writeMetadata(_ metadata: Metadata, to path: Path) throws {
        let data = try JSONEncoder().encode(metadata)
        try metadataPath(for: path).write(data)
    }

  func readMetadata(at path: Path) throws -> Metadata {
        guard metadataPath(for: path).exists else {
            return Metadata(packages: [:])
        }
        let data: Data = try metadataPath(for: path).read()
        return try JSONDecoder().decode(Metadata.self, from: data)
    }

  func addPackage(git: String, packagePath: Path, mintPath: Path) throws {
      var metadata = try readMetadata(at: mintPath)
        metadata.packages[git] = packagePath.lastComponent
      try writeMetadata(metadata, to: mintPath)
    }

  func getPackageGit(name: String, mintPath: Path) throws -> String? {
    let metadata = try readMetadata(at: mintPath)
        return metadata.packages.first(where: { $0.key.lowercased().contains(name.lowercased()) })?.key
    }

  func getGlobalInstalledPackages(installationPath: Path, mintPath: Path) -> [String: String] {
        guard installationPath.exists,
            let packages = try? installationPath.children() else {
                return [:]
        }

        return packages.reduce(into: [:]) { result, package in
            guard let installStatus = try? InstallStatus(path: package, mintPackagesPath: mintPath),
                case let .mint(version) = installStatus.status,
                let symlink = try? package.symlinkDestination() else {
                    return
            }
            let packageName = String(symlink.parent().parent().parent().lastComponent.split(separator: "_").last!)
            result[packageName] = version
        }
    }

    @discardableResult
  public func listPackages(mintPath: Path, installationPath: Path) throws -> [String: [String]] {
        guard packagesPath(for: mintPath).exists else {
            standardOutput("No mint packages installed")
            return [:]
        }

        let globalInstalledPackages: [String: String] = getGlobalInstalledPackages(installationPath: installationPath, mintPath: mintPath)

        var versionsByPackage: [String: [String]] = [:]
        let packages: [String] = try packagesPath(for: mintPath).children().filter { $0.isDirectory }.map { packagePath in
            let versions = try (packagePath + "build").children().sorted().map { $0.lastComponent }
            let packageName = String(packagePath.lastComponent.split(separator: "_").last!)
            var package = "  \(packageName)"
            for version in versions {
                package += "\n    - \(version)"
                if globalInstalledPackages[packageName] == version {
                    package += " *"
                }
                versionsByPackage[packageName, default: []].append(version)
            }
            return package
        }

        standardOutput("Installed mint packages:\n\(packages.sorted().joined(separator: "\n"))")
        return versionsByPackage
    }

    @discardableResult
  public func run(repo: String, version: String, verbose: Bool = false, mintPath: Path, installPath: Path, arguments: [String]? = nil) throws -> Package {
        let guessedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        let name = arguments?.first ?? guessedCommand
        var arguments = arguments ?? [guessedCommand]
        arguments = arguments.count > 1 ? Array(arguments.dropFirst()) : []
        var git = repo
        if !git.contains("/") {
            // find repo
            if let existingGit = try getPackageGit(name: git, mintPath: mintPath) {
                git = existingGit
            } else {
                throw MintError.packageNotFound(git)
            }
        }
        let package = Package(repo: git, version: version, name: name)
      
        try run(package, arguments: arguments, verbose: verbose, mintPath: mintPath, installationPath: installPath)
      
        return package
    }

  public func run(_ package: Package, arguments: [String], verbose: Bool, mintPath: Path, installationPath: Path) throws {
    try install(package, mintPath: mintPath, installationPath: installationPath, update: false, verbose: verbose, global: false)
        standardOutput("🌱  Running \(package.commandVersion)...")

        var context = CustomContext(main)
        context.env["MINT"] = "YES"
        context.env["RESOURCE_PATH"] = ""

        let packagePath = PackagePath(path: packagesPath(for: mintPath), package: package)
        try context.runAndPrint(packagePath.commandPath.string, arguments)
    }

    @discardableResult
  public func install(repo: String, version: String, mintPath: Path, installationPath: Path, command: String?, update: Bool = false, verbose: Bool = false, global: Bool = false) throws -> Package {
        let guessedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        let name = command ?? guessedCommand
        let package = Package(repo: repo, version: version, name: name)
      try install(package, mintPath: mintPath, installationPath: installationPath, update: update, verbose: verbose, global: global)
        return package
    }

  public func install(_ package: Package, mintPath: Path, installationPath: Path, update: Bool = false, verbose: Bool = false, global: Bool = false) throws {

        if !package.repo.contains("/") {
            throw MintError.invalidRepo(package.repo)
        }

        let packagePath = PackagePath(path: packagesPath(for: mintPath), package: package)

        if package.version.isEmpty {
            // we don't have a specific version, let's get the latest tag
            standardOutput("🌱  Finding latest version of \(package.name)")
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

            standardOutput("🌱  Resolved latest version of \(package.name) to \(package.version)")
        }

        if !update && packagePath.commandPath.exists {
            if global {
                try installGlobal(packagePath: packagePath, installationPath: installationPath)
            } else {
                standardOutput("🌱  \(package.commandVersion) already installed".green)
            }
            return
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + packagePath.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()
        standardOutput("🌱  Cloning \(packagePath.gitPath) \(package.version)...")
        do {
            try runCommand("git clone --depth 1 -b \(package.version) \(packagePath.gitPath) \(packagePath.repoPath)", at: checkoutPath, verbose: verbose)
        } catch {
            throw MintError.repoNotFound(packagePath.gitPath)
        }

        try? packagePath.installPath.delete()
        try packagePath.installPath.mkpath()

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let target = "x86_64-apple-macosx\(osVersion.majorVersion).\(osVersion.minorVersion)"

        standardOutput("🌱  Building \(package.name). This may take a few minutes...")
        try runCommand("swift build -c release -Xswiftc -target -Xswiftc \(target)", at: packageCheckoutPath, verbose: verbose)

        standardOutput("🌱  Installing \(package.name)...")
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
            standardOutput("🌱  Copying resources for \(package.name): \(resources.joined(separator: ", ")) ...")
            for resource in resources {
                let resourcePath = packageCheckoutPath + resource
                if resourcePath.exists {
                    try resourcePath.copy(packagePath.installPath + resource)
                } else {
                    standardOutput("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        try addPackage(git: packagePath.gitPath, packagePath: packagePath.packagePath, mintPath: mintPath)

        standardOutput("🌱  Installed \(package.commandVersion)".green)
        if global {
            try installGlobal(packagePath: packagePath, installationPath: installationPath)
        }

        try? packageCheckoutPath.delete()
    }

  func installGlobal(packagePath: PackagePath, installationPath: Path) throws {

        let toolPath = packagePath.commandPath
        let installPath = installationPath + packagePath.package.name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath(for: installationPath))

        if let warning = installStatus.warning {
            let ok = Question().confirmation("🌱  \(warning)\nOvewrite it with Mint's symlink?".yellow)
            if !ok {
                return
            }
        }

        try? installPath.absolute().delete()
        try? installPath.parent().mkpath()

        let output = main.run(bash: "ln -s \(toolPath.string) \(installPath.string)")
        guard output.succeeded else {
            errorOutput("🌱  Could not install \(packagePath.package.commandVersion) in \(installPath.string)")
            return
        }
        var confirmation = "Linked \(packagePath.package.commandVersion) to \(installationPath.string)"
        if case let .mint(previousVersion) = installStatus.status {
            confirmation += ", replacing version \(previousVersion)"
        }

        standardOutput("🌱  \(confirmation).".green)
    }

  public func uninstall(name: String, installPath: Path, mintPath: Path) throws {

        // find packages
        var metadata = try readMetadata(at: installPath)
        let packages = metadata.packages.filter { $0.key.lowercased().contains(name.lowercased()) }

        // remove package
        switch packages.count {
        case 0:
            errorOutput("🌱  \(name.quoted) package was not found".red)
        case 1:
            let package = packages.first!.value
            let packagePath = packagesPath(for: mintPath) + package
            try? packagePath.delete()
            standardOutput("🌱  \(name) was uninstalled")
        default:
            // TODO: ask for user input about which to delete
            for package in packages {
                let packagePath = packagesPath(for: mintPath) + package.value
                try? packagePath.delete()
            }

            standardOutput("🌱  \(packages.count) packages that matched the name \(name.quoted) were uninstalled".green)
        }

        // remove metadata
        for (key, _) in packages {
            metadata.packages[key] = nil
        }
      try writeMetadata(metadata, to: installPath)

        // remove global install
        let installPath = installPath + name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath(for: mintPath))

        if let warning = installStatus.warning {
            let ok = Question().confirmation("🌱  \(warning)\nDo you still wish to remove it?".yellow)
            if !ok {
                return
            }
        }
        try? installPath.delete()
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

struct InstallStatus {

    let status: Status
    let path: Path

    init(path: Path, mintPackagesPath: Path) throws {
        self.path = path
        if path.isSymlink {
            let actualPath = try path.symlinkDestination()
            if actualPath.absolute().string.contains(mintPackagesPath.absolute().string) {
                let version = actualPath.parent().lastComponent
                status = .mint(version: version)
            } else {
                status = .symlink(path: actualPath)
            }
        } else if path.exists {
            status = .file
        } else {
            status = .missing
        }
    }

    enum Status {

        case mint(version: String)
        case file
        case symlink(path: Path)
        case missing
    }

    var isSafe: Bool {
        switch status {
        case .file, .symlink: return true
        case .missing, .mint: return true
        }
    }

    var warning: String? {
        switch status {
        case .file: return "An executable that was not installed by mint already exists at \(path)."
        case let .symlink(symlink): return "An executable that was not installed by mint already exists at \(path) that is symlinked to \(symlink)."
        default: return nil
        }
    }
}
