//
//  Stack.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 3/22/22.
//

import Foundation

class Stack<Element> {
    private var items = [Element]()
    func push(_ item: Element) {
        items.append(item)
    }
    func pop() -> Element {
        return items.removeLast()
    }
    func clear() {
        items = [Element]()
    }
    
    var isEmpty : Bool { return items.isEmpty }
}
