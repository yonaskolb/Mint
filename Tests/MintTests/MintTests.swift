@testable import MintKit
import PathKit
import SwiftCLI
import XCTest

class MintTests: XCTestCase {

    let mint = Mint(path: Path.temporary + "mint",
                    linkPath: Path.temporary + "mint-installs",
                    standardOut: WriteStream.null,
                    standardError: WriteStream.null)
    let testRepo = "yonaskolb/SimplePackage"
    let sshTestRepo = "git@github.com:yonaskolb/SimplePackage.git"
    let testVersion = "4.0.0"
    let latestVersion = "5.0.0"
    let testCommand = "simplepackage"
    let testRepoName = "SimplePackage"

    override func setUp() {
        super.setUp()
        // mint.verbose = true
        mint.runAsNewProcess = false
        try? mint.path.delete()
        try? mint.linkPath.delete()
        mint.mintFilePath = "Mintfile"
    }

    func checkInstalledVersion(package: PackageReference, executable: String, file: StaticString = #file, line: UInt = #line) throws {
        let packagePath = PackagePath(path: mint.packagesPath, package: package, executable: executable)
        XCTAssertTrue(packagePath.executablePath.exists)
        let output = try capture(packagePath.executablePath.string, "--version")
        XCTAssertEqual(output.stdout, package.version, file: file, line: line)
    }

    func testInstallCommand() throws {

        let globalPath = mint.linkPath + testCommand

        // install specific version
        let specificPackage = PackageReference(repo: testRepo, version: testVersion)
        try mint.install(package: specificPackage)
        try checkInstalledVersion(package: specificPackage, executable: testCommand)

        // install using simple name
        try mint.install(package: PackageReference(repo: testRepoName, version: testVersion))

        // check that not globally installed
        XCTAssertFalse(globalPath.exists)
        XCTAssertEqual(mint.getLinkedPackages(), [:])
        // install already installed version globally
        try mint.install(package: PackageReference(repo: testRepo, version: testVersion), link: true)
        XCTAssertTrue(globalPath.exists)
        let globalOutput = try capture(globalPath.string)
        XCTAssertEqual(globalOutput.stdout, testVersion)

        XCTAssertEqual(mint.getLinkedPackages(), [testCommand: testVersion])

        // install latest version
        let latestPackage = PackageReference(repo: testRepo)
        try mint.install(package: latestPackage, executable: testCommand, link: true)
        XCTAssertEqual(latestPackage.version, latestVersion)
        try checkInstalledVersion(package: latestPackage, executable: testCommand)
        XCTAssertEqual(latestPackage.version, latestVersion)

        let latestGlobalOutput = try capture(globalPath.string)
        XCTAssertEqual(latestGlobalOutput.stdout, latestVersion)
        XCTAssertEqual(mint.getLinkedPackages(), [testCommand: latestVersion])

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages[testRepoName, default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: testCommand)

        // check not globally installed
        XCTAssertFalse(globalPath.exists)
        XCTAssertEqual(mint.getLinkedPackages(), [:])

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
    }

    func testRunCommand() throws {

        // run a specific version
        let specificPackage = PackageReference(repo: testRepo, version: testVersion)
        try mint.run(package: specificPackage, arguments: [testCommand])
        try checkInstalledVersion(package: specificPackage, executable: testCommand)

        // run using simple name
        try mint.run(package: PackageReference(repo: testRepoName, version: testVersion), arguments: [])

        // run an already installed version
        try mint.run(package: PackageReference(repo: testRepo, version: testVersion), arguments: [testCommand])

        // run with arguments
        try mint.run(package: PackageReference(repo: testRepo, version: testVersion), arguments: [testCommand, "--version"])

        // run latest version
        let latestPackage = PackageReference(repo: testRepo)
        try mint.run(package: latestPackage, arguments: [testCommand])
        try checkInstalledVersion(package: latestPackage, executable: testCommand)
        XCTAssertEqual(latestPackage.version, latestVersion)

        // check package list has installed versions
        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages[testRepoName, default: []], [testVersion, latestPackage.version])
        XCTAssertEqual(installedPackages.count, 1)

        // uninstall
        try mint.uninstall(name: testCommand)

        // check package list is empty
        XCTAssertTrue(try mint.listPackages().isEmpty)
    }

    func testBootstrapCommand() throws {
        mint.mintFilePath = simpleMintFileFixture.absolute()

        try mint.bootstrap()

        let package = PackageReference(repo: "yonaskolb/SimplePackage", version: "4.0.0")

        let globalPath = mint.linkPath + testCommand

        // check that not globally installed
        XCTAssertFalse(globalPath.exists)
        XCTAssertEqual(mint.getLinkedPackages(), [:])

        let installedPackages = try mint.listPackages()
        XCTAssertEqual(installedPackages["SimplePackage", default: []], [package.version])
        XCTAssertEqual(installedPackages.count, 1)

        try checkInstalledVersion(package: package, executable: testCommand)
    }

    func testMintFileInstall() throws {
        mint.mintFilePath = simpleMintFileFixture.absolute()

        let specificPackage = PackageReference(repo: testRepoName)
        try mint.install(package: specificPackage)
        XCTAssertEqual(specificPackage.version, testVersion)
        try checkInstalledVersion(package: specificPackage, executable: testCommand)
    }

    func testMintFileRun() throws {
        mint.mintFilePath = simpleMintFileFixture.absolute()

        let specificPackage = PackageReference(repo: testRepoName)
        try mint.run(package: specificPackage, arguments: [])
        XCTAssertEqual(specificPackage.version, testVersion)
        try checkInstalledVersion(package: specificPackage, executable: testCommand)
    }

    func testMintErrors() {

        expectError(MintError.cloneError(url: "http://invaliddomain.com/invalid", version: testVersion)) {
            try mint.run(package: PackageReference(repo: "http://invaliddomain.com/invalid", version: testVersion), arguments: ["invalid"])
        }

        expectError(MintError.invalidExecutable("invalidCommand")) {
            try mint.run(package: PackageReference(repo: testRepo, version: testVersion), arguments: ["invalidCommand"])
        }

        expectError(MintError.packageNotFound("invalidPackage")) {
            try mint.run(package: PackageReference(repo: "invalidPackage", version: testVersion), arguments: [])
        }

        expectError(MintError.mintfileNotFound("invalid")) {
            mint.mintFilePath = "invalid"
            try mint.bootstrap()
        }
    }
}
