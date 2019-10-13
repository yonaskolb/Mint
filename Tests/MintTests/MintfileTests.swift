@testable import MintKit
import PathKit
import XCTest

class MintfileTests: XCTestCase {

    func testMintfileFromString() {
        let contents = """
        # Swifttools
        yonaskolb/xcodegen@1.8.0
        realm/SwiftLint@0.25.0 # Linting Tool
        """

        let mintfile = Mintfile(string: contents)

        XCTAssertEqual(
            mintfile.packages,
            [
                PackageReference(repo: "yonaskolb/xcodegen", version: PackageReference.Revision.branch(name: "1.8.0")),
                PackageReference(repo: "realm/SwiftLint", version: PackageReference.Revision.branch(name: "0.25.0")),
            ]
        )

        let expectedPackage = PackageReference(repo: "realm/SwiftLint", version: PackageReference.Revision.branch(name: "0.25.0"))
        XCTAssertEqual(mintfile.package(for: "realm/SwiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "SwiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "realm/swiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "swiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "another/Repo"), nil)
    }

    func testMintfileFromFile() throws {

        let mintfile = try Mintfile(path: mintFileFixture)

        XCTAssertEqual(
            mintfile.packages,
            [
                PackageReference(repo: "yonaskolb/SimplePackage", version: PackageReference.Revision.branch(name: "4.0.0")),
                PackageReference(repo: "yonaskolb/Mint", version: PackageReference.Revision.branch(name: "0.9.1")),
            ]
        )

        let expectedPackage = PackageReference(repo: "yonaskolb/SimplePackage", version: PackageReference.Revision.branch(name: "4.0.0"))
        XCTAssertEqual(mintfile.package(for: "yonaskolb/SimplePackage"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "SimplePackage"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "yonaskolb/Simplepackage"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "simplepackage"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "another/Repo"), nil)
    }
}
