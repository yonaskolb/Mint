import XCTest

extension MintTests {
    static let __allTests = [
        ("testBootstrapCommand", testBootstrapCommand),
        ("testInstallCommand", testInstallCommand),
        ("testMintErrors", testMintErrors),
        ("testMintFileInstall", testMintFileInstall),
        ("testRunCommand", testRunCommand),
        ("testListCommandDumpFunctionality", testListCommandDumpFunctionality),
    ]
}

extension MintfileTests {
    static let __allTests = [
        ("testMintfileFromFile", testMintfileFromFile),
        ("testMintfileFromString", testMintfileFromString),
    ]
}

extension PackageTests {
    static let __allTests = [
        ("testPackageGitPaths", testPackageGitPaths),
        ("testPackagePaths", testPackagePaths),
        ("testPackageReferenceInfo", testPackageReferenceInfo),
    ]
}

#if !os(macOS)
    public func __allTests() -> [XCTestCaseEntry] {
        return [
            testCase(MintTests.__allTests),
            testCase(MintfileTests.__allTests),
            testCase(PackageTests.__allTests),
        ]
    }
#endif
