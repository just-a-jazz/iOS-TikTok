//
//  ContentViewView.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ReelFeedViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            
            Home(viewModel: viewModel, safeArea: safeArea)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
