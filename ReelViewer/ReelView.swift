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
    let reelPlayer: ReelPlayer
    
    @Binding var activeReelId: String?
    
    init(size: CGSize, safeArea: EdgeInsets, reel: Reel, reelPlayer: ReelPlayer, activeReelId: Binding<String?>) {
        self.size = size
        self.safeArea = safeArea
        self.reel = reel
        
        // Create a stable Playback Coordinator instance per ReelView identity
        self.reelPlayer = reelPlayer
        self._activeReelId = activeReelId
    }
    
    var body: some View {
        ReelPlayerView(player: reelPlayer.player)
            .onChange(of: activeReelId) {
                guard let activeReelId else { return }

                if activeReelId == self.reel.id {
                    reelPlayer.play()
                } else {
                    reelPlayer.pause()
                }
            }
            .onTapGesture {
                switch reelPlayer.timeControlStatus {
                case .paused:
                    reelPlayer.play()
                case .waitingToPlayAtSpecifiedRate:
                    print("Buffering...")
                    break
                case .playing:
                    reelPlayer.pause()
                @unknown default:
                    break
                }
            }
    }
}

#Preview {
    ContentView()
}
