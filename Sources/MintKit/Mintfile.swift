import Foundation
import PathKit

public struct Mintfile {

    let packages: [PackageReference]

    public func package(for repo: String) -> PackageReference? {
        return packages.first { $0.repo.lowercased().contains(repo.lowercased()) }
    }

    public init(path: Path) throws {
        guard path.exists else {
            throw MintError.mintfileNotFound(path.string)
        }
        let contents: String = try path.read()
        self.init(string: contents)
    }

    public init(string: String) {
        let lines = string
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let linesWithoutCommentLines = lines
            .filter { !$0.hasPrefix("#") }

        #if swift(>=4.1)
            let linesWithoutTrailingComments = linesWithoutCommentLines.compactMap { $0.split(separator: "#").first }
        #else
            let linesWithoutTrailingComments = linesWithoutCommentLines.flatMap { $0.split(separator: "#").first }
        #endif

        packages = linesWithoutTrailingComments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { PackageReference(package: String($0)) }

        // Print warning for multiple definitions
        let duplicates = Dictionary(grouping: packages, by: { $0.repo })
            .filter { $0.value.count > 1 }
            .mapValues { $0.map { $0.version } }

        duplicates.forEach { repo, versions in
            print("🌱  MINTFILE: repository \"\(repo)\" defined multiple times with versions \(versions.map{ $0.string }.joined(separator: ", ")).")
        }
    }
}
