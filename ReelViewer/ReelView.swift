//
//  ReelView.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import AVKit
import SwiftUI

struct ReelView: View {
    let size: CGSize
    let safeArea: EdgeInsets
    let reel: Reel
    let reelPlayer: ReelPlayer?
    
    init(size: CGSize, safeArea: EdgeInsets, reel: Reel, reelPlayer: ReelPlayer?) {
        self.size = size
        self.safeArea = safeArea
        self.reel = reel
        self.reelPlayer = reelPlayer
    }
    
    var body: some View {
        if let reelPlayer {
            ReelPlayerView(player: reelPlayer.player)
                .onTapGesture(perform: reelPlayer.handleTapGesture)
        } else {
            Color.black
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
