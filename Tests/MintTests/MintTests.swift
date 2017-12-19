import XCTest
import PathKit
@testable import MintKit

class MintTests: XCTestCase {

    func testPackagePaths() {

        let mint = Mint(path: "testPath/mint")
        let package = Package(repo: "yonaskolb/mint", version: "1.2.0", name: "mint")
        let packagePath = PackagePath(path: mint.packagesPath, package: package)

        XCTAssertEqual(mint.packagesPath, "testPath/mint/packages")
        XCTAssertEqual(packagePath.gitPath, "https://github.com/yonaskolb/mint.git")
        XCTAssertEqual(packagePath.repoPath, "github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.packagePath, "testPath/mint/packages/github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.installPath, "testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0")
        XCTAssertEqual(packagePath.commandPath, "testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0/mint")
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
        ]

        for (url, expected) in urls {
            XCTAssertEqual(PackagePath.gitURLFromString(url), expected)
        }
    }

    static var allTests = [
        ("testPackagePaths", testPackagePaths),
        ("testPackageGitPaths", testPackageGitPaths),
    ]
}
