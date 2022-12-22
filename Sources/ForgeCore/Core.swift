//
// Created by v.prusakov on 12/21/22.
//

import Foundation
import TSCBasic

public typealias Environment = [String: String]

public extension Environment {
    static let empty: Environment = [:]

    static let current: Environment = ProcessInfo.processInfo.environment

    var path: String? {
        #if os(Windows)
        return self["Path"]
        #else
        return self["PATH"]
        #endif
    }
}