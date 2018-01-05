@testable import MintKit
import PathKit
import SwiftShell
import XCTest

class MintTests: XCTestCase {

    let mint = Mint(path: Path.temporary + "mint", installationPath: Path.temporary + "mint-installs")
    let testRepo = "yonaskolb/simplepackage"
    let testVersion = "2.0.0"
    let latestVersion = "3.0.0"
    let testCommand = "simplepackage"

    override func setUp() {
        super.setUp()
        try? mint.path.delete()
        try? mint.installationPath.delete()
    }

    func testPackagePaths() {

        let testMint = Mint(path: "/testPath/mint", installationPath: "/testPath/mint-installs")
        let package = Package(repo: "yonaskolb/mint", version: "1.2.0", name: "mint")
        let packagePath = PackagePath(path: testMint.packagesPath, package: package)

        XCTAssertEqual(testMint.path, "/testPath/mint")
        XCTAssertEqual(testMint.packagesPath, "/testPath/mint/packages")
        XCTAssertEqual(testMint.installationPath, "/testPath/mint-installs")
        XCTAssertEqual(packagePath.gitPath, "https://github.com/yonaskolb/mint.git")
        XCTAssertEqual(packagePath.repoPath, "github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.packagePath, "/testPath/mint/packages/github.com_yonaskolb_mint")
        XCTAssertEqual(packagePath.installPath, "/testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0")
        XCTAssertEqual(packagePath.commandPath, "/testPath/mint/packages/github.com_yonaskolb_mint/build/1.2.0/mint")
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

        let globalPath = mint.installationPath + testCommand

        // install specific version
        let specificPackage = try mint.install(repo: testRepo, version: testVersion, command: testCommand)
        expectMintVersion(package: specificPackage)

        // check that not globally installed
        XCTAssertFalse(globalPath.exists)

        // install already installed version globally
        try mint.install(repo: testRepo, version: testVersion, command: testCommand, global: true)

        XCTAssertTrue(globalPath.exists)
        let globalOutput = main.run(globalPath.string)
        XCTAssertEqual(globalOutput.stdout, testVersion)

        // install latest version
        let latestPackage = try mint.install(repo: testRepo, version: "", command: testCommand, global: true)
        expectMintVersion(package: latestPackage)
        XCTAssertEqual(latestPackage.version, latestVersion)
        let latestGlobalOutput = main.run(globalPath.string)
        XCTAssertEqual(latestGlobalOutput.stdout, latestVersion)

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages[testCommand, default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: testCommand)

        // check not globally installed
        XCTAssertFalse(globalPath.exists)

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
    }

    func testRunCommand() throws {

        // run a specific version
        let specificPackage = try mint.run(repo: testRepo, version: testVersion, arguments: [testCommand])
        expectMintVersion(package: specificPackage)

        // run an already installed version
        try mint.run(repo: testRepo, version: testVersion, arguments: [testCommand])

        // run without arguments
        try mint.run(repo: testRepo, version: testVersion, arguments: [testCommand])

        // run with arguments
        try mint.run(repo: testRepo, version: testVersion, arguments: [testCommand, "--version"])

        // run latest version
        let latestPackage = try mint.run(repo: testRepo, version: "", arguments: [testCommand])
        expectMintVersion(package: latestPackage)
        XCTAssertEqual(latestPackage.version, latestVersion)

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages[testCommand, default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: testCommand)

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
    }

    func testMintErrors() {

        func expectError(_ expectedError: MintError, closure: () throws -> Void) {
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
            try mint.run(repo: "http://invaliddomain.com/invalid", version: testVersion, arguments: ["invalid"])
        }

        expectError(MintError.invalidRepo("invalid repo")) {
            try mint.install(repo: "invalid repo", version: testVersion, command: "", force: false)
        }

        expectError(MintError.invalidCommand("invalidCommand")) {
            try mint.run(repo: testRepo, version: testVersion, arguments: ["invalidCommand"])
        }

        expectError(MintError.packageNotFound("invalidPackage")) {
            try mint.run(repo: "invalidPackage", version: testVersion, arguments: [])
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
