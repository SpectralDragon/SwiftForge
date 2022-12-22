//
// Created by v.prusakov on 12/22/22.
//

import Foundation
import ArgumentParser

public struct SwiftForge: ParsableCommand {
    public private(set) static var configuration = CommandConfiguration(
        commandName: "forge",
        abstract: "A tool for generating Swift code from Xcode projects.",
        subcommands: [
            ForgeRun.self,
            ForgeBuild.self
//            Help.self,
//            Version.self,
        ]
    )

    public init() {}
}
