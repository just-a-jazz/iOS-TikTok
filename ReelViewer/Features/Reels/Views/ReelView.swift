//
//  ReelView.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import AVKit
import SwiftUI

struct ReelView: View {
    let safeArea: EdgeInsets
    @Binding var reel: Reel
    let reelPlayer: ReelPlayer?

    @State private var messageText = ""
    @State private var composerFocused = false

    var onTap: () -> Void
    var onFocusChange: (Bool) -> Void
    var onSend: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            reelPlayerLayer
            
            InlineMessagingBar(
                text: $messageText,
                isFocused: $composerFocused,
                isLiked: $reel.isLiked,
                onFocusChange: onFocusChange,
                onSend: onSend
            )
            // Shift the bar slightly above the keyboard/safe area when focused
            .padding(.bottom, !composerFocused ? safeArea.bottom : safeArea.bottom + 12)
            .padding(.horizontal, 8)
        }
        .ignoresSafeArea()
    }
    
    private func handleTapGesture() {
        if composerFocused {
            // Dismiss keyboard / blur input when tapping the reel
            composerFocused = false
            return
        }

        onTap()
    }

    @ViewBuilder
    private var reelPlayerLayer: some View {
        if let reelPlayer {
            ReelPlayerView(
                player: reelPlayer.player,
                composerFocused: composerFocused,
                onTap: handleTapGesture
            )
        } else {
            Color.black.ignoresSafeArea()
        }
    }
}

private struct ReelPlayerView: View {
    let player: AVPlayer
    let composerFocused: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            ReelPlayerUIView(player: player)
                // prevent highlighting of text in reels
                .allowsHitTesting(false)
            Color.black
                .opacity(composerFocused ? 0.8 : 0)
                .animation(.easeOut(duration: 0.2), value: composerFocused)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        }
    }
}

#Preview {
    ContentView()
}
