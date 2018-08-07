//
//  SwiftPackage.swift
//  MintKit
//
//  Created by Yonas Kolb on 5/8/18.
//

import Foundation
import PathKit
import SwiftCLI

struct SwiftPackage: Decodable {

    let name: String
    let products: [Product]

    init(directory: Path) throws {

        let content = try capture("swift", arguments: ["package", "dump-package"], directory: directory.string).stdout

        guard let json = content.index(of: "{"),
            let data = content[json...].data(using: .utf8) else {
            throw MintError.packageFileNotFound
        }

        self = try JSONDecoder().decode(SwiftPackage.self, from: data)
    }

    struct Product: Decodable {
        let name: String
        let type: String

        enum CodingKeys: String, CodingKey {
            case name
            case type = "product_type"
        }

        var isExecutable: Bool {
            return type == "executable"
        }
    }
}
