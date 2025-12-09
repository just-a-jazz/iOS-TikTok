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
    @State private var activeReelId: String?
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(reelManager.reels) { reel in
                    ReelView(
                        size: size,
                        safeArea: safeArea,
                        reel: reel,
                        reelPlayer: reelManager.player(for: reel),
                        activeReelId: $activeReelId
                    )
//                        .frame(maxWidth: .infinity)
//                        .containerRelativeFrame(.vertical)
                        .id(reel.id)
                        .containerRelativeFrame([.vertical, .horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .background(.black)
        .environment(\.colorScheme, .dark)
        .scrollPosition(id: $activeReelId)
        .onAppear {
            Task {
                try await reelManager.loadReels()
            }
        }
        .onChange(of: reelManager.reels) {
            if activeReelId == nil,
               let first = reelManager.reels.first {
                activeReelId = first.id
            }
        }
        
    }
}

#Preview {
    ContentView()
}
