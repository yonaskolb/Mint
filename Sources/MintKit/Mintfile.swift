//
//  Mintfile.swift
//  MintKit
//
//  Created by Wolfgang Lutz on 04.04.18.
//

import Foundation
import PathKit

struct Mintfile {
  static let defaultPath = Path(FileManager.default.currentDirectoryPath) + ".mintfile"
  
  static func `default`() -> Mintfile? {
    return self.init(path: Mintfile.defaultPath)
  }
  
  let packageInfos: [PackageInfo]
  
  public func version(for repo: String) -> String {
    return packageInfos.first { $0.repo == repo }?.version ?? ""
  }
  
  init?(path: Path) {
    guard FileManager.default.fileExists(atPath: path.string) else {
      return nil
    }
    
    guard let contents = try? String(contentsOfFile: path.string, encoding: .utf8) else {
      fatalError("Could not read mintfile at \(path).")
    }
    
    self.init(string: contents)
  }
  
  init?(string: String) {
    guard !string.isEmpty else {
      return nil
    }
    
    let lines = string
      .split(separator: "\n")
      .map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
    
    let linesWithoutCommentLines = lines
      .filter{ !$0.hasPrefix("#")}
    
    #if swift(>=4.1)
      let linesWithoutTrailingComments = linesWithoutCommentLines.compactMap { $0.split(separator: "#").first }
    #else
      let linesWithoutTrailingComments = linesWithoutCommentLines.flatMap { $0.split(separator: "#").first }
    #endif
    
    self.packageInfos = linesWithoutTrailingComments
      .map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
      .map { PackageInfo(package: String($0)) }
    
    // Print warning for empty version
    packageInfos
      .filter { $0.version.isEmpty }
      .forEach { print("🌱  MINTFILE: repository \($0.repo) has no defined version. Specify a version using <Repo>@<Commitish>.") }

    // Print warning for multiple definitions
    let occurences = [String: Int]()
    
    packageInfos
      .map { $0.repo }
      .reduce(into: occurences) { (occurences, repo) in
        let count = occurences[repo]
        occurences[repo] = (count ?? 0) + 1
      }.filter { (_, count) -> Bool in
      count != 1
      }.forEach { (repo, _) in
        let version = packageInfos.first { packageInfo -> Bool in
          packageInfo.repo == repo
        }!.version
        
        print("🌱  MINTFILE: repository \"\(repo)\" defined multiple times. Using version \"\(version)\".")
    }
  }
  
}
