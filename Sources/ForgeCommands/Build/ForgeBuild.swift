//
// Created by v.prusakov on 12/20/22.
//

import Foundation
import ArgumentParser
import ForgeCore

struct ForgeBuild: ForgeCommand {
    static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the project."
    )

    func run(_ context: ForgeContext) throws {

    }
}