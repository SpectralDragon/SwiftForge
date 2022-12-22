//
// Created by v.prusakov on 12/22/22.
//

import Foundation
import ArgumentParser
import TSCBasic
import ForgeRuntime

public protocol ForgeCommand: ParsableCommand {
    func run(_ context: ForgeContext) throws
}

extension ForgeCommand {
    public func run() throws {
        let context = ForgeContext()

        try self.run(context)
    }
}

public class Workspace {
    public let path: AbsolutePath

    public let fileSystem: FileSystem

    public let toolchain: Toolchain

    public let manifestRunner: BuildManifestRunner

    init(
        path: AbsolutePath,
        fileSystem: FileSystem,
        toolchain: Toolchain,
        manifestRunner: BuildManifestRunner
    ) {
        self.path = path
        self.fileSystem = fileSystem
        self.toolchain = toolchain
        self.manifestRunner = manifestRunner
    }

    public func getManifestGraph() throws {
        let manifest = path.appending(component: "Build.swift")

        manifestRunner.runBuildManifest(at: manifest, initialMessage: Data()) { result in
            print(result)
        }
    }
}

public class ForgeContext {
    
    private var toolchain: Toolchain?

    init() {

    }
    
    public func getWorkspace() throws -> Workspace {
        let manifestRunner = try DefaultBuildManifestRunner(
            cacheDirectory: AbsolutePath("/Users/v.prusakov/Developer/SwiftForge/Example"),
            toolchain: self.getHostToolchain()
        )
        
        return try Workspace(
            path: AbsolutePath("/Users/v.prusakov/Developer/SwiftForge/Example"),
            fileSystem: localFileSystem,
            toolchain: self.getHostToolchain(),
            manifestRunner: manifestRunner
        )
    }

    public func getHostToolchain() throws -> Toolchain {
        // Get cached toolchain
        if let toolchain = toolchain {
            return toolchain
        }

        let toolchain = try Toolchain(
            toolchainBinDir: Self.getBinDir()
        )

        self.toolchain = toolchain

        return toolchain
    }

    private static func getBinDir() throws -> AbsolutePath {
        #if os(macOS)
        let originalWorkingDirectory = localFileSystem.currentWorkingDirectory
        guard let cwd = originalWorkingDirectory else {
            return try AbsolutePath(validating: CommandLine.arguments[0]).parentDirectory
        }
        return try AbsolutePath(validating: CommandLine.arguments[0], relativeTo: cwd).parentDirectory
        #endif

        fatalError()
    }
}
