//
// Created by v.prusakov on 12/21/22.
//

//@_implementationOnly import Foundation

import ForgeBuildCore

public struct HostToBuildManifestMessage: Codable {
//    case buildManifest(String)
    
    public let platform: Platform
    
    public init(platform: Platform) {
        self.platform = platform
    }
}

public enum BuildManifestToHostMessage: Codable {
    case buildManifest(String)
}
