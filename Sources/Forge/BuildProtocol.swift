//
// Created by v.prusakov on 12/20/22.
//

@_implementationOnly import Foundation
import ForgeRuntime
import ForgeBuildCore

public protocol Build {
    typealias Context = BuildContext
    
    init()
    
    func build(_ context: Context) async throws
}

typealias BuildConnection = Connection<BuildManifestToHostMessage, HostToBuildManifestMessage>

fileprivate(set) var buildToHostConnection: BuildConnection?

public class BuildContext {
    public let platform: Platform
    
    public init(platform: Platform) {
        self.platform = platform
    }
    
    var libraries: [Library] = []
    
    public func addLibrary<L: Library>(_ library: L, kind: LibraryKind = .dynamic) {
        libraries.append(library)
    }
}

extension Build {
    public static func main() async throws {
        
        print("Started")
        
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
        buildToHostConnection = BuildConnection(
            input: FileHandle(fileDescriptor: inputFD),
            output: FileHandle(fileDescriptor: outputFD)
        )
        
        print("start listening message")
        
        while let message = try buildToHostConnection?.receiveNextMessage() {
            do {
                
                print("receiving a message", message)
                
                try await handleMessage(message)
            }
            catch {
                exit(1)
            }
        }
    }
    
    private static func handleMessage(_ message: HostToBuildManifestMessage) async throws {
        
        let manifest = Self.init()
        
        let context = BuildContext(platform: message.platform)
        try await manifest.build(context)
        
        print("Final context", context.platform, context.libraries)
        
        exit(0)
        
        
        //        switch message {
        //        case .buildManifest(let path):
        //            let context = BuildContext()
        //            try await buildManifest.build(context)
        ////            try buildToHostConnection.send(.buildManifest(String(data: try context.dump(), encoding: .utf8)!))
        //        }
    }
    
    // Private function to construct an error message from an `errno` code.
    fileprivate static func describe(errno: Int32) -> String {
        if let cStr = strerror(errno) { return String(cString: cStr) }
        return String(describing: errno)
    }
}
