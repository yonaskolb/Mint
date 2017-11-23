import Foundation
import XCTest

import ShellOut

@testable import MintKit

class MintTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset (debug) cached installs and files to a clean slate.
        try? FileManager.default.removeItem(at: Mint.path.url)
    }
    override func tearDown() {
        // Clean up debug cache.
        try? FileManager.default.removeItem(at: Mint.path.url)
    }

    let testRepository = "yonaskolb/Mint"; let invalidRepository = "yonaskolb/Mnt"
    let testPackageShorthand = "Mint"; let invalidPackageShorthand = "Mnt"
    let testVersion = "0.1.0"
    let testCommand = "Mint"; let invalidCommand = "Mnt"
    let testCommandWithArguments = "Mint --help"

    func testInstallCommand() {
        // Standard
        do {
            try Mint.install(repo: testRepository, version: testVersion, command: testCommand, force: false)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        // Already installed
        do {
            try Mint.install(repo: testRepository, version: testVersion, command: testCommand, force: false)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        // Invalid repository
        do {
            try Mint.install(repo: invalidPackageShorthand, version: testVersion, command: testCommand, force: false)
            XCTFail("No error thrown with invalid repository.")
        } catch let error {
            XCTAssertEqual(error as? MintError, MintError.invalidRepo(invalidPackageShorthand))
        }
    }

    func testRunCommand() {
        // Standard
        do {
            try Mint.run(repo: testRepository, version: testVersion, command: testCommand)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        do {
            try Mint.run(repo: invalidRepository, version: testVersion, command: testCommand)
            XCTFail("No error thrown with invalid repository.")
        } catch let error {
            XCTAssertEqual(error as? MintError, MintError.repoNotFound("https://github.com/" + invalidRepository + ".git"))
        }

        // Shorthand when already intalled
        do {
            try Mint.run(repo: testPackageShorthand, version: testVersion, command: testCommand)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        do {
            try Mint.run(repo: invalidPackageShorthand, version: testVersion, command: testCommand)
            XCTFail("No error thrown with invalid package shorthand.")
        } catch let error {
            XCTAssertEqual(error as? MintError, MintError.packageNotFound(invalidPackageShorthand))
        }

        // Specified command name
        do {
            try Mint.run(repo: testRepository, version: testVersion, command: invalidCommand)
            XCTFail("No error thrown with invalid command.")
        } catch let error {
            XCTAssertEqual(error as? MintError, MintError.invalidCommand(invalidCommand.components(separatedBy: " ").first!))
        }

        // With arguments
        do {
            try Mint.run(repo: testRepository, version: testVersion, command: testCommandWithArguments)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        // With GitHub domain
        do {
            try Mint.run(repo: "github.com/" + testRepository, version: testVersion, command: testCommand)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testVersionlessRepository() {
        let temp = URL(fileURLWithPath: "/tmp/MyPackage")
        try? FileManager.default.removeItem(at: temp)
        defer { try? FileManager.default.removeItem(at: temp) }

        do {
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true, attributes: nil)
            try shellOut(to: "swift package init --type executable", at: temp.path)
            try shellOut(to: "git init", at: temp.path)
            try shellOut(to: "echo \u{22}Sources\nNonexistent\u{22} > Package.resources", at: temp.path)
            try shellOut(to: "git add .", at: temp.path)
            try shellOut(to: "git commit -m \u{22}Committed.\u{22}", at: temp.path)

            try Mint.run(repo: temp.absoluteString, version: "", command: "MyPackage")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    static var allTests = [
        ("testInstallCommand", testInstallCommand),
        ("testRunCommand", testRunCommand),
        ("testVersionlessRepository", testVersionlessRepository)
    ]
}
