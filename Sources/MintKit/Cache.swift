import Foundation
import PathKit

/// A struct used as a representation of the cache
struct Cache: Hashable {
    struct PackageInfo: Hashable {
        var name: String {
            return PackageReference(repo: gitRepo).name
        }

        let gitRepo: String
        let path: Path
        let versionDirs: [VersionDir]
    }

    struct VersionDir: Hashable {
        let path: Path
        var version: String { path.lastComponent }
        let executables: [ExecutableInfo]
    }

    struct ExecutableInfo: Hashable {
        let path: Path
        let linked: Bool
        var name: String { path.lastComponent }
    }

    let packages: [PackageInfo]

    init(path: Path, metadata: Mint.Metadata, linkedExecutables: [Path]) throws {
        packages = try path.children()
            .filter { $0.isDirectory && !$0.lastComponent.hasPrefix(".") }
            .map { originPath in
                let buildPath = originPath + "build"
                let versionDirs: [VersionDir] = try buildPath.children()
                    .filter { $0.isDirectory && !$0.lastComponent.hasPrefix(".") }
                    .map { versionPath in
                        let executables = try versionPath.children()
                            .filter { $0.isFile && $0.extension == nil && !$0.lastComponent.hasPrefix(".") }
                            .map { executablePath in
                                ExecutableInfo(path: executablePath, linked: linkedExecutables.contains(executablePath))
                            }
                            .sorted { $0.name < $1.name }
                        return VersionDir(path: versionPath, executables: executables)
                    }
                    .sorted { $0.version < $1.version }

                let gitRepos = metadata.packages.filter { $0.value == originPath.lastComponent }.map { $0.key }
                let gitRepo: String
                switch gitRepos.count {
                case 0:
                    throw MintError.inconsistentCache("Inconsistent metadata: git repository not found for package at path '\(originPath)'")
                case 1:
                    gitRepo = gitRepos[0]
                default:
                    throw MintError.inconsistentCache("Inconsistent metadata: multiple git repositories found for package at path '\(originPath)'")
                }

                return PackageInfo(gitRepo: gitRepo, path: originPath, versionDirs: versionDirs)
            }
            .sorted { $0.name < $1.name }
    }

    var list: String {
        var description: [String] = []
        for package in packages {
            var packageDescription = ["  \(package.name)"]
            if packages.filter({ $0.name == package.name }).count > 1 {
                packageDescription.append("(\(package.gitRepo))")
            }
            description.append(packageDescription.joined(separator: " "))

            for versionDir in package.versionDirs {
                var versionDescription: [String] = ["    - \(versionDir.version)"]
                if versionDir.executables.count == 1 {
                    let executable = versionDir.executables[0]
                    if executable.name.lowercased() != package.name.lowercased() {
                        versionDescription.append("(\(executable.name))")
                    }
                    if executable.linked {
                        versionDescription.append("*")
                    }
                } else if versionDir.executables.allSatisfy({ $0.linked }) {
                    let executablesDescription = versionDir.executables.map { $0.name }.joined(separator: ", ")
                    versionDescription.append("(\(executablesDescription)) *")
                } else {
                    let executablesDescription = versionDir.executables
                        .map { $0.linked ? "\($0.name) *" : $0.name }
                        .joined(separator: ", ")
                    versionDescription.append("(\(executablesDescription))")
                }
                description.append(versionDescription.joined(separator: " "))
            }
        }
        return description.joined(separator: "\n")
    }
}
