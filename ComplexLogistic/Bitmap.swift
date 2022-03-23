//
//  Bitmap.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/26/22.
//

import Foundation
import AppKit

struct Bitmap {
    let width: Int
    let height: Int    
    var imageRep : NSBitmapImageRep? = nil
    
    
    subscript(x: Int, y: Int) -> NSColor {
        get {
            let p = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            imageRep?.getPixel(p, atX: x, y: y)
            return NSColor.black
        }
        set {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            if newValue.colorSpace == .genericGamma22Gray {
                var white: CGFloat = 0
                newValue.getWhite(&white, alpha: &alpha)
                red = white
                green = white
                blue = white
            } else {
                newValue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            }
            let R = Int(red*255)
            let G = Int(green*255)
            let B = Int(blue*255)
            let A = Int(alpha*255)
            var pixel = [R,G,B,A]
            imageRep?.setPixel(&pixel, atX: x, y: y)
        }
    }
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let bytesPerPixel = 4
        let samplesPerPixel = 4
        let bytesPerSample = 1
        let bytesPerRow = self.width * bytesPerPixel
        imageRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                    pixelsWide: width,
                                    pixelsHigh: height,
                                    bitsPerSample: bytesPerSample * 8,
                                    samplesPerPixel: samplesPerPixel,
                                    hasAlpha: true,
                                    isPlanar: false,
                                    colorSpaceName: .calibratedRGB,
                                    bitmapFormat: [.alphaNonpremultiplied,.thirtyTwoBitLittleEndian],
                                    bytesPerRow: bytesPerRow,
                                    bitsPerPixel: bytesPerPixel * 8)
    }

}

extension NSImage {
    convenience init?(bitmap: Bitmap) {
    
        guard let cgImage = bitmap.imageRep?.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage, size: .zero)
    }
}
