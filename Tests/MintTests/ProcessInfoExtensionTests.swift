@testable import MintKit
import XCTest

final class ProcessInfoExtensionTests: XCTestCase {
    func testMachineHardwareName_Intel() {
        #if !(os(macOS) && arch(x86_64))
            print("Test can only be run on an Intel based Mac")
        #else
            XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "x86_64")
        #endif
    }

    func testMachineHardwareName_AppleSilicone() {
        #if !(os(macOS) && arch(arm64))
            print("Test can only be run on an Apple Silicon based Mac")
        #else
            XCTAssertEqual(ProcessInfo.processInfo.machineHardwareName, "arm64")
        #endif
    }
}
