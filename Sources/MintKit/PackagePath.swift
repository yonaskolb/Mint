import PathKit

/// Contains all the paths for packages
struct PackagePath {

    var path: Path
    var package: PackageReference
    var executable: String?

    init(path: Path, package: PackageReference, executable: String? = nil) {
        self.path = path
        self.package = package
        self.executable = executable
    }

    var packagePath: Path { path + package.repoPath }
    var installPath: Path { packagePath + "build" + package.version }
    var executablePath: Path { installPath + (executable ?? package.name) }

    func getExecutables() throws -> [String] {
        try installPath.children()
            .filter { $0.isFile && !$0.lastComponent.hasPrefix(".") && $0.extension == nil }
            .map { $0.lastComponent }
    }

    var commandVersion: String {
        "\(executable ?? package.name) \(package.version)"
    }
}
