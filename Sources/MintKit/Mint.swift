import Foundation
import PathKit
import Rainbow
import SwiftCLI

public class Mint {

    public var path: Path
    public var linkPath: Path
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
        linkPath: Path,
        mintFilePath: Path = "Mintfile",
        standardOut: WritableStream = Term.stdout,
        standardError: WritableStream = Term.stderr
    ) {
        self.standardOut = standardOut
        self.standardError = standardError
        self.path = path.absolute()
        self.linkPath = linkPath.absolute()
        self.mintFilePath = mintFilePath
    }

    func output(_ string: String) {
        standardOut.print("🌱 \(string)")
    }

    func errorOutput(_ string: String) {
        standardError.print("🌱 \(string)")
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

    func getLinkedPackages() -> [String: String] {
        guard linkPath.exists,
            let packages = try? linkPath.children() else {
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
            output("No mint packages installed")
            return [:]
        }

        let linkedPackages: [String: String] = getLinkedPackages()

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
                if linkedPackages[packageName] == version {
                    package += " *"
                }
                versionsByPackage[packageName, default: []].append(version)
            }
            return package
        }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        output("Installed mint packages:\n\(packages.joined(separator: "\n"))")
        return versionsByPackage
    }

    /// return whether the version was resolved remotely
    @discardableResult
    func resolvePackage(_ package: PackageReference) throws -> Bool {

        // resolve version from MintFile
        if package.version.isEmpty,
            mintFilePath.exists,
            let mintfile = try? Mintfile(path: mintFilePath) {
            // set version to version from mintfile
            if let mintFilePackage = mintfile.package(for: package.repo), !mintFilePackage.version.isEmpty {
                package.version = mintFilePackage.version
                package.repo = mintFilePackage.repo
                if verbose {
                    output("Using \(package.repo) \(package.version) from Mintfile.")
                }
            }
        }

        // resolve repo from installed packages
        if !package.repo.contains("/") {
            // repo reference by name. Get the full git repo
            if let existingGit = try getPackageGit(name: package.repo) {
                package.repo = existingGit
            } else {
                throw MintError.packageNotFound(package.repo)
            }
        }

        // resolve latest version from git repo
        if package.version.isEmpty {
            // we don't have a specific version, let's get the latest tag
            output("Finding latest version of \(package.name)")
            do {
                let tagOutput = try Task.capture(bash: "git ls-remote --tags --refs \(package.gitPath)")

                let tagReferences = tagOutput.stdout
                if tagReferences.isEmpty {
                    package.version = "master"
                } else {
                    let tags = tagReferences.split(separator: "\n").map { String($0.split(separator: "\t").last!.split(separator: "/").last!) }
                    let versions = convertTagsToVersionMap(tags)
                    if let latestVersion = versions.keys.sorted().last, let tag = versions[latestVersion] {
                        package.version = tag
                    } else {
                        package.version = "master"
                    }
                }
            } catch {
                throw MintError.repoNotFound(package.gitPath)
            }
            return true
        } else {
            return false
        }
    }

    public func run(package: PackageReference, arguments: [String] = [], executable: String? = nil, noInstall: Bool = false) throws {

        let resolvedVersionRemotely = try resolvePackage(package)

        let installed = try install(package: package, beforeOtherCommand: true, force: false, link: false, noInstall: noInstall)

        var arguments = arguments
        let packagePath = try getPackagePath(for: package, with: &arguments, executable: executable)

        if verbose || installed || resolvedVersionRemotely {
            output("Running \(packagePath.executable ?? "") \(package.version)...")
        }

        if runAsNewProcess {
            var env = ProcessInfo.processInfo.environment
            env["MINT"] = "YES"
            env["RESOURCE_PATH"] = ""
            try Task.execvp(packagePath.executablePath.string, arguments: arguments, env: env)
        } else {
            let runTask = Task(executable: packagePath.executablePath.string, arguments: arguments)
            _ = runTask.runSync()
        }
    }

    public func getExecutablePath(package: PackageReference, executable: String?) throws -> Path {
        try resolvePackage(package)
        var arguments: [String] = []
        let packagePath = try getPackagePath(for: package, with: &arguments, executable: executable)
        return packagePath.executablePath
    }

    func getPackagePath(for package: PackageReference, with arguments: inout [String], executable: String?) throws -> PackagePath {
        var packagePath = PackagePath(path: packagesPath, package: package)

        if let executable = executable {
            packagePath.executable = executable
            if !packagePath.executablePath.exists {
                throw MintError.invalidExecutable(executable)
            }
            return packagePath
        }

        if !packagePath.installPath.exists {
            throw MintError.packageNotInstalled(package)
        }

        let executables = try packagePath.getExecutables()
        switch executables.count {
        case 0:
            throw MintError.missingExecutable(package)
        case 1:
            packagePath.executable = executables[0]
            if let firstArgument = arguments.first,
                executables[0].lowercased() == firstArgument.lowercased() {
                // the executable was part of the arguments, so let's drop it
                arguments = Array(arguments.dropFirst())
            }
        default:
            if let firstArgument = arguments.first?.lowercased(), let executable = executables.first(where: { $0.lowercased() == firstArgument }) {
                // the first argument matched an executable. Let's use it and drop the first argument
                packagePath.executable = executable
                arguments = Array(arguments.dropFirst())
                return packagePath
            }

            packagePath.executable = Input.readOption(options: executables, prompt: "There are multiple executables, which one would you like to run? In the future you can use the --executable argument")
        }
        return packagePath
    }

    @discardableResult
    /// returns if the package was installed
    public func install(package: PackageReference, executable: String? = nil, beforeOtherCommand: Bool = false, force: Bool = false, link: Bool = false, noInstall: Bool = false) throws -> Bool {

        try resolvePackage(package)

        let packagePath = PackagePath(path: packagesPath, package: package, executable: executable)

        let isInstalled = packagePath.installPath.exists

        if !isInstalled, noInstall {
            throw MintError.packageNotInstalled(package)
        }

        if !force, isInstalled {
            if !beforeOtherCommand || verbose {
                output("\(packagePath.commandVersion) already installed".green)
            }
            if link {
                if let executable = executable {
                    try linkPackage(package, executable: executable)
                } else {
                    let executables = try packagePath.getExecutables()
                    for executable in executables {
                        try linkPackage(package, executable: executable)
                    }
                }
            }
            return false
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + package.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()

        let cloneCommand = "git clone --depth 1 -b \(package.version) \(package.gitPath) \(package.repoPath)"
        try runPackageCommand(name: "Cloning \(package.namedVersion)",
                              command: cloneCommand,
                              directory: checkoutPath,
                              error: .cloneError(package))

        try runPackageCommand(name: "Resolving package",
                              command: "swift package resolve",
                              directory: packageCheckoutPath,
                              error: .packageResolveError(package))

        let spmPackage = try SwiftPackage(directory: packageCheckoutPath)

        let executables = spmPackage.products.filter { $0.isExecutable }.map { $0.name }
        guard !executables.isEmpty else {
            throw MintError.missingExecutable(package)
        }

        var buildCommand = "swift build -c release"
        #if os(macOS)
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            let target = "x86_64-apple-macosx\(osVersion.majorVersion).\(osVersion.minorVersion)"
            buildCommand += " -Xswiftc -target -Xswiftc \(target)"
        #endif

        try runPackageCommand(name: "Building package",
                              command: buildCommand,
                              directory: packageCheckoutPath,
                              stdOutOnError: true,
                              error: .packageBuildError(package))

        // clear the install directory
        try? packagePath.installPath.delete()
        try packagePath.installPath.mkpath()

        for executable in executables {
            let executablePath = packageCheckoutPath + ".build/release/\(executable)"
            if !executablePath.exists {
                throw MintError.invalidExecutable(executablePath.lastComponent)
            }
            let destinationPackagePath = PackagePath(path: packagesPath, package: package, executable: executable)
            if verbose {
                standardOut.print("Copying \(executablePath.string) to \(destinationPackagePath.executablePath)")
            }
            // copy using shell instead of FileManager via PathKit because it removes executable permissions on Linux
            try Task.run("cp", executablePath.string, destinationPackagePath.executablePath.string)
        }

        let resourcesFile = packageCheckoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            output("Copying resources for \(spmPackage.name): \(resources.joined(separator: ", ")) ...")
            for resource in resources {
                let resourcePath = packageCheckoutPath + resource
                if resourcePath.exists {
                    let filename = String(resource.split(separator: "/").last!)
                    let dest = packagePath.installPath + filename
                    try Task.run(bash: "cp -R \"\(resourcePath)\" \"\(dest)\"")
                } else {
                    output("resource \(resource) doesn't exist".yellow)
                }
            }
        }

        try addPackage(git: package.gitPath, path: packagePath.packagePath)

        output("Installed \(package.name) \(package.version)".green)
        try? packageCheckoutPath.delete()

        if link {
            if let executable = executable {
                try linkPackage(package, executable: executable)
            } else {
                for executable in executables {
                    try linkPackage(package, executable: executable)
                }
            }
        }

        return true
    }

    private func runPackageCommand(name: String, command: String, directory: Path, stdOutOnError: Bool = false, error mintError: MintError) throws {
        output(name)
        do {
            if verbose {
                try Task.run(bash: command, directory: directory.string)
            } else {
                _ = try Task.capture(bash: command, directory: directory.string)
            }
        } catch {
            if let error = error as? CaptureError, !verbose {
                if stdOutOnError, !error.captured.stdout.isEmpty {
                    standardOut <<< error.captured.stdout
                }
                if !error.captured.stderr.isEmpty {
                    standardError <<< error.captured.stderr
                }
            }
            var errorString = "Encountered error during \(command.quoted)"
            if !verbose {
                errorString += ". Use --verbose to see full output"
            }
            errorOutput(errorString)
            throw mintError
        }
    }

    func linkPackage(_ package: PackageReference, executable: String) throws {

        let packagePath = PackagePath(path: packagesPath, package: package, executable: executable)
        let installPath = linkPath + packagePath.executable!

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if let warning = installStatus.warning {
            let ok = Input.confirmation("🌱  \(warning)\nOverwrite it with Mint's symlink?".yellow)
            if !ok {
                return
            }
        }

        try? installPath.delete()
        try? installPath.parent().mkpath()

        do {
            try Task.run(bash: "ln -s \"\(packagePath.executablePath.string)\" \"\(installPath.string)\"")
        } catch {
            errorOutput("Could not link \(packagePath.commandVersion) to \(installPath.string)".red)
            return
        }
        var confirmation = "Linked \(packagePath.commandVersion) to \(linkPath.string)"
        if case let .mint(previousVersion) = installStatus.status, packagePath.package.version != previousVersion {
            confirmation += ", replacing version \(previousVersion)"
        }

        output(confirmation.green)
    }

    public func bootstrap(link: Bool = false) throws {

        let mintFile = try Mintfile(path: mintFilePath)

        guard !mintFile.packages.isEmpty else {
            standardOut <<< "🌱  Mintfile is empty"
            return
        }

        let packageCount = "\(mintFile.packages.count) \(mintFile.packages.count == 1 ? "package" : "packages")"

        if verbose {
            output("Found \(packageCount) in \(mintFilePath.string)")
        }
        var installCount = 0
        for package in mintFile.packages {
            let installed = try install(package: package, beforeOtherCommand: true, force: false, link: link)
            if installed {
                installCount += 1
            }
        }
        if installCount == 0 {
            output("\(packageCount) up to date".green)
        } else {
            output("Installed \(installCount)/\(packageCount)".green)
        }
    }

    public func uninstall(name: String) throws {

        // find packages
        var metadata = try readMetadata()
        let packages = metadata.packages.filter { $0.key.lowercased().contains(name.lowercased()) }

        // remove package
        switch packages.count {
        case 0:
            errorOutput("\(name.quoted) package was not found".red)
        case 1:
            let package = packages.first!.value
            let packagePath = packagesPath + package
            try? packagePath.delete()
            output("\(name) was uninstalled")
        default:
            // TODO: ask for user input about which to delete
            for package in packages {
                let packagePath = packagesPath + package.value
                try? packagePath.delete()
            }

            output("\(packages.count) packages that matched the name \(name.quoted) were uninstalled".green)
        }

        // remove metadata
        for (key, _) in packages {
            metadata.packages[key] = nil
        }
        try writeMetadata(metadata)

        // remove link
        let installPath = linkPath + name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if let warning = installStatus.warning {
            let ok = Input.confirmation("🌱  \(warning)\nDo you still wish to remove it?".yellow)
            if !ok {
                return
            }
        }
        try? installPath.delete()
    }
}
