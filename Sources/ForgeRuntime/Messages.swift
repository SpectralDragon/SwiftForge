//
// Created by v.prusakov on 12/21/22.
//

//@_implementationOnly import Foundation

import ForgeBuildCore

public enum HostToBuildManifestMessage: Codable {
    case buildManifest(Platform)

    case runTask(name: String, arguments: [String])
}

public enum BuildManifestToHostMessage: Codable {
    
    case compiledBuildManifest(BuildManifest)
    
    case emit(message: String)
    
    case exit

    case taskFinished(name: String, status: Int32)
}
