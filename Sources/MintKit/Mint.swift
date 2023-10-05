import Foundation
import PathKit
import Rainbow
import SwiftCLI
import Version

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

    func getGitRepos(name: String) throws -> [String] {
        let metadata = try readMetadata()

        let gitRepos = metadata.packages
            .filter { $0.key.lowercased().contains(name.lowercased()) }
            .map { $0.key }

        return gitRepos
    }

    func getLinkedExecutables() -> [Path] {
        guard linkPath.exists,
            let packages = try? linkPath.children() else {
            return []
        }

        return packages.reduce(into: []) { result, package in
            guard let installStatus = try? InstallStatus(path: package, mintPackagesPath: path),
                case .mint = installStatus.status,
                let symlink = try? package.symlinkDestination() else {
                return
            }
            result.append(symlink)
        }
    }

    @discardableResult
    public func listPackages() throws -> [String: [String]] {
        guard packagesPath.exists else {
            output("No mint packages installed")
            return [:]
        }

        let metadata = try readMetadata()
        let cache = try Cache(path: packagesPath, metadata: metadata, linkedExecutables: getLinkedExecutables())
        output("Installed mint packages:\n\(cache.list)")

        return cache.packages.reduce(into: [:]) { result, cache in
            result[cache.gitRepo] = cache.versionDirs.map { $0.version }
        }
    }

    /// return whether the version was resolved remotely
    @discardableResult
    func resolvePackage(_ package: PackageReference) throws -> Bool {

        // resolve repo and version from MintFile
        if mintFilePath.exists,
            let mintfile = try? Mintfile(path: mintFilePath),
            let mintFilePackage = mintfile.package(for: package.repo) {
            // set repo to repo from mintfile
            package.repo = mintFilePackage.repo

            if package.version.isEmpty, !mintFilePackage.version.isEmpty {
                // set version to version from mintfile
                package.version = mintFilePackage.version
                if verbose {
                    output("Using \(package.repo) \(package.version) from Mintfile.")
                }
            }
        }

        // resolve repo from installed packages
        if !package.repo.contains("/") {
            // repo reference by name. Get the full git repo
            let gitRepos = try getGitRepos(name: package.repo)

            let gitRepo: String
            switch gitRepos.count {
            case 0:
                throw MintError.packageNotFound(package.repo)

            case 1:
                gitRepo = gitRepos[0]

            default:
                gitRepo = Input.readOption(options: gitRepos, prompt: "There are multiple git repositories matching '\(package.repo)', which one would you like to use?")
            }
            package.repo = gitRepo
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
                let metadata = try readMetadata()
                let linkedExecutables = getLinkedExecutables()
                let cache = try Cache(path: packagesPath, metadata: metadata, linkedExecutables: linkedExecutables)
                
                guard let installedVersions = cache.packages
                        .first(where: { $0.gitRepo == package.repo })?
                        .versionDirs.map({ $0.version }),
                    let fallbackVersion = installedVersions.last else {
                    throw MintError.repoNotFound(package.gitPath)
                }
                package.version = installedVersions
                    .compactMap(Version.init)
                    .max()?.description ?? fallbackVersion
                errorOutput( "Failed to find latest version online. Falling back to local version \(package.version)")
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
    public func install(package: PackageReference, executable: String? = nil, beforeOtherCommand: Bool = false, force: Bool = false, link: Bool = false, noInstall: Bool = false, overwrite: Bool? = nil) throws -> Bool {

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
                    try linkPackage(package, executable: executable, overwrite: overwrite)
                } else {
                    let executables = try packagePath.getExecutables()
                    for executable in executables {
                        try linkPackage(package, executable: executable, overwrite: overwrite)
                    }
                }
                try linkResources(package)
                checkLinkPath()
            }
            return false
        }

        let checkoutPath = Path.temporary + "mint"
        let packageCheckoutPath = checkoutPath + package.repoPath

        try checkoutPath.mkpath()

        try? packageCheckoutPath.delete()

        let cloneCommand: String

        if package.versionCouldBeSHA {
            // version is maybe a SHA, so we can't do a shallow clone
            cloneCommand = "git clone \(package.gitPath) \(package.repoPath) && cd \(package.repoPath) && git checkout \(package.version)"
        } else {
            cloneCommand = "git clone --depth 1 -b \(package.version) \(package.gitPath) \(package.repoPath)"
        }
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

        for executable in executables {
            var buildCommand = "swift build -c release --product \(executable)"

            #if os(macOS)
                let processInfo = ProcessInfo.processInfo
                if let machineHardwareName = processInfo.machineHardwareName {
                    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
                    let target = "\(machineHardwareName)-apple-macosx\(osVersion.majorVersion).\(osVersion.minorVersion)"
                    buildCommand += " -Xswiftc -target -Xswiftc \(target)"
                }
            #endif

            try runPackageCommand(name: "Building product \(executable)",
                                  command: buildCommand,
                                  directory: packageCheckoutPath,
                                  stdOutOnError: true,
                                  error: .packageBuildError(package))
        }

        let packageBuildPath = packageCheckoutPath + ".build/release"
        let packageInstallPath = packagePath.installPath

        // clear the install directory
        try? packageInstallPath.delete()
        try packageInstallPath.mkpath()

        try copyBuildArtifacts(from: packageBuildPath, to: packagePath.installPath, executables: executables)

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
                try linkPackage(package, executable: executable, overwrite: overwrite)
            } else {
                for executable in executables {
                    try linkPackage(package, executable: executable, overwrite: overwrite)
                }
            }
            try linkResources(package)
            checkLinkPath()
        }

        return true
    }

    private func copyBuildArtifacts(from buildPath: Path, to installPath: Path, executables: [String]) throws {
        var pathsToCopy: [Path] = []
        for executable in executables {
            let executablePath = buildPath + executable
            if !executablePath.exists {
                throw MintError.invalidExecutable(executablePath.lastComponent)
            }
            pathsToCopy.append(executablePath)
        }

        try pathsToCopy.append(contentsOf: getResources(from: buildPath))

        for path in pathsToCopy {
            let destinationPath = installPath + path.lastComponent
            if verbose {
                standardOut.print("Copying \(path) to \(destinationPath)")
            }
            // copy using shell instead of FileManager via PathKit because it removes executable permissions on Linux
            try Task.run(bash: "cp -R \(path.string) \(destinationPath.string)")
        }
    }

    private func getResources(from path: Path) throws -> [Path] {
        let extensions: Set = ["bundle", "resources", "dylib"]

        return try path.children().filter {
            guard let ext = $0.extension, extensions.contains(ext) else {
                return false
            }

            return true
        }
    }
    
    private func checkLinkPath() {
        if let path = ProcessInfo.processInfo.environment["PATH"], !path.contains(linkPath.string) {
            output("\(linkPath) must be added to your $PATH if you wish to run this package outside of mint".yellow)
        }
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

    func linkPackage(_ package: PackageReference, executable: String, overwrite: Bool?) throws {

        let packagePath = PackagePath(path: packagesPath, package: package, executable: executable)
        let installPath = linkPath + packagePath.executable!

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if let warning = installStatus.warning {
            if let overwrite = overwrite, !overwrite {
                return
            }
            if overwrite == nil {
                let ok = Input.confirmation("🌱  \(warning)\nOverwrite it with Mint's symlink?".yellow)
                if !ok {
                    return
                }
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

    func linkResources(_ package: PackageReference) throws {
        let packagePath = PackagePath(path: packagesPath, package: package)
        let resources = try getResources(from: packagePath.installPath)

        for resource in resources {
            let installPath = linkPath + resource.lastComponent

            do {
                try Task.run(bash: "ln -s -f \"\(packagePath.installPath + resource.lastComponent)\" \"\(installPath.string)\"")
            } catch {
                errorOutput("Could not link \(resource.lastComponent) to \(installPath.string)".red)
                return
            }
        }
    }

    public func bootstrap(link: Bool = false, overwrite: Bool? = nil) throws {

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
            let installed = try install(package: package, beforeOtherCommand: true, force: false, link: link, overwrite: overwrite)
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
        let linkedExecutables = getLinkedExecutables()
        let cache = try Cache(path: packagesPath, metadata: metadata, linkedExecutables: linkedExecutables)
        let packages = cache.packages.filter { $0.gitRepo.lowercased().contains(name.lowercased()) }

        // remove package
        let package: Cache.PackageInfo
        switch packages.count {
        case 0:
            errorOutput("\(name.quoted) package was not found".red)
            return
        case 1:
            package = packages.first!
        default:
            let option = Input.readOption(options: packages.map { $0.gitRepo }, prompt: "There are multiple packages matching '\(name)', which one would you like to uninstall?")
            package = packages.first { $0.gitRepo == option }!
        }

        let resources = try package.versionDirs
            .map { try getResources(from: $0.path) }
            .flatMap { $0 }

        try package.path.delete()
        output("\(package.name) was uninstalled")

        // remove metadata
        metadata.packages[package.gitRepo] = nil
        try writeMetadata(metadata)

        // remove link
        for executable in Set(package.versionDirs.flatMap { $0.executables }) where executable.linked {
            let installPath = linkPath + executable.name
            try installPath.delete()
        }

        // remove resource artifact link
        for resource in resources {
            let installPath = linkPath + resource.lastComponent
            try installPath.delete()
        }
    }
}
