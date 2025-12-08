//
//  Home.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import SwiftUI

struct Home: View {
    let size: CGSize
    let safeArea: EdgeInsets
    
    @State private var reelManager = ReelManager()
    @State private var scrollPosition: String?
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0){
                ForEach(reelManager.reels) { reel in
                    ReelView(size: size, safeArea: safeArea, reel: reel)
//                        .frame(maxWidth: .infinity)
//                        .containerRelativeFrame(.vertical)
                        .id(reel.id)
                        .containerRelativeFrame([.vertical, .horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .onChange(of: scrollPosition) { _, newValue in
            print("Changed scroll position to \(newValue ?? "unknown")")
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .background(.black)
        .environment(\.colorScheme, .dark)
        .scrollPosition(id: $scrollPosition)
        .onAppear {
            Task {
                try await reelManager.loadReels()
            }
        }
        
    }
}

#Preview {
    ContentView()
}
