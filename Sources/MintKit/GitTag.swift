import Foundation
import Version

func convertTagsToVersionMap(_ tags: [String]) -> [Version: String] {
    var knownVersions: [Version: String] = [:]
    for tag in tags {
        if let version = Version(tolerant: tag) {
            knownVersions[version] = tag
        }
    }
    return knownVersions
}
