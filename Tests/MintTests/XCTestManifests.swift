import XCTest

extension MintTests {
    static let __allTests = [
        ("testInstallCommand", testInstallCommand),
        ("testMintErrors", testMintErrors),
        ("testPackageReferenceInfo", testPackageReferenceInfo),
        ("testPackageGitPaths", testPackageGitPaths),
        ("testPackagePaths", testPackagePaths),
        ("testRunCommand", testRunCommand),
    ]
}

extension MintfileTests {
    static let __allTests = [
        ("testMintfileFromFile", testMintfileFromFile),
        ("testMintfileFromString", testMintfileFromString),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MintTests.__allTests),
        testCase(MintfileTests.__allTests),
    ]
}
#endif
