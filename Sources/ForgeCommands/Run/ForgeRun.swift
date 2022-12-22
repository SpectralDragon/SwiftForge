//
// Created by v.prusakov on 12/20/22.
//

import Foundation
import ForgeCore
import ArgumentParser

struct ForgeRun: ForgeCommand {
    static var configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Build and run the project."
    )

    func run(_ context: ForgeContext) throws {
        let workspace = try context.getWorkspace()
        let graph = try workspace.getManifestGraph()
        print(graph)
    }
}
