import XCTest

extension MintTests {
    static let __allTests = [
        ("testBootstrapCommand", testBootstrapCommand),
        ("testInstallCommand", testInstallCommand),
        ("testMintErrors", testMintErrors),
        ("testMintFileInstall", testMintFileInstall),
        ("testPackageGitPaths", testPackageGitPaths),
        ("testPackagePaths", testPackagePaths),
        ("testPackageReferenceInfo", testPackageReferenceInfo),
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
