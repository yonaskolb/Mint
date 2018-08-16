import Foundation
import PathKit
import Rainbow
import SwiftCLI
import Utility

public class Mint {

    public var path: Path
    public var installationPath: Path
    public var mintFilePath: Path

    var packagesPath: Path {
        return path + "packages"
    }

    var metadataPath: Path {
        return path + "metadata.json"
    }

    public var standardOut: WritableStream
    public var standardError: WritableStream

    public var verbose = false
    public var runAsNewProcess = true

    public init(
        path: Path,
        installationPath: Path,
        mintFilePath: Path = "Mintfile",
        standardOut: WritableStream = WriteStream.stdout,
        standardError: WritableStream = WriteStream.stderr) {
        self.standardOut = standardOut
        self.standardError = standardError
        self.path = path.absolute()
        self.installationPath = installationPath.absolute()
        self.mintFilePath = mintFilePath
    }

    public func closeStreams() {
        standardOut.closeWrite()
        standardError.closeWrite()
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

    func getGlobalInstalledPackages() -> [String: String] {
        guard installationPath.exists,
            let packages = try? installationPath.children() else {
            return [:]
        }

        return packages.reduce(into: [:]) { result, package in
            guard let installStatus = try? InstallStatus(path: package, mintPackagesPath: path),
                case let .mint(version) = installStatus.status,
                let symlink = try? package.symlinkDestination() else {
                return
            }
            let packageName = symlink.lastComponent
            result[packageName] = version
        }
    }

    @discardableResult
    public func listPackages() throws -> [String: [String]] {
        guard packagesPath.exists else {
            standardOut <<< "No mint packages installed"
            return [:]
        }

        let globalInstalledPackages: [String: String] = getGlobalInstalledPackages()

        var versionsByPackage: [String: [String]] = [:]
        let packages: [String] = try packagesPath.children().filter { $0.isDirectory }.map { packagePath in
            let versions = try (packagePath + "build")
                .children()
                .filter { !$0.lastComponent.hasPrefix(".") }
                .sorted()
                .map { $0.lastComponent }
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

        standardOut <<< "Installed mint packages:\n\(packages.sorted().joined(separator: "\n"))"
        return versionsByPackage
    }

    @discardableResult
    public func run(repo: String, version: String, arguments: [String]? = nil) throws -> Package {
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
        try install(package, update: false, global: false)
        standardOut <<< "🌱  Running \(package.commandVersion)..."
        let packagePath = PackagePath(path: packagesPath, package: package)
        if !packagePath.commandPath.exists {
            throw MintError.invalidCommand(packagePath.commandPath.string)
        }
        if runAsNewProcess {
            var env = ProcessInfo.processInfo.environment
            env["MINT"] = "YES"
            env["RESOURCE_PATH"] = ""
            try Task.execvp(packagePath.commandPath.string, arguments: arguments, env: env)
        } else {
            let runTask = Task(executable: packagePath.commandPath.string, arguments: arguments)
            _ = runTask.runSync()
        }
    }

    @discardableResult
    public func install(repo: String, version: String, command: String?, update: Bool = false, global: Bool = false) throws -> Package {
        let guessedCommand = repo.components(separatedBy: "/").last!.components(separatedBy: ".").first!
        let name = command ?? guessedCommand
        let package = Package(repo: repo, version: version, name: name)
        try install(package, update: update, global: global)
        return package
    }

    public func install(_ package: Package, update: Bool = false, global: Bool = false) throws {

        if !package.repo.contains("/") {
            throw MintError.invalidRepo(package.repo)
        }

        let packagePath = PackagePath(path: packagesPath, package: package)

        if package.version.isEmpty {
            // we don't have a specific version, let's get the latest tag
            standardOut <<< "🌱  Finding latest version of \(package.name)"
            do {
                let tagOutput = try SwiftCLI.capture(bash: "git ls-remote --tags --refs \(packagePath.gitPath)")

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

                standardOut <<< "🌱  Resolved latest version of \(package.name) to \(package.version)"
            } catch {
                throw MintError.repoNotFound(packagePath.gitPath)
            }
        }

        if !update && packagePath.commandPath.exists {
            if global {
                try installGlobal(packagePath: packagePath)
            } else {
                standardOut <<< "🌱  \(package.commandVersion) already installed".green
            }
            return
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + packagePath.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()
        standardOut <<< "🌱  Cloning \(packagePath.gitPath) \(package.version)..."

        let cloneCommand = "git clone --depth 1 -b \(package.version) \(packagePath.gitPath) \(packagePath.repoPath)"

        do {
            if verbose {
                try SwiftCLI.run(bash: cloneCommand, directory: checkoutPath.string)
            } else {
                _ = try SwiftCLI.capture(bash: cloneCommand, directory: checkoutPath.string)
            }
        } catch {
            if let error = error as? CaptureError {
                if !error.captured.stderr.isEmpty, !verbose {
                    standardError <<< error.captured.stderr
                }
            }
            throw MintError.cloneError(url: packagePath.gitPath, version: package.version)
        }

        standardOut <<< "🌱  Building \(package.name) with SPM..."

        try buildPackage(name: package.name, path: packageCheckoutPath)

        standardOut <<< "🌱  Installing..."

        let toolFile = packageCheckoutPath + ".build/release/\(package.name)"
        if !toolFile.exists {
            throw MintError.invalidCommand(package.name)
        }

        // TODO: perhaps don't remove the whole directory once we install specific executables
        try? packagePath.installPath.delete()
        try packagePath.installPath.mkpath()

        // copy using shell instead of FileManager via PathKit because it remove executable permissions on Linux
        try SwiftCLI.run("cp", toolFile.string, packagePath.commandPath.string)

        let resourcesFile = packageCheckoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            standardOut <<< "🌱  Copying resources for \(package.name): \(resources.joined(separator: ", ")) ..."
            for resource in resources {
                let resourcePath = packageCheckoutPath + resource
                if resourcePath.exists {
                    try resourcePath.copy(packagePath.installPath + resource)
                } else {
                    standardOut <<< "resource \(resource) doesn't exist".yellow
                }
            }
        }

        try installManPages(packagePath: packagePath)

        try addPackage(git: packagePath.gitPath, path: packagePath.packagePath)

        standardOut <<< "🌱  Installed \(package.commandVersion)".green
        if global {
            try installGlobal(packagePath: packagePath)
        }

        try? packageCheckoutPath.delete()
    }

    private func installManPages(packagePath: PackagePath) throws {
        let package = packagePath.package
        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + packagePath.repoPath
        let manpages = Path("\(packageCheckoutPath)/docs/man/").glob("*")
        if !manpages.isEmpty {
            let allFiles = try manpages
                .flatMap { $0.isDirectory ? try $0.recursiveChildren() : [$0] }
                .map { $0.lastComponent }
                .joined(separator: ", ")

            standardOut <<< "🌱  Copying manpages for \(package.name): \(allFiles) ..."

            if !packagePath.manpagesPath.exists {
                try packagePath.manpagesPath.mkpath()
            }

            for manpage in manpages {
                let dest = packagePath.manpagesPath + manpage.lastComponent

                // Path#copy(_:) fails if the dest already exists.
                try SwiftCLI.run(bash: "cp -R \"\(manpage)\" \"\(dest)\"")
            }
        }
    }

    private func buildPackage(name: String, path: Path) throws {

        var command = "swift build -c release"
        #if os(macOS)
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            let target = "x86_64-apple-macosx\(osVersion.majorVersion).\(osVersion.minorVersion)"
            command += " -Xswiftc -static-stdlib -Xswiftc -target -Xswiftc \(target)"
        #endif

//        let buildSteps = [
//            "Fetching": "Fetching Dependencies",
//            "Cloning": "Resolving Dependencies",
//            "Compile": "Compiling",
//            "Linking": "Linking",
//            ]
//
//        var currentBuildStep: String?
//        var buildStepOutput = ""
//
//        let taskOut = LineStream { string in
//            if self.verbose {
//                self.standardOut <<< string
//            } else {
//                if let buildStep = buildSteps.first(where : { string.hasPrefix($0.key) })?.value {
//                    if buildStep != currentBuildStep {
//                        buildStepOutput = ""
//                        if currentBuildStep != nil {
//                            //self?.standardOut.print("👍")
//                        }
//                        currentBuildStep = buildStep
//                        self.standardOut <<< "🌱  \(buildStep)..."
//                    }
//                }
//            }
//            buildStepOutput += string + "\n"
//        }

        let taskOut = verbose ? standardOut : LineStream {_ in}
        let taskError = LineStream {_ in}
        let task = Task(executable: "/bin/bash", arguments: ["-c", command], directory: path.string, stdout: taskOut, stderr: taskError)
        task.runAsync()
        let status = task.finish()
//        taskOut.wait()
//        taskOut.closeWrite()
//        taskError.closeWrite()

        if status != 0 {
//            let out = verbose ? "" : "\(buildStepOutput.trimmingCharacters(in: .whitespacesAndNewlines))\n"
//            let out = ""
//            let error = taskError.readAll().trimmingCharacters(in: .whitespacesAndNewlines)
//            var string = "\(out)\(error)"
            var string = "Failed to build \(name)"
            if !verbose {
                string += ". Use --verbose to see full output"
            }
            throw MintError.buildError(string)
        }
    }

    private func checkForExistingExecutable(installStatus: InstallStatus) -> Bool {
        let warning: String? = {
            switch installStatus.status {
            case .file:
                return message(.executableIsNonMintFileWarning(installStatus.path.string))
            case .symlink(let symlink):
                return message(.executableIsNonMintSymlinkWarning(path: installStatus.path.string,
                                                                  symlink: symlink.string))
            default:
                return nil
            }
        }()

        if let warning = warning {
            let ok = Question().confirmation("🌱  \(warning)\nOvewrite it with Mint's symlink?".yellow)
            if !ok {
                return false
            }
        }

        return true
    }

    func installGlobal(packagePath: PackagePath) throws {

        let toolPath = packagePath.commandPath
        let installPath = installationPath + packagePath.package.name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if !checkForExistingExecutable(installStatus: installStatus) {
            return
        }

        try? installPath.delete()
        try? installPath.parent().mkpath()

        do {
            try SwiftCLI.run(bash: "ln -s \(toolPath.string) \(installPath.string)")
        } catch {
            standardError <<< "🌱  Could not install \(packagePath.package.commandVersion) in \(installPath.string)"
            return
        }
        var confirmation = "Linked \(packagePath.package.commandVersion) to \(installationPath.string)"
        if case let .mint(previousVersion) = installStatus.status {
            confirmation += ", replacing version \(previousVersion)"
        }

        standardOut <<< "🌱  \(confirmation).".green

        // symlink each manpages
        let manpages = try packagePath.manpagesPath.glob("*")
            .flatMap { try $0.recursiveChildren() }

        for packageManpagePath in manpages {
            if let latterPath = packageManpagePath.string.split(around: "share/man/").1 {
                let dest = Path("/usr/local/share/man/\(latterPath)")

                let installStatus = try InstallStatus(path: dest, mintPackagesPath: packagesPath)

                let warning: String? = {
                    switch installStatus.status {
                    case .file:
                        return message(.manpageIsNonMintFileWarning(installStatus.path.string))
                    case .symlink(let symlink):
                        return message(.manpageIsNonMintSymlinkWarning(path: installStatus.path.string,
                                                                       symlink: symlink.string))
                    default:
                        return nil
                    }
                }()

                if let warning = warning {
                    let ok = Question().confirmation("🌱  \(warning)\nOvewrite it with Mint's symlink?".yellow)
                    if !ok {
                        continue
                    }
                    try dest.delete()
                }

                try! SwiftCLI.run(bash: "ln -s \(packageManpagePath) \(dest)")
            }
        }
    }

    public func bootstrap() throws {

        let mintFile = try Mintfile(path: mintFilePath)

        guard !mintFile.packages.isEmpty else {
            standardOut <<< "🌱  Mintfile is empty"
            return
        }

        let packageCount = "\(mintFile.packages.count) \(mintFile.packages.count == 1 ? "package" : "packages")"

        standardOut <<< "🌱  Found \(packageCount) in \(mintFilePath.string)"
        for mintPackage in mintFile.packages {
            try install(repo: mintPackage.repo, version: mintPackage.version, command: nil, update: false, global: false)
        }
        standardOut <<< "🌱  Installed \(packageCount) from \(mintFilePath.string)".green
    }

    public func uninstall(name: String) throws {

        // find packages
        var metadata = try readMetadata()
        let packages = metadata.packages.filter { $0.key.lowercased().contains(name.lowercased()) }

        // remove package
        switch packages.count {
        case 0:
            standardError <<< "🌱  \(name.quoted) package was not found".red
        case 1:
            let package = packages.first!.value
            let packagePath = packagesPath + package
            try? packagePath.delete()
            standardOut <<< "🌱  \(name) was uninstalled"
        default:
            // TODO: ask for user input about which to delete
            for package in packages {
                let packagePath = packagesPath + package.value
                try? packagePath.delete()
            }

            standardOut <<< "🌱  \(packages.count) packages that matched the name \(name.quoted) were uninstalled".green
        }

        // remove metadata
        for (key, _) in packages {
            metadata.packages[key] = nil
        }
        try writeMetadata(metadata)

        // remove global install
        let installPath = installationPath + name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if !checkForExistingExecutable(installStatus: installStatus) {
            return
        }

        try? installPath.delete()
    }
}
