@testable import MintKit
import XCTest

final class ProcessInfoExtensionTests: XCTestCase {
    func testMachineHardwareName_Intel() throws {
        #if !(os(macOS) && arch(x86_64))
            try XCTSkipIf(true, "Not running tests on Intel based Mac")
        #endif

        XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "x86_64")
    }

    func testMachineHardwareName_AppleSilicone() throws {
        #if !(os(macOS) && arch(arm64))
        try XCTSkipIf(true, "Not running tests on Apple Silicone based Mac")
        #endif

        XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "arm64")
    }
}
