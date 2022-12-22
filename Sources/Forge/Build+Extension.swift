//
//  File.swift
//  
//
//  Created by v.prusakov on 12/22/22.
//

@_implementationOnly import Foundation
import ForgeRuntime
import ForgeBuildCore

typealias BuildToHostConnection = Connection<BuildManifestToHostMessage, HostToBuildManifestMessage>

fileprivate(set) var buildToHostConnection: BuildToHostConnection?

public class BuildContext {
    public let platform: Platform

    public init(platform: Platform) {
        self.platform = platform
    }

    public private(set) var libraries: [Library] = []
    
    public private(set) var products: [Product] = []

    public func addLibrary<L: Library>(_ library: L, kind: LibraryKind = .dynamic) {
        libraries.append(library)
    }
    
    public func addProduct(_ product: Product) {
        products.append(product)
    }
}

extension Build {
    public static func main() async throws {

        // Duplicate the `stdin` file descriptor, which we will then use for
        // receiving messages from the plugin host.
        let inputFD = dup(fileno(stdin))
        guard inputFD >= 0 else {
            fatalError("Could not duplicate `stdin`: \(describe(errno: errno)).")
        }

        // Having duplicated the original standard-input descriptor, we close
        // `stdin` so that attempts by the plugin to read console input (which
        // are usually a mistake) return errors instead of blocking.
        guard close(fileno(stdin)) >= 0 else {
            fatalError("Could not close `stdin`: \(describe(errno: errno)).")
        }

        // Duplicate the `stdout` file descriptor, which we will then use for
        // sending messages to the plugin host.
        let outputFD = dup(fileno(stdout))
        guard outputFD >= 0 else {
            fatalError("Could not dup `stdout`: \(describe(errno: errno)).")
        }

        // Having duplicated the original standard-output descriptor, redirect
        // `stdout` to `stderr` so that all free-form text output goes there.
        guard dup2(fileno(stderr), fileno(stdout)) >= 0 else {
            fatalError("Could not dup2 `stdout` to `stderr`: \(describe(errno: errno)).")
        }

        // Turn off full buffering so printed text appears as soon as possible.
        // Windows is much less forgiving than other platforms.  If line
        // buffering is enabled, we must provide a buffer and the size of the
        // buffer.  As a result, on Windows, we completely disable all
        // buffering, which means that partial writes are possible.
        #if os(Windows)
        setvbuf(stdout, nil, _IONBF, 0)
        #else
        setvbuf(stdout, nil, _IOLBF, 0)
        #endif
        buildToHostConnection = BuildToHostConnection(
            input: FileHandle(fileDescriptor: inputFD),
            output: FileHandle(fileDescriptor: outputFD)
        )

        print("start listening message")

        while let message = try buildToHostConnection?.receiveNextMessage() {
            do {

                print("receiving a message", message)

                try await handleMessage(message)
            } catch {
                try buildToHostConnection?.send(.exit)
                exit(1)
            }
        }
    }

    private static func handleMessage(_ message: HostToBuildManifestMessage) async throws {
        switch message {
        case .buildManifest(let platform):
            let manifest = Self.init()

            let context = BuildContext(platform: platform)
            try await manifest.build(context)

            print("Final context", context.platform, context.libraries)

            let buildManifest = BuildManifest(
                platforms: [platform, .iOS],
                products: [
                    Product(
                        name: "Test",
                        kind: .executable,
                        dependencies: ["Test"]
                    )
                ]
            )

            try buildToHostConnection?.send(.compiledBuildManifest(buildManifest))

            exit(0)
        case .runTask(let name, let arguments):
            print("run task", name, arguments)

            let manifest = Self.init()
            
            guard let task = self.getAllTasks(from: manifest).first(where: { $0.name == name }) else {
                try buildToHostConnection?.send(.emit(message: "Can't find a task by name"))
                try buildToHostConnection?.send(.taskFinished(name: name, status: 1))
                exit(1)
            }
            
            try await task.invoke(manifest, arguments: [:])

            try buildToHostConnection?.send(.taskFinished(name: name, status: 0))

            exit(0)
        }
    }

    // Private function to construct an error message from an `errno` code.
    fileprivate static func describe(errno: Int32) -> String {
        if let cStr = strerror(errno) { return String(cString: cStr) }
        return String(describing: errno)
    }
    
    private static func getAllTasks<T: Build>(from manifest: T) -> [Task<T>] {
        let mirror = Mirror(reflecting: manifest)
        
        return mirror.children.compactMap { $0.value as? Task<T> }
    }
}
