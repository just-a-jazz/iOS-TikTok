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
    @Binding var reel: Reel
    let reelPlayer: ReelPlayer?
    
    @Binding var isTyping: Bool
    @State private var messageText = ""
    @State private var composerFocused = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let reelPlayer {
                ZStack {
                    ReelPlayerView(player: reelPlayer.player)
                        // prevent highlighting of text in reels
                        .allowsHitTesting(false)
                    Color.black
                        .opacity(composerFocused ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.2), value: composerFocused)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: handleTapGesture)
                }
            } else {
                Color.black.ignoresSafeArea()
            }
            
            InlineMessagingBar(
                text: $messageText,
                isFocused: $composerFocused,
                isLiked: $reel.isLiked,
                onFocusChange: handleFocusChange,
                onSend: handleSend
            )
            // Nudge the bar slightly above the keyboard/safe area when focused
            .padding(.bottom, !composerFocused ? safeArea.bottom : safeArea.bottom + 12)
            .padding(.horizontal, 8)
        }
        .ignoresSafeArea()
        .onChange(of: composerFocused) { _, newValue in
            // Extra safety to ensure pause/resume even if focus callback timing varies
            handleFocusChange(newValue)
        }
    }
    
    private func handleTapGesture() {
        if composerFocused {
            // Dismiss keyboard / blur input when tapping the reel
            composerFocused = false
            return
        }
        
        switch reelPlayer?.timeControlStatus {
        case .paused:
            reelPlayer?.play()
        case .waitingToPlayAtSpecifiedRate:
            print("Buffering...")
            break
        case .playing:
            reelPlayer?.pause()
        default:
            break
        }
    }
    
    private func handleFocusChange(_ focused: Bool) {
        isTyping = focused
        if focused {
            reelPlayer?.pause()
        } else {
            reelPlayer?.play()
        }
    }
    
    private func handleSend(_ text: String) {
        /// placeholder for the message pipeline
        print("Send \"\(text)\" on reel \(reel.id)")
    }
}

#Preview {
    ContentView()
}
