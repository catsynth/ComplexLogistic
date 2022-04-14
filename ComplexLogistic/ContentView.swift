//
//  ContentView.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/26/22.
//

import SwiftUI

struct ContentView: View {

    @State private var lowerLeft = defaultLowerLeft
    @State private var upperRight = defaultUpperRight

    @State private var transientLowerLeft = defaultLowerLeft
    @State private var transientUpperRight = defaultUpperRight

    @State private var stack = Stack<BoundingBox>()
    
    @State private var isDragging = false
    @State private var firstPoint = CGPoint()
    @State private var secondPoint = CGPoint()
    
    
    @Binding var zoomReset : Action
    @Binding var zoomPrevious : Action
            
    var body: some View {
   
        let logisticView = LogisticView(lowerLeft: $lowerLeft,
                                        upperRight: $upperRight,
                                        isDragging: $isDragging,
                                        firstPoint: $firstPoint,
                                        secondPoint: $secondPoint,
                                        transientLowerLeft: $transientLowerLeft,
                                        transientUpperRight: $transientUpperRight,
                                        stack : $stack)
        
        VStack {
            HStack {
                if isDragging {
                    Text("Lower Left: \(transientLowerLeft.x), \(transientLowerLeft.y)")
                        .padding(20)
                        .foregroundColor(.white)
                        .font(.title)
                    Text("Upper Right: \(transientUpperRight.x), \(transientUpperRight.y)")
                        .padding(20)
                        .foregroundColor(.white)
                        .font(.title)
                } else {
                    Text("Lower Left: \(lowerLeft.x), \(lowerLeft.y)")
                        .padding(20)
                        .foregroundColor(.tektronixGreen)
                        .font(.title)
                    Text("Upper Right: \(upperRight.x), \(upperRight.y)")
                        .padding(20)
                        .foregroundColor(.tektronixGreen)
                        .font(.title)

                }
            }.background(Color.black)
                .padding([.bottom],-20)
            ZStack {
                logisticView
                    .frame(width: 1200, height: 800)
                    .onAppear(perform: {
                        zoomReset = { logisticView.reset() }
                        zoomPrevious = { logisticView.back() }
                        Task {
                            await logisticView.update()
                        }
                    })
                                        
                if isDragging {
                    let width = abs(firstPoint.x - secondPoint.x)
                    let height = abs(firstPoint.y - secondPoint.y)
                    let x = min(firstPoint.x,secondPoint.x) + 0.5 * width
                    let y = min(firstPoint.y,secondPoint.y) + 0.5 * height
                    
                    Rectangle()
                        .stroke(lineWidth: 5)
                        .fill(.white)
                        .frame(width: width, height: height, alignment: .topLeading)
                        .position(x: x, y: y)
                }
            }
        }.background(Color.black)
        
    }
}

