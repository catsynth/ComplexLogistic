//
//  Stack.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 3/22/22.
//

import Foundation

struct Stack<Element> {
    var items = [Element]()
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    mutating func clear() {
        items = [Element]()
    }
    
    var isEmpty : Bool { return items.isEmpty }
}
