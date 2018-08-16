import Foundation
import XCTest

func expectError<T>(_ expectedError: T, file: StaticString = #file, line: UInt = #line, closure: () throws -> Void) where T: Error, T: Equatable {
    do {
        try closure()
        XCTFail("Expected to fail with <\(expectedError)>", file: file, line: line)
    } catch let error as T {
        if error != expectedError {
            XCTFail("Expected to fail with <\(expectedError)> but failed with <\(error)>", file: file, line: line)
        }
    } catch {
        XCTFail("Expected to fail with <\(expectedError)>", file: file, line: line)
    }
}
