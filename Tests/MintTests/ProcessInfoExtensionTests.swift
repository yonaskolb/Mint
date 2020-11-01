@testable import MintKit
import XCTest

final class ProcessInfoExtensionTests: XCTestCase {
    #if os(macOS)

    #if arch(x86_64)
    func testMachineHardwareName_Intel() {
        XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "x86_64")
    }
    #endif

    #if arch(arm64)
    func testMachineHardwareName_AppleSilicone() {
        XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "arm64")
    }
    #endif

    #endif
}
