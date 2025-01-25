@testable import MintKit
import XCTest

class PackageTests: XCTestCase {

    func testPackagePaths() {

        let testMint = Mint(path: "/testPath/mint", linkPath: "/testPath/mint-installs")
        let package = PackageReference(repo: "yonaskolb/mint", version: "1.2.0")
        let packagePath = PackagePath(path: testMint.packagesPath, package: package)

        XCTAssertEqual(testMint.path, "/testPath/mint")
        XCTAssertEqual(testMint.packagesPath, "/testPath/mint/packages")
        XCTAssertEqual(testMint.linkPath, "/testPath/mint-installs")
        XCTAssertEqual(package.gitPath, "https://github.com/yonaskolb/mint.git")
        XCTAssertEqual(package.repoPath, "github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.packagePath, "/testPath/mint/packages/github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.installPath, "/testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0")
        XCTAssertEqual(packagePath.executablePath, "/testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0/mint")
    }

    func testPackageGitPaths() {

        let urls: [String: String] = [
            "yonaskolb/mint": "https://github.com/yonaskolb/mint.git",
            "github.com/yonaskolb/mint": "https://github.com/yonaskolb/mint.git",
            "https://github.com/yonaskolb/mint": "https://github.com/yonaskolb/mint",
            "https://github.com/yonaskolb/mint.git": "https://github.com/yonaskolb/mint.git",
            "mycustomdomain.com/package": "https://mycustomdomain.com/package",
            "mycustomdomain.com/package.git": "https://mycustomdomain.com/package.git",
            "https://mycustomdomain.com/package": "https://mycustomdomain.com/package",
            "https://mycustomdomain.com/package.git": "https://mycustomdomain.com/package.git",
            "git@github.com:yonaskolb/Mint.git": "git@github.com:yonaskolb/Mint.git",
            "mac-cain13/R.swift": "https://github.com/mac-cain13/R.swift.git",
        ]

        for (url, expected) in urls {
            XCTAssertEqual(PackageReference(repo: url).gitPath, expected)
        }
    }

    func testPackageNames() {

        let urls: [String: String] = [
            "yonaskolb/mint": "mint",
            "github.com/yonaskolb/mint": "mint",
            "https://github.com/yonaskolb/mint": "mint",
            "https://github.com/yonaskolb/mint.git": "mint",
            "mycustomdomain.com/package": "package",
            "mycustomdomain.com/package.git": "package",
            "https://mycustomdomain.com/package": "package",
            "https://mycustomdomain.com/package.git": "package",
            "git@github.com:yonaskolb/Mint.git": "Mint",
            "mac-cain13/R.swift": "R.swift",
            "github.com/mac-cain13/R.swift": "R.swift",
            "https://github.com/mac-cain13/R.swift.git": "R.swift",
            "git@github.com:mac-cain13/R.swift.git": "R.swift",
        ]

        for (url, expected) in urls {
            XCTAssertEqual(PackageReference(repo: url).name, expected)
        }
    }

    func testPackageReferenceInfo() {

        XCTAssertEqual(PackageReference(package: "yonaskolb/mint"), PackageReference(repo: "yonaskolb/mint"))
        XCTAssertEqual(PackageReference(package: "yonaskolb/mint@0.0.1"), PackageReference(repo: "yonaskolb/mint", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "github.com/yonaskolb/mint"), PackageReference(repo: "github.com/yonaskolb/mint"))
        XCTAssertEqual(PackageReference(package: "github.com/yonaskolb/mint@0.0.1"), PackageReference(repo: "github.com/yonaskolb/mint", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "https://github.com/yonaskolb/mint"), PackageReference(repo: "https://github.com/yonaskolb/mint"))
        XCTAssertEqual(PackageReference(package: "https://github.com/yonaskolb/mint@0.0.1"), PackageReference(repo: "https://github.com/yonaskolb/mint", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "https://github.com/yonaskolb/mint.git"), PackageReference(repo: "https://github.com/yonaskolb/mint.git"))
        XCTAssertEqual(PackageReference(package: "https://github.com/yonaskolb/mint.git@0.0.1"), PackageReference(repo: "https://github.com/yonaskolb/mint.git", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "mycustomdomain.com/package"), PackageReference(repo: "mycustomdomain.com/package"))
        XCTAssertEqual(PackageReference(package: "mycustomdomain.com/package@0.0.1"), PackageReference(repo: "mycustomdomain.com/package", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "mycustomdomain.com/package.git"), PackageReference(repo: "mycustomdomain.com/package.git"))
        XCTAssertEqual(PackageReference(package: "mycustomdomain.com/package.git@0.0.1"), PackageReference(repo: "mycustomdomain.com/package.git", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "https://mycustomdomain.com/package"), PackageReference(repo: "https://mycustomdomain.com/package"))
        XCTAssertEqual(PackageReference(package: "https://mycustomdomain.com/package@0.0.1"), PackageReference(repo: "https://mycustomdomain.com/package", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "https://mycustomdomain.com/package.git"), PackageReference(repo: "https://mycustomdomain.com/package.git"))
        XCTAssertEqual(PackageReference(package: "https://mycustomdomain.com/package.git@0.0.1"), PackageReference(repo: "https://mycustomdomain.com/package.git", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "git@github.com:yonaskolb/Mint.git"), PackageReference(repo: "git@github.com:yonaskolb/Mint.git"))
        XCTAssertEqual(PackageReference(package: "git@github.com:yonaskolb/Mint.git@0.0.1"), PackageReference(repo: "git@github.com:yonaskolb/Mint.git", version: "0.0.1"))
        XCTAssertEqual(PackageReference(package: "ssh://git@server.com/user/project.git"), PackageReference(repo: "ssh://git@server.com/user/project.git"))
        XCTAssertEqual(PackageReference(package: "ssh://git@server.com/user/project.git@0.1"), PackageReference(repo: "ssh://git@server.com/user/project.git", version: "0.1"))
    }

    func testPackageVersions() {

        XCTAssertFalse(PackageReference(repo: "", version: "my_branch").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "develop").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "master").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "1.0").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "fgvb45g_").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "fgv/b45g").versionCouldBeSHA)
        XCTAssertFalse(PackageReference(repo: "", version: "fgv.b45g").versionCouldBeSHA)

        XCTAssertTrue(PackageReference(repo: "", version: "fgvb45g").versionCouldBeSHA)
        XCTAssertTrue(PackageReference(repo: "", version: "fgvb45g6g4fgvb45g6g4fgvb45g6g4fgvb45g6g4").versionCouldBeSHA)
    }
}
