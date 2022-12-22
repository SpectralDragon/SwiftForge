//
// Created by v.prusakov on 12/22/22.
//

import TSCBasic

public class Toolchain {
    
    public let swiftCompilerPath: AbsolutePath
    
    public let forgeLibraryPath: ForgeLibrarySearchPaths
    
    public func getClangCompilerPath() -> AbsolutePath {
        return AbsolutePath("/usr/bin/clang")
    }
    
    init(
        toolchainBinDir: AbsolutePath,
        environment: Environment = .current
    ) throws {
        let envSearchPath = getEnvSearchPaths(pathString: environment.path, currentWorkingDirectory: localFileSystem.currentWorkingDirectory)
        self.swiftCompilerPath = try ToolFinder.findSwiftCompiler(binDir: toolchainBinDir, searchPaths: envSearchPath, useXcrun: false)
        
        let path = "/Users/v.prusakov/Library/Developer/Xcode/DerivedData/SwiftForge-eautxfletrksevdibwxhfaeqxbih/Build/Products/Debug/PackageFrameworks/Forge.framework"
        
        self.forgeLibraryPath = ForgeLibrarySearchPaths.make(for: AbsolutePath(path))
    }
}

class ToolFinder {
    
    private static let hostExecutableSuffix = {
#if os(Windows)
        return ".exe"
#else
        return ""
#endif
    }()
    
    static func findSwiftCompiler(binDir: AbsolutePath, searchPaths: [AbsolutePath], environment: Environment = .current, useXcrun: Bool) throws -> AbsolutePath {
        let name = "swiftc"
        
        if let tool = try? ToolFinder.tool(named: name, binDir: binDir) {
            return tool
        } else if let tool = try? ToolFinder.findTool(named: name, useXcrun: useXcrun, searchPaths: searchPaths) {
            return tool
        }
        
        fatalError("Swift compiler was not found")
    }
    
    static func tool(named: String, binDir: AbsolutePath) throws -> AbsolutePath {
        let toolPath = binDir.appending(component: named + hostExecutableSuffix)
        guard localFileSystem.exists(toolPath) else {
            throw Error.toolNotFound(name: named, searchPaths: [binDir])
        }
        return toolPath
    }
    
    static func findTool(named: String, useXcrun: Bool, searchPaths: [AbsolutePath]) throws -> AbsolutePath {
        if useXcrun {
#if os(macOS)
            let swiftc = try TSCBasic.Process.checkNonZeroExit(arguments: ["/usr/bin/xcrun", "-f", named])
            return AbsolutePath(swiftc)
#endif
        }
        
        for path in searchPaths {
            if let tool = try? Self.tool(named: named, binDir: path) {
                return tool
            }
        }
        
        throw Error.toolNotFound(name: named, searchPaths: searchPaths)
    }
    
    enum Error: Swift.Error {
        case toolNotFound(name: String, searchPaths: [AbsolutePath])
    }
}

public struct ForgeLibrarySearchPaths {
    enum SearchStyle {
        
        case commandLine
        
        case xcode
        
        case spmInXcode
    }
    
    let path: AbsolutePath
    let style: SearchStyle
    
    private init(path: AbsolutePath, style: SearchStyle) {
        self.path = path
        self.style = style
    }
    
    public var includeSearchPath: AbsolutePath {
        switch style {
        case .commandLine:
            return path.parentDirectory
        case .xcode:
            return path.parentDirectory
        case .spmInXcode:
            return path.parentDirectory.parentDirectory
        }
    }
    
    public var librarySearchPath: AbsolutePath {
        switch style {
        case .commandLine:
            return path.parentDirectory
        case .xcode:
            return path.parentDirectory
        case .spmInXcode:
            return path.parentDirectory.parentDirectory
        }
    }
    
    public var frameworkSearchPath: AbsolutePath {
        switch style {
        case .commandLine:
            return path.parentDirectory
        case .xcode:
            return path.parentDirectory
        case .spmInXcode:
            return path.parentDirectory
        }
    }
    
    public static func make(for libraryLocation: AbsolutePath) -> ForgeLibrarySearchPaths {
        ForgeLibrarySearchPaths(
            path: libraryLocation,
            style: style(for: libraryLocation)
        )
    }
    
    private static func style(for path: AbsolutePath) -> SearchStyle {
        if path.extension == "framework" {
            if path.parentDirectory.components.last == "PackageFrameworks" {
                return .spmInXcode
            }
            return .xcode
        }
        return .commandLine
    }
}
