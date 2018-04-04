@testable import MintKit
import PathKit
import XCTest


class MintfileTests: XCTestCase {

    func testMintfileFromString() {
      let contents =  """
                      # Swifttools
                      yonaskolb/xcodegen@1.8.0
                      realm/SwiftLint@0.25.0 # Linting Tool
                      """
      
      let mintfile = Mintfile(string: contents)
      
      XCTAssertEqual(
        mintfile!.packageInfos,
        [
          PackageInfo(version: "1.8.0", repo: "yonaskolb/xcodegen"),
          PackageInfo(version: "0.25.0", repo: "realm/SwiftLint")
        ]
      )
      
      XCTAssertEqual(mintfile!.version(for: "realm/SwiftLint"), "0.25.0")
      XCTAssertEqual(mintfile!.version(for: "another/Repo"), "")
    }
  
  func testMintfileFromFile() {
    let testBundle = Bundle(for: type(of: self))
    
    let path = testBundle.path(
      forResource: "mintfile",
      ofType: nil,
      inDirectory: nil
    )
    
    let mintfile = Mintfile(path: Path(path!))
    
    XCTAssertEqual(
      mintfile!.packageInfos,
      [
        PackageInfo(version: "1.8.0", repo: "yonaskolb/xcodegen"),
        PackageInfo(version: "0.25.0", repo: "realm/SwiftLint")
      ]
    )
    
    XCTAssertEqual(mintfile!.version(for: "realm/SwiftLint"), "0.25.0")
    XCTAssertEqual(mintfile!.version(for: "another/Repo"), "")
  }

}
