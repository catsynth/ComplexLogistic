//
//  Memoize.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 3/1/22.
//

import Foundation


struct Memoize<T> {
    
    let constructor : () -> T
    
    private var cached : T? = nil
    
    public mutating func get() -> T {
        if cached != nil { return cached! }
        cached = constructor()
        return cached!
    }
    
    public init (_ aConstructor : @escaping () -> T) {
        constructor = aConstructor
    }
}
