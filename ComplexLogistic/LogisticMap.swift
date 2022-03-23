//
//  LogisticMap.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 3/21/22.
//

import Foundation
import ComplexModule
import Accelerate

// the simple version

func logisticMap (_ a : Complex<Double>) -> Bool {
    let iterations = 512

    var i = 0
    var z = Complex<Double>(0.5,0.0)
    while i <= iterations {
        z = a * z * (1 - z)
        i += 1
        if z.real * z.real + z.imaginary * z.imaginary > 1 {
            break
        }
        
    }
    return i >= iterations

}



// the very vectorized version

func logisticMapV (_ a : ArraySlice<Complex<Double>>) -> [Bool]  {
    let iterations = 400
            
    let size = a.count

    let a_r = Array<Double>(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        for i in 0..<size {
            buffer[i] = a[a.startIndex + i].real
        }
        initializedCount = size
    }
    let a_i = Array<Double>(unsafeUninitializedCapacity: size) { buffer, initializedCount in
        for i in 0..<size {
            buffer[i] = a[a.startIndex + i].imaginary
        }
        initializedCount = size
    }

    
    var z_r = Array<Double>(repeating: 0.5, count: size)
    var z_i = Array<Double>(repeating: 0.0, count: size)
    var j = 0

    while j <= iterations {
        let zSquared_r = vDSP.subtract(multiplication: (z_r, z_r), multiplication: (z_i, z_i))
        let zSquared_i = vDSP.multiply(2.0,vDSP.multiply(z_r, z_i))
        z_r = vDSP.subtract(z_r, zSquared_r)
        z_i = vDSP.subtract(z_i, zSquared_i)
        let r_r = vDSP.subtract(multiplication:(z_r, a_r),multiplication:(z_i, a_i))
        let r_i = vDSP.add(multiplication:(z_r, a_i),multiplication:(z_i,a_r))
        z_r = r_r
        z_i = r_i
        j += 1
    }
    
    let zNorm = vDSP.add(multiplication: (z_r, z_r),multiplication: (z_i, z_i))
    return zNorm.map { $0 <= 1 }
}
