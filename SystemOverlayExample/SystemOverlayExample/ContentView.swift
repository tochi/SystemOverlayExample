//
//  ContentView.swift
//  SystemOverlayExample
//
//  Created by Tomoyuki Tochihira on 2024/10/21.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    var body: some View {
        VStack {
            ToggleImmersiveSpaceButton()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
