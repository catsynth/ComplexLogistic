//
//  ComplexLogisticApp.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/26/22.
//

import SwiftUI

@main
struct ComplexLogisticApp: App {
        
    @State var zoomReset : Action = {}
    @State var zoomPrevious : Action = {}
    
    var body: some Scene {
        WindowGroup {
            ContentView(zoomReset: $zoomReset, zoomPrevious: $zoomPrevious)
        }
        .commands {
            LogisticCommands(zoomReset: $zoomReset, zoomPrevious: $zoomPrevious)
        }
    }
    
}
