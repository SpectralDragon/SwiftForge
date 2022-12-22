//
//  Product.swift
//  
//
//  Created by v.prusakov on 12/22/22.
//

import Foundation

public struct Product: Codable {
    
    public enum ProductKind: String, Codable {
        case executable
        case library
    }
    
    public let name: String
    
    public let kind: ProductKind
    
    public let dependencies: [String]

    public init(name: String, kind: ProductKind, dependencies: [String]) {
        self.name = name
        self.kind = kind
        self.dependencies = dependencies
    }
}
