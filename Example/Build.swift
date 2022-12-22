//
// Created by v.prusakov on 12/20/22.
//

import Forge

@main
struct App: Build {
    
    @Task(name: "task-build", selector: App.taskBuild) var myTask
    
    init() {
        print("App initialized")
    }

    func build(_ context: Context) async throws {
        if context.platform == .macOS {
            print("build for macOS")
        }

        if context.platform == .iOS {
            print("build for iOS")
        }
        
//        context.addLibrary(
//            SwiftLibrary(
//                name: "iOSApp",
//                sources: [
//                    "Sources/*.swift"
//                ],
//                dependencies: [],
//                swiftSettings: [])
//        )

//        context.spm(.package(url: "", from: ""))
        
//        context.addLibrary(
//            CLibrary(
//                name: "CLibExample",
//                sources: [
//                    "Example/Sources/Example.c"
//                ],
//                publicHeaders: [
//                    "Example/Sources/Example.h"
//                ]
//            ),
//            kind: .static
//        )
//
//        if context.platform == .macOS {
//            context.addLibrary(
//                SwiftLibrary(
//                    name: "SwiftApp",
//                    sources: [
//                        "Example/Sources/*.swift"
//                    ],
//                    swiftCompilerFlags: [
//                        "-Xswiftc", "-target",
//                        "-Xswiftc", "x86_64-apple-macosx11.0"
//                    ]
//                )
//            )
//
//            context.addTarget(
//                Executable(
//                    name: "Example",
//                    targets: [
//                        "SwiftApp"
//                    ]
//                )
//            )
//
//            context.addProduct(
//                Executable(
//                    name: "Example",
//                    targets: [
//                        "Example"
//                    ]
//                )
//            )
//        }

//        if context.platform == .ios {
//            context.addProduct(
//                iOSApp(
//                    name: "Example",
//                    targets: [
//                        "SwiftApp"
//                    ],
//                    bundleId: "com.example",
//                    bundleName: "Example",
//                    bundleShortVersion: "1.0",
//                    bundleVersion: "1",
//                    bundleIcon: "Example/Assets.xcassets/AppIcon.appiconset",
//                    bundleLaunchScreen: "Example/Assets.xcassets/LaunchScreen.storyboard",
//                )
//            )
//        }
    }
    
    func taskBuild(_ args: [String : String]) {
        print("Builded!")
    }
}
