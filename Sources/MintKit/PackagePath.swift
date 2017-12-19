//
//  MintPath.swift
//  MintKit
//
//  Created by Yonas Kolb on 19/12/17.
//

import Foundation
import PathKit

/// Contains all the paths for packages
struct PackagePath {

    let path: Path
    let package: Package

    init(path: Path, package: Package) {
        self.path = path
        self.package = package
    }

    var gitPath: String { return gitURLFromString(package.repo) }

    var repoPath: String {
        return gitPath
            .components(separatedBy: "://").last!
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".git", with: "")
    }

    var packagePath: Path { return path + repoPath }
    var installPath: Path { return packagePath + "build" + package.version }
    var commandPath: Path { return installPath + package.name }
    

    private func gitURLFromString(_ string: String) -> String {
        if let url = URL(string: string), url.scheme != nil {
            return url.absoluteString
        } else {
            if string.contains("github.com") {
                return "https://\(string).git"
            } else {
                return "https://github.com/\(string).git"
            }
        }
    }
}
