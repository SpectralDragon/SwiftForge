//
//  BuildManifest.swift
//  
//
//  Created by v.prusakov on 12/22/22.
//

import Foundation

public struct BuildManifest: Codable {
    
    public let platforms: [Platform]
    
//    public let libraries: [Library]
    
    public let products: [Product]
    
    public init(platforms: [Platform], products: [Product]) {
        self.platforms = platforms
        self.products = products
    }
    
}
