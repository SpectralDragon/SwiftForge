//
// Created by v.prusakov on 12/21/22.
//

public enum LibraryKind: String, Codable {
    case `dynamic`
    case `static`
}

public protocol Library: Codable {
    var name: String { get }
    var dependencies: [String] { get }
}

public struct SwiftSetting: Codable {
    public let name: String
    public let value: String
}

public struct SwiftLibrary: Library {
    public let name: String
    public var sources: [String]
    public var dependencies: [String]
    public var swiftSettings: [SwiftSetting]
    
    public init(name: String, sources: [String], dependencies: [String], swiftSettings: [SwiftSetting]) {
        self.name = name
        self.sources = sources
        self.dependencies = dependencies
        self.swiftSettings = swiftSettings
    }
}

public struct CLibrary: Library {
    public let name: String
    public var sources: [String]
    public var publicHeaders: [String]
    public var dependencies: [String]
}
