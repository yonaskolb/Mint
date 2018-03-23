//
//  PackageInfo.swift
//  MintKit
//
//  Created by Wolfgang Lutz on 18.03.18.
//

import Foundation

struct PackageInfo {
  let version: String
  let repo: String
  
  public init(version: String, repo: String) {
    self.version = version
    self.repo = repo
  }
  
  public init(package: String) {
    let packageParts = package.components(separatedBy: "@")
    if packageParts.count == 3 {
      self.init(version: packageParts[2], repo: [packageParts[0], packageParts[1]].joined(separator: "@"))
    } else if packageParts.count == 2 {
      if packageParts[1].contains(":") {
        self.init(version: "", repo: [packageParts[0], packageParts[1]].joined(separator: "@"))
      } else {
        self.init(version: packageParts[1], repo: packageParts[0])
      }
    } else {
      self.init(version: "", repo: package)
    }
  }
  
}

extension PackageInfo: Equatable {
  static func ==(lhs: PackageInfo, rhs: PackageInfo) -> Bool {
    return lhs.repo == rhs.repo && lhs.version == rhs.version
  }
}

