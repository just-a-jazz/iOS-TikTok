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
    
    @State var player: AVPlayer
    @Binding var activeReelId: String?
    
    init(size: CGSize, safeArea: EdgeInsets, reel: Reel, activeReelId: Binding<String?>) {
        self.size = size
        self.safeArea = safeArea
        self.reel = reel
        
        self._player = State(initialValue: AVPlayer(url: reel.url))
        self._activeReelId = activeReelId
    }
    
    var body: some View {
        ReelPlayerView(player: player)
            .onChange(of: activeReelId) {
                guard let activeReelId else { return }

                if activeReelId == self.reel.id {
                    player.play()
                } else {
                    player.pause()
                }
            }
            .onTapGesture {
                switch player.timeControlStatus {
                case .paused:
                    player.play()
                case .waitingToPlayAtSpecifiedRate:
                    print("Buffering...")
                    break
                case .playing:
                    player.pause()
                default:
                    break
                }
            }
    }
}

#Preview {
    ContentView()
}
