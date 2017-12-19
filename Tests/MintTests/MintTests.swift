import XCTest
import PathKit
import SwiftShell

@testable import MintKit

class MintTests: XCTestCase {

    let mint = Mint(path: Path.temporary + "mint")
    let testRepo = "yonaskolb/mint"
    let testVersion = "0.6.0"
    let testCommand = "mint"

    override class func setUp() {
        super.setUp()
        try? (Path.temporary + "mint").delete()
    }

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

    func testInstallCommand() throws {

        // install specific version
        let testPackage = try mint.install(repo: testRepo, version: testVersion, command: testCommand, force: false)
        let testPackagePath = PackagePath(path: mint.packagesPath, package: testPackage)
        XCTAssertTrue(testPackagePath.commandPath.exists)
        let output = main.run(testPackagePath.commandPath.string, "--version")
        XCTAssertEqual(output.stdout, testVersion)

        // install already installed version
        try mint.install(repo: testRepo, version: testVersion, command: testCommand, force: false)

        // install latest version
        let latestPackage = try mint.install(repo: testRepo, version: "", command: testCommand, force: false)
        XCTAssertEqual(latestPackage.version, Mint.version)

        let packages = try mint.listPackages()
        XCTAssertTrue(packages.count > 0)
    }

    func testRunCommand() throws {
        // run existing version
        try mint.run(repo: testRepo, version: testVersion, command: "mint --version")

        // install and run specific version
        let package = try mint.run(repo: testRepo, version: testVersion, command: "mint --version")
        let packagePath = PackagePath(path: mint.packagesPath, package: package)
        XCTAssertTrue(packagePath.commandPath.exists)
    }

    func testMintErrors() {

        func expectError(_ expectedError: MintError, closure: () throws -> ()) {
            do {
                try closure()
                XCTFail("Expected to fail with \(expectedError)")
            } catch let error as MintError {
                XCTAssertEqual(error, expectedError)
            } catch {
                XCTFail("Expected to fail with \(expectedError)")
            }
        }

        expectError(MintError.repoNotFound("http://invaliddomain.com/invalid")) {
            try mint.run(repo: "http://invaliddomain.com/invalid", version: testVersion, command: "invalid")
        }

        expectError(MintError.invalidRepo("invalid repo")) {
            try mint.install(repo: "invalid repo", version: testVersion, command: "", force: false)
        }

        expectError(MintError.invalidCommand("invalidCommand")) {
            try mint.run(repo: "yonaskolb/mint", version: testVersion, command: "invalidCommand")
        }

        expectError(MintError.packageNotFound("invalidPackage")) {
            try mint.run(repo: "invalidPackage", version: testVersion, command: "")
        }
    }

    static var allTests = [
        ("testPackagePaths", testPackagePaths),
        ("testPackageGitPaths", testPackageGitPaths),
        ("testInstallCommand", testInstallCommand),
        ("testRunCommand", testRunCommand),
        ("testMintErrors", testMintErrors),
    ]
}
