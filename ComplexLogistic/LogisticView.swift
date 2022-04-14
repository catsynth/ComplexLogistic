//
//  LogisticView.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/26/22.
//

import SwiftUI
import Accelerate
import simd
import ComplexModule


let defaultLowerLeft = simd_double2(x: -2, y: -2)
let defaultUpperRight = simd_double2(x: 4, y: 2)

protocol ExtendedViewDelegate {
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
}

class ExtendedView : NSImageView {
    
    var delegate : ExtendedViewDelegate? = nil
    
    override func mouseDown(with event: NSEvent) {
        delegate?.mouseDown(with: event)
    }

    
    override func mouseDragged(with event: NSEvent) {
        delegate?.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        delegate?.mouseUp(with: event)
    }
}


struct LogisticView: NSViewRepresentable {
        
    typealias NSViewType = ExtendedView

    static let tektronixGreen = NSColor(cgColor: Color.tektronixGreen.cgColor!)
    
    private static let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)
    private let view = ExtendedView(frame: LogisticView.frame)
    
    @Binding var lowerLeft : SIMD2<Double>
    @Binding var upperRight : SIMD2<Double>
    
    @Binding var isDragging : Bool
    @Binding var firstPoint : CGPoint
    @Binding var secondPoint : CGPoint
   
    @Binding var transientLowerLeft : SIMD2<Double>
    @Binding var transientUpperRight : SIMD2<Double>

    @Binding var stack : Stack<BoundingBox>
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSViewType {
        view.image = NSImage(size: CGSize(width: Self.frame.width,height: Self.frame.height))
        view.delegate = context.coordinator
        view.window?.makeFirstResponder(view)
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    
    private func convertPoint (point : NSPoint) -> NSPoint {
        var newPoint = view.convert(point, to: nil)
        //don't forget to flip
        newPoint.y = Self.frame.height - newPoint.y
        return newPoint
    }
    
    @MainActor
    func update () async {
        let horizontalStride =  (upperRight.x - lowerLeft.x) / Double(LogisticView.frame.width)
        let verticalStride = (upperRight.y - lowerLeft.y) / Double(LogisticView.frame.height)
            
        let width = Int(LogisticView.frame.width)
        let height = Int(LogisticView.frame.height)
        
        var bitmap = Bitmap(width: width,height: height)

        var aV = Array<Complex<Double>>(repeating: 0, count: width*height)
        
        for i in 0..<width {
            for j in 0..<height {
                aV[i*height+j] = Complex(lowerLeft.x+Double(i)*horizontalStride,
                                         upperRight.y-Double(j)*verticalStride)
                
            }
        }
        
        let ptr = UnsafeMutablePointer<Bool>.allocate(capacity: aV.count)
        let buffer = UnsafeMutableBufferPointer<Bool>(start: ptr, count: aV.count)
        buffer.initialize(repeating: false)
        
        await aV.concurrentMapV(chunks: 200, buffer: buffer, transform: logisticMapV)
        for i in 0..<width {
            for j in 0..<height {
                bitmap[i,j] =  buffer[i*height+j] ? Self.tektronixGreen! : NSColor.black
            }
        }
        
        view.image = NSImage(bitmap: bitmap)
    }

    private func updatePoints() -> (SIMD2<Double>,SIMD2<Double>) {
        let centerX = 0.5 * (firstPoint.x + secondPoint.x)
        let centerY = 0.5 * (2 * Self.frame.height - firstPoint.y - secondPoint.y)
        
        let width = abs(secondPoint.x - firstPoint.x)
                
        let ratio = width / Self.frame.width
        let newXWidth = (upperRight.x - lowerLeft.x) * ratio
        let newYWidth = newXWidth * 2/3
        
        let newCenterX = lowerLeft.x + centerX / Self.frame.width * abs(upperRight.x - lowerLeft.x)
        let newCenterY = lowerLeft.y + centerY / Self.frame.height * abs(upperRight.y - lowerLeft.y)
        
        let resultLeft = simd_double2(x: newCenterX - 0.5 * newXWidth, y: newCenterY - 0.5 * newYWidth)
        let resultRight = simd_double2(x: newCenterX + 0.5 * newXWidth, y: newCenterY + 0.5 * newYWidth)
        return (resultLeft,resultRight)
    }
    
    
    func reset() {
        lowerLeft = defaultLowerLeft
        upperRight = defaultUpperRight
        stack.clear()
        Task {
            await update()
        }
    }
    
    func back() {
        guard !stack.isEmpty else { return }
        let box = stack.pop()
        lowerLeft = box.lowerLeft
        upperRight = box.upperRight
        Task {
            await update()
        }
    }
        
    class Coordinator : ExtendedViewDelegate {
        
        var view : LogisticView
        
        init(_ logisticView : LogisticView) {
            self.view = logisticView
        }
        
        func mouseDown(with event: NSEvent) {
            let location = event.locationInWindow
            self.view.firstPoint = self.view.convertPoint(point: location)
        }
        
        func mouseDragged(with event: NSEvent) {
            let location = event.locationInWindow
            self.view.secondPoint = self.view.convertPoint(point: location)
            (self.view.transientLowerLeft,self.view.transientUpperRight) = self.view.updatePoints()
            self.view.isDragging = true
        }
        
        func mouseUp(with event: NSEvent) {
            self.view.isDragging = false
            let location = event.locationInWindow
            let box = BoundingBox(lowerLeft: self.view.lowerLeft, upperRight: self.view.upperRight)
            self.view.stack.push(box)
            self.view.secondPoint = self.view.convertPoint(point: location)
            (self.view.lowerLeft,self.view.upperRight) = self.view.updatePoints()
            Task {
                await self.view.update()
            }
        }
    }
}
