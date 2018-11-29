import Foundation
import PathKit
import Rainbow
import SwiftCLI
import Utility

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
    var inputReader: InputReader

    public init(
        path: Path,
        linkPath: Path,
        mintFilePath: Path = "Mintfile",
        standardOut: WritableStream = WriteStream.stdout,
        standardError: WritableStream = WriteStream.stderr) {
        self.standardOut = standardOut
        self.standardError = standardError
        self.path = path.absolute()
        self.linkPath = linkPath.absolute()
        self.mintFilePath = mintFilePath
        inputReader = InputReader(standardOut: standardOut)
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
            standardOut <<< "No mint packages installed"
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

        standardOut <<< "Installed mint packages:\n\(packages.joined(separator: "\n"))"
        return versionsByPackage
    }

    func resolvePackage(_ package: PackageReference) throws {

        // resolve version from MintFile
        if package.version.isEmpty,
            mintFilePath.exists,
            let mintfile = try? Mintfile(path: mintFilePath) {
            // set version to version from mintfile
            if let mintFilePackage = mintfile.package(for: package.repo), !mintFilePackage.version.isEmpty {
                package.version = mintFilePackage.version
                package.repo = mintFilePackage.repo
                standardOut <<< "🌱  Using \(package.repo) \(package.version) from Mintfile."
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

        // resove latest version from git repo
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
    }

    public func run(package: PackageReference, arguments: [String] = [], swiftCompilerFlags: [String] = [], cCompilerFlags: [String] = [], linkerFlags: [String] = []) throws {

        try resolvePackage(package)

        // install the package if not installed already
        try install(package: package, force: false, link: false, swiftCompilerFlags: swiftCompilerFlags, cCompilerFlags: cCompilerFlags, linkerFlags: linkerFlags)

        var packagePath = PackagePath(path: packagesPath, package: package)

        if let packageExecutable = arguments.first {
            packagePath.executable = packageExecutable
            if !packagePath.executablePath.exists {
                throw MintError.invalidExecutable(packageExecutable)
            }
        } else {
            let executables = try packagePath.getExecutables()
            switch executables.count {
            case 0:
                throw MintError.missingExecutable
            case 1:
                packagePath.executable = executables[0]
            default:
                packagePath.executable = inputReader.ask("There are multiple executables, which one would you like to run?", answers: executables)
            }
        }
        standardOut <<< "🌱  Running \(packagePath.executable ?? "") \(package.version)..."

        let arguments = arguments.isEmpty ? [] : Array(arguments.dropFirst())

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

    public func install(package: PackageReference, executable: String? = nil, force: Bool = false, link: Bool = false, swiftCompilerFlags: [String] = [], cCompilerFlags: [String] = [], linkerFlags: [String] = []) throws {

        try resolvePackage(package)

        let packagePath = PackagePath(path: packagesPath, package: package, executable: executable)

        let alreadyInstalled = packagePath.installPath.exists
        if !force && alreadyInstalled {
            standardOut <<< "🌱  \(packagePath.commandVersion) already installed".green
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

        guard let spmPackage = try? SwiftPackage(directory: packageCheckoutPath) else {
            throw MintError.packageFileNotFound
        }

        let executables = spmPackage.products.filter { $0.isExecutable }.map { $0.name }
        guard !executables.isEmpty else {
            throw MintError.missingExecutable
        }

        standardOut <<< "🌱  Building \(spmPackage.name) Package with SPM..."

        try buildPackage(name: package.name, path: packageCheckoutPath, swiftCompilerFlags: swiftCompilerFlags, cCompilerFlags: cCompilerFlags, linkerFlags: linkerFlags)

        standardOut <<< "🌱  Installing \(spmPackage.name)..."

        // clear the install directory
        try? packagePath.installPath.delete()
        try packagePath.installPath.mkpath()

        for executable in executables {
            let executablePath = packageCheckoutPath + ".build/release/\(executable)"
            if !executablePath.exists {
                throw MintError.invalidExecutable(executablePath.lastComponent)
            }
            let destinationPackagePath = PackagePath(path: packagesPath, package: package, executable: executable)
            // copy using shell instead of FileManager via PathKit because it removes executable permissions on Linux
            try SwiftCLI.run("cp", executablePath.string, destinationPackagePath.executablePath.string)
        }

        let resourcesFile = packageCheckoutPath + "Package.resources"
        if resourcesFile.exists {
            let resourcesString: String = try resourcesFile.read()
            let resources = resourcesString.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            standardOut <<< "🌱  Copying resources for \(spmPackage.name): \(resources.joined(separator: ", ")) ..."
            for resource in resources {
                let resourcePath = packageCheckoutPath + resource
                if resourcePath.exists {
                    let filename = String(resource.split(separator: "/").last!)
                    let dest = packagePath.installPath + filename
                    try SwiftCLI.run(bash: "cp -R \"\(resourcePath)\" \"\(dest)\"")
                } else {
                    standardOut <<< "resource \(resource) doesn't exist".yellow
                }
            }
        }

        try addPackage(git: packagePath.gitPath, path: packagePath.packagePath)

        standardOut <<< "🌱  Installed \(spmPackage.name) \(package.version)".green
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
    }

    private func buildPackage(name: String, path: Path, swiftCompilerFlags: [String], cCompilerFlags: [String], linkerFlags: [String]) throws {
        
        var command = "swift build -c release"
        #if os(macOS)
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            let target = "x86_64-apple-macosx\(osVersion.majorVersion).\(osVersion.minorVersion)"
            command += " -Xswiftc -static-stdlib -Xswiftc -target -Xswiftc \(target)"
        #endif
        for swiftCompilerFlag in swiftCompilerFlags {
            command += " -Xswiftc \(swiftCompilerFlag)"
        }
        for cCompilerFlag in cCompilerFlags {
            command += " -Xcc \(cCompilerFlag)"
        }
        for linkerFlag in linkerFlags {
            command += " -Xlinker \(linkerFlag)"
        }

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

        let taskOut = verbose ? standardOut : WriteStream.null
        let taskError = WriteStream.null
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

    func linkPackage(_ package: PackageReference, executable: String) throws {

        let packagePath = PackagePath(path: packagesPath, package: package, executable: executable)
        let installPath = linkPath + packagePath.executable!

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if let warning = installStatus.warning {
            let ok = inputReader.confirmation("🌱  \(warning)\nOverwrite it with Mint's symlink?".yellow)
            if !ok {
                return
            }
        }

        try? installPath.delete()
        try? installPath.parent().mkpath()

        do {
            try SwiftCLI.run(bash: "ln -s \(packagePath.executablePath.string) \(installPath.string)")
        } catch {
            standardError <<< "🌱  Could not link \(packagePath.commandVersion) to \(installPath.string)"
            return
        }
        var confirmation = "Linked \(packagePath.commandVersion) to \(linkPath.string)"
        if case let .mint(previousVersion) = installStatus.status {
            confirmation += ", replacing version \(previousVersion)"
        }

        standardOut <<< "🌱  \(confirmation).".green
    }

    public func bootstrap() throws {

        let mintFile = try Mintfile(path: mintFilePath)

        guard !mintFile.packages.isEmpty else {
            standardOut <<< "🌱  Mintfile is empty"
            return
        }

        let packageCount = "\(mintFile.packages.count) \(mintFile.packages.count == 1 ? "package" : "packages")"

        standardOut <<< "🌱  Found \(packageCount) in \(mintFilePath.string)"
        for package in mintFile.packages {
            try install(package: package, force: false, link: false)
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

        // remove link
        let installPath = linkPath + name

        let installStatus = try InstallStatus(path: installPath, mintPackagesPath: packagesPath)

        if let warning = installStatus.warning {
            let ok = inputReader.confirmation("🌱  \(warning)\nDo you still wish to remove it?".yellow)
            if !ok {
                return
            }
        }
        try? installPath.delete()
    }
}
