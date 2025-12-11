//
//  Home.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import SwiftUI

struct Home: View {
    @Bindable var viewModel: ReelFeedViewModel
    let safeArea: EdgeInsets
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach($viewModel.reels) { $reel in
                    ReelView(
                        safeArea: safeArea,
                        reel: $reel,
                        reelPlayer: viewModel.player(for: reel),
                        onTap: { viewModel.handleTap(on: reel) },
                        onFocusChange: { focused in
                            viewModel.handleComposerFocus(focused, reel: reel)
                        },
                        onSend: { text in
                            viewModel.handleSend(text, for: reel)
                        }
                    )
                    .id(reel.id)
                    .containerRelativeFrame([.vertical, .horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $viewModel.activeReelId)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .background(.black)
        .onAppear {
            Task {
                await viewModel.loadReels()
            }
        }
        .onChange(of: viewModel.activeReelId) { oldReelId, newReelId in
            handleActiveReelChange(from: oldReelId, to: newReelId)
        }
        .scrollDisabled(viewModel.isTyping || !viewModel.hasReadyAnchor)
    }

    private func handleActiveReelChange(from oldId: String?, to newId: String?) {
        guard let newId else { return }

        if let fallback = viewModel.resolveActiveReelChange(from: oldId, to: newId) {
            withAnimation {
                viewModel.activeReelId = fallback
            }
        }
    }
}

#Preview {
    ContentView()
}
