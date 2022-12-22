//
// Created by v.prusakov on 12/21/22.
//

public struct Platform: RawRepresentable, Codable {
    public private(set) var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension Platform {
    static let iOS = Platform(rawValue: "iOS")
    static let macOS = Platform(rawValue: "macOS")
    static let tvOS = Platform(rawValue: "tvOS")
    static let watchOS = Platform(rawValue: "watchOS")

    static let applePlatforms: [Platform] = [.iOS, .macOS, .tvOS, .watchOS]

    static let linux = Platform(rawValue: "linux")
    static let android = Platform(rawValue: "android")
    static let windows = Platform(rawValue: "windows")
}