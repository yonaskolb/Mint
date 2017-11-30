//
//  Package.swift
//  MintKit
//
//  Created by Yonas Kolb on 27/9/17.
//

import Foundation
import PathKit

public class Package {
    public var repo: String
    public var version: String
    public var name: String

    public init(repo: String, version: String, name: String) {
        self.repo = repo
        self.version = version
        self.name = name
    }

    public var git: String {
        return Mint.gitURLFromString(repo)
    }

    public var gitVersion: String {
        return "\(git) \(version.quoted)"
    }

    public var commandVersion: String {
        return "\(name) \(version.quoted)"
    }

    var path: Path {
        return Mint.packagesPath + repoPath
    }

    var repoPath: String {
        return git
            .components(separatedBy: "://").last!
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".git", with: "")
    }

    var installPath: Path { return path + "build" + version }
    var commandPath: Path { return installPath + name }
    var metadataPath: Path { return path + "metadata.json" }

}
