//
// Created by v.prusakov on 12/21/22.
//

public struct Platform: Codable, Equatable {
    public let name: String

    init(name: String) {
        self.name = name
    }
}

public extension Platform {
    static let iOS = Platform(name: "iOS")
    static let macOS = Platform(name: "macOS")
    static let tvOS = Platform(name: "tvOS")
    static let watchOS = Platform(name: "watchOS")

    static let linux = Platform(name: "linux")
    static let android = Platform(name: "android")
    static let windows = Platform(name: "windows")
    
    static func custom(name: String) -> Platform {
        Platform(name: name)
    }
}
