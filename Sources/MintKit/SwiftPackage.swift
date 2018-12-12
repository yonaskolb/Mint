import Foundation
import PathKit
import SwiftCLI

struct SwiftPackage: Decodable {

    let name: String
    let products: [Product]

    init(directory: Path) throws {

        let content: String
        do {
            content = try capture("swift", arguments: ["package", "dump-package"], directory: directory.string).stdout
        } catch let error as CaptureError {
            let captureResult = error.captured
            let message = captureResult.stderr.isEmpty ? captureResult.stdout : captureResult.stderr
            throw MintError.packageError(message)
        }

        guard let json = content.index(of: "{"),
            let data = content[json...].data(using: .utf8) else {
            throw MintError.packageDumpParsingError(content)
        }

        do {
            self = try JSONDecoder().decode(SwiftPackage.self, from: data)
        } catch {
            throw MintError.packageDecodingError(error)
        }
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
