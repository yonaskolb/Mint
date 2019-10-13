import Foundation
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

    var packagePath: Path { return path + package.repoPath }
    var installPath: Path { return packagePath + "build" + package.version.string }
    var executablePath: Path { return installPath + (executable ?? package.name) }

    func getExecutables() throws -> [String] {
        return try installPath.children()
            .filter { $0.isFile && !$0.lastComponent.hasPrefix(".") && $0.extension == nil }
            .map { $0.lastComponent }
    }

    var commandVersion: String {
        return "\(executable ?? package.name) \(package.version)"
    }
}
