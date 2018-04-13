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

        let expectedPackage = MintPackage(repo: "realm/SwiftLint", version: "0.25.0")
        
        XCTAssertEqual(
            mintfile.packages,
            [
                MintPackage(repo: "yonaskolb/xcodegen", version: "1.8.0"),
                MintPackage(repo: "realm/SwiftLint", version: "0.25.0"),
            ]
        )
        
        XCTAssertEqual(mintfile.package(for: "realm/SwiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "SwiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "realm/swiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "swiftLint"), expectedPackage)
        XCTAssertEqual(mintfile.package(for: "another/Repo"), nil)
    }
}
