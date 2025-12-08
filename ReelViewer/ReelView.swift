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
    
    let player: AVPlayer
    
    init(size: CGSize, safeArea: EdgeInsets, reel: Reel) {
        self.size = size
        self.safeArea = safeArea
        self.reel = reel
        self.player = AVPlayer(url: reel.url)
        print("Created player for \(reel.url)")
    }
    
    var body: some View {
        CustomVideoPlayer(player: player)
            .onAppear {
                print("Changed position to \(reel.url)")
                player.play()
            }
            .onTapGesture {
                switch player.timeControlStatus {
                case .paused:
                    player.play()
                case .waitingToPlayAtSpecifiedRate:
                    print("WE ARE HERE")
                    break
                case .playing:
                    player.pause()
                default:
                    break
                }
            }
//            .onDisappear {
//                print("Changed position from \(reel.url)")
//                player.pause()
//            }
    }
}

#Preview {
    ContentView()
}
