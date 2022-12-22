//
//  File.swift
//  
//
//  Created by v.prusakov on 12/22/22.
//

@propertyWrapper
public struct Task<T: Build> {
    
    public typealias BuildSelector = (T) -> ([String: String]) async throws -> Void
    
    let name: String
    let selector: BuildSelector
    public var wrappedValue: Void
    
    public init(name: String, selector: @escaping BuildSelector) {
        self.name = name
        self.selector = selector
    }
    
    func invoke(_ target: T, arguments: [String: String]) async throws {
        try await self.selector(target)(arguments)
    }
}
