import Foundation
import PathKit

struct Mintfile {
    static let defaultPath = Path("Mintfile")

    static func `default`() -> Mintfile? {
        return self.init(path: Mintfile.defaultPath)
    }

    let packages: [MintPackage]

    public func version(for repo: String) -> String? {
        return packages.first { $0.repo.contains(repo) }?.version
    }

    init?(path: Path) {
        guard path.exists else {
            return nil
        }

        guard let contents: String = try? path.read() else {
            fatalError("Could not read mintfile at \(path).")
        }

        self.init(string: contents)
    }

    init(string: String) {
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
            .map { MintPackage(package: String($0)) }

        // Print warning for empty version
        packages
            .filter { $0.version.isEmpty }
            .forEach { print("🌱  MINTFILE: repository \($0.repo) has no defined version. Specify a version using <Repo>@<Commitish>.") }

        // Print warning for multiple definitions
        let duplicates = Dictionary(grouping: packages, by: { $0.repo })
            .filter { $0.value.count > 1 }
            .mapValues { $0.map { $0.version } }

        duplicates.forEach { repo, versions in
            print("🌱  MINTFILE: repository \"\(repo)\" defined multiple times with versions \(versions.joined(separator: ", ")).")
        }
    }
}
