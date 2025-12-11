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
    
    @State private var isTyping = false
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach($reelManager.reels) { $reel in
                    ReelView(
                        size: size,
                        safeArea: safeArea,
                        reel: $reel,
                        reelPlayer: reelManager.playerForRender(for: reel),
                        isTyping: $isTyping
                    )
                    .id(reel.id)
                    .containerRelativeFrame([.vertical, .horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $activeReelId)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .background(.black)
        .onAppear {
            Task {
                try await reelManager.loadReels()
                if activeReelId == nil,
                   let first = reelManager.reels.first {
                    activeReelId = first.id
                }
            }
        }
        .onChange(of: activeReelId) { oldReelId, newReelId in
            reelManager.handleActiveReelChange(from: oldReelId, to: newReelId)
        }
        .scrollDisabled(!reelManager.isReadyForPlayback || isTyping)
    }
}

#Preview {
    ContentView()
}
