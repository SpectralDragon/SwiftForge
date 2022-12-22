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
