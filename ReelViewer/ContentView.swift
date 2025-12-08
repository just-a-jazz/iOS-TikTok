//
//  ContentViewView.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let safeArea = geometry.safeAreaInsets
            
            Home(size: size, safeArea: safeArea)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
