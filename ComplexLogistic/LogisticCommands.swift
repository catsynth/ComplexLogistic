//
//  LogisticCommands.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 3/20/22.
//

import Foundation
import SwiftUI


struct LogisticCommands: Commands {
    
    @Binding var zoomReset : Action
    @Binding var zoomPrevious : Action
    
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Reset Zoom") {
                zoomReset()
            }.keyboardShortcut("0")
            Button("Previous Zoom") {
                zoomPrevious()
            }.keyboardShortcut(.delete)
        }
    }
}
