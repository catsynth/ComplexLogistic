//
//  Array+Concurrent.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/27/22.
//

import Foundation

func synchronized(sync: AnyObject, fn: ()->()) {
  objc_sync_enter(sync)
  fn()
  objc_sync_exit(sync)
}


extension Array {

    typealias T = Array.Element
    
    
    func concurrentMap<U>(chunks: Int, transform: @escaping (T) -> U) async -> Array<U> {
        
        // populate the array
        let r = transform(self[0] as T)
        let buffer = UnsafeMutableBufferPointer<U>.allocate(capacity: self.count)
        buffer.initialize(repeating: r)
        
        return await withTaskGroup(of: Void.self) { group in
            for startIndex in stride(from: 1, through: self.count, by: chunks) {
                group.addTask {
                    let endIndex = Swift.min(startIndex + chunks, self.count)
                    let chunkedRange = self[startIndex..<endIndex]
                    
                    for (index, item) in chunkedRange.enumerated() {
                        buffer[index + startIndex] = transform(item)
                    }
                }
            }
            for await _ in group {}

            return buffer.map {$0}
        }
    }
    
    func concurrentMapV<U>(chunks: Int,
                           buffer : UnsafeMutableBufferPointer<U>,
                           transform: @escaping (ArraySlice<T>) -> [U]) async {
        
        
        await withTaskGroup(of: Void.self) { group in
            for startIndex in stride(from: 0, through: self.count-1, by: chunks) {
                group.addTask {
                    let endIndex = Swift.min(startIndex + chunks, self.count)
                    let chunkedRange = self[startIndex..<endIndex]
                    let result = transform (chunkedRange)
                    for (index,value) in result.enumerated() {
                        buffer[startIndex+index] = value
                    }
                }
            }
            
            for await _ in group {}
        }
    }
}
