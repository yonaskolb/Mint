import XCTest
import PathKit
import SwiftShell

@testable import MintKit

class MintTests: XCTestCase {

    let mint = Mint(path: Path.temporary + "mint")
    let testRepo = "yonaskolb/mint"
    let testVersion = "0.6.0"
    let testCommand = "mint"

    override func setUp() {
        super.setUp()
        try? mint.path.delete()
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

    func expectMintVersion(package: Package) {
        let packagePath = PackagePath(path: mint.packagesPath, package: package)
        XCTAssertTrue(packagePath.commandPath.exists)
        let output = main.run(packagePath.commandPath.string, "--version")
        XCTAssertEqual(output.stdout, package.version)
    }

    func testInstallCommand() throws {

        let globalPath = mint.installsPath + "mint"

        // install specific version
        let specificPackage = try mint.install(repo: testRepo, version: testVersion, command: testCommand)
        expectMintVersion(package: specificPackage)

        // check that not globally installed
        XCTAssertFalse(globalPath.exists)

        // install already installed version globally
        try mint.install(repo: testRepo, version: testVersion, command: testCommand, global: true)

        XCTAssertTrue(globalPath.exists)
        let globalOutput = main.run(globalPath.string, "--version")
        XCTAssertEqual(globalOutput.stdout, testVersion)

        // install latest version
        let latestPackage = try mint.install(repo: testRepo, version: "", command: testCommand, global: true)
        expectMintVersion(package: latestPackage)
        XCTAssertEqual(latestPackage.version, Mint.version)
        let latestGlobalOutput = main.run(globalPath.string, "--version")
        XCTAssertEqual(latestGlobalOutput.stdout, Mint.version)

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages["mint", default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: "mint")

        // check not globally installed
        XCTAssertFalse(globalPath.exists)

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
    }

    func testRunCommand() throws {

        let versionCommand = "mint --version"
        // run a specific version
        let specificPackage = try mint.run(repo: testRepo, version: testVersion, command: versionCommand)
        expectMintVersion(package: specificPackage)

        // run an already installed version
        try mint.run(repo: testRepo, version: testVersion, command: versionCommand)

        // run without arguments
        try mint.run(repo: testRepo, version: testVersion, command: "mint")

        // run latest version
        let latestPackage = try mint.run(repo: testRepo, version: "", command: versionCommand)
        expectMintVersion(package: latestPackage)
        XCTAssertEqual(latestPackage.version, Mint.version)

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages["mint", default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: "mint")

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
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
