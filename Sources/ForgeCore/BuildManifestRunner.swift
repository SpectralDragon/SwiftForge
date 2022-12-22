//
// Created by v.prusakov on 12/21/22.
//

import Foundation
import TSCBasic
import TSCUtility
import ForgeRuntime

//protocol BuildManifestRunnerDelegate: AnyObject {
//    func buildManifestRunner(_ runner: BuildManifestRunner, didReceiveMessage message: BuildManifestToHostMessage)
//}

typealias HostToBuildConnection = Connection<HostToBuildManifestMessage, BuildManifestToHostMessage>

public struct BuildManifestResult {
    
}

public protocol BuildManifestRunner {
    func compileBuildManifest(
        source: AbsolutePath,
        dependencies: [AbsolutePath],
        completion: @escaping (Result<String, Error>) -> Void
    )
    
    func runBuildManifest(
        at path: AbsolutePath,
        initialMessage: HostToBuildManifestMessage,
        completion: @escaping (Result<BuildManifestResult, Error>) -> Void
    )
}

public class DefaultBuildManifestRunner: BuildManifestRunner {
    
    private let toolchain: Toolchain
    private let queue = DispatchQueue(label: "org.swiftforge.build-manifest-runner")
    
    private let cacheDirectory: AbsolutePath
    
    public init(
        cacheDirectory: AbsolutePath,
        toolchain: Toolchain
    ) {
        self.toolchain = toolchain
        self.cacheDirectory = cacheDirectory
    }
    
    public func compileBuildManifest(
        source: AbsolutePath,
        dependencies: [AbsolutePath],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let execName = "BuildManifest"
        
#if os(Windows)
        let execSuffix = ".exe"
#else
        let execSuffix = ""
#endif
        let execFilePath = self.cacheDirectory.appending(component: execName + execSuffix)
        let diagFilePath = self.cacheDirectory.appending(component: execName + ".dia")
        
        var commandLineArguments = [self.toolchain.swiftCompilerPath.pathString]
        
        let forgeLibraryPath = self.toolchain.forgeLibraryPath
        
        commandLineArguments += [
            "-I", forgeLibraryPath.includeSearchPath.pathString,
            "-L", forgeLibraryPath.librarySearchPath.pathString,
            "-F", forgeLibraryPath.frameworkSearchPath.pathString,
        ]
        
        if forgeLibraryPath.path.extension == "dylib" {
            commandLineArguments += [
                "-lForge"
            ]
#if !os(Windows)
            // -rpath argument is not supported on Windows,
            // so we add runtimePath to PATH when executing the manifest instead
            commandLineArguments += ["-Xlinker", "-rpath", "-Xlinker", forgeLibraryPath.path.pathString]
#endif
        } else {
            commandLineArguments += [
                "-framework", "Forge",
                "-Xlinker", "-rpath", "-Xlinker", forgeLibraryPath.path.parentDirectory.pathString,
            ]
        }
        
        commandLineArguments.append("-g")
        
#if os(macOS)
        if let sdk = self.sdkRoot() {
            commandLineArguments += ["-sdk", sdk.pathString]
        }
#endif
        
        commandLineArguments += ["-parse-as-library"]
        
        commandLineArguments += ["-Xfrontend", "-serialize-diagnostics-path", "-Xfrontend", diagFilePath.pathString]
        
        // Add source file of manifest
        commandLineArguments += [source.pathString]
        
        commandLineArguments += ["-o", execFilePath.pathString]
        
        //        print(commandLineArguments.joined(separator: " "))
        
        TSCBasic.Process.popen(
            arguments: commandLineArguments,
            environment: [:],
            queue: self.queue
        ) { [weak self] process in
            guard let self = self else { return }
            dispatchPrecondition(condition: .onQueue(self.queue))
            
            completion(process.tryMap { result in
                print("Finished with result")
                
                return execFilePath.pathString
            })
        }
    }
    
    public func runBuildManifest(
        at path: AbsolutePath,
        initialMessage: HostToBuildManifestMessage,
        completion: @escaping (Result<BuildManifestResult, Error>) -> Void
    ) {
        
        print("Begin compile at path \(path.pathString)")
        
        self.compileBuildManifest(
            source: path,
            dependencies: []
        ) { result in
            
            switch result {
            case .success(let path):
                self.invoke(
                    executable: AbsolutePath(path),
                    initialMessage: initialMessage
                )
            case .failure(let error):
                fatalError(error.localizedDescription)
            }
        }
    }
    
    private func sdkRoot() -> AbsolutePath? {
        var sdkRootPath: AbsolutePath?
        // Find SDKROOT on macOS using xcrun.
#if os(macOS)
        let foundPath = try? TSCBasic.Process.checkNonZeroExit(
            args: "/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-path"
        )
        guard let sdkRoot = foundPath?.spm_chomp(), !sdkRoot.isEmpty else {
            return nil
        }
        if let path = try? AbsolutePath(validating: sdkRoot) {
            sdkRootPath = path
        }
#endif
        
        return sdkRootPath
    }
    
    private func invoke(executable: AbsolutePath, initialMessage: HostToBuildManifestMessage) {
        let process = Process()
        process.executableURL = executable.asURL
        process.arguments = []
        process.environment = ProcessInfo.processInfo.environment
        process.currentDirectoryURL = localFileSystem.currentWorkingDirectory?.asURL
        
        // Set up a pipe for sending structured messages to the plugin on its stdin.
        let stdinPipe = Pipe()
        let outputHandle = stdinPipe.fileHandleForWriting
        let outputQueue = DispatchQueue(label: "plugin-send-queue")
        process.standardInput = stdinPipe
        
        // Set up a pipe for receiving messages from the plugin on its stdout.
        let stdoutPipe = Pipe()
        
        let connection = HostToBuildConnection(
            input: stdoutPipe.fileHandleForReading,
            output: outputHandle
        )
        
        process.standardOutput = stdoutPipe
        
        // Set up a pipe for receiving free-form text output from the plugin on its stderr.
        let stderrPipe = Pipe()
        var stderrData = Data()
        
        stderrPipe.fileHandleForReading.readabilityHandler = { (fileHandle: FileHandle) -> Void in
            // Read and pass on any available free-form text output from the plugin.
            // We need the lock since we could run concurrently with the termination handler.
            let data = fileHandle.availableData
            
            // Pass on any available data to the delegate.
            if data.isEmpty { return }
            stderrData.append(contentsOf: data)
            self.queue.async {
                print(String(data: data, encoding: .utf8)!)
            }
            
        }
        
        process.standardError = stderrPipe
        
        do {
            try process.run()
            
            try connection.send(initialMessage)
            
            while let message = try connection.receiveNextMessage() {
                
                switch message {
                case .compiledBuildManifest(let result):
                    print("Got result \(result)")
                    break
                case .emit(let message):
                    print("Emitted", message)
                case .exit:
                    break
                case .taskFinished(let taskName, let result):
                    print("task \(taskName) finished with result \(result)")
                    break
                }
            }
        } catch {
            fatalError("Failed to run process: \(error)")
        }
    }
}
