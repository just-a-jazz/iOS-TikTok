//
//  ReelFeedViewModel.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-10.
//

import Foundation

@Observable
@MainActor
class ReelFeedViewModel {
    private let service: ReelServiceProtocol = ReelService()
    private let playbackCoordinator: ReelPlaybackCoordinator = ReelPlaybackCoordinator()

    var reels: [Reel] = []
    // Track the active reel ID for policy decisions
    var activeReelId: String?
    var isTyping = false
    var isLoading = false
    var errorMessage: String?

    var isReadyForPlayback: Bool {
        playbackCoordinator.isReadyForPlayback
    }

    func loadReels() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchReels()
            reels = fetched
            playbackCoordinator.updateReels(fetched)
            if activeReelId == nil {
                activeReelId = fetched.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setActiveReel(from oldID: String?, to newID: String?) {
        activeReelId = newID
        playbackCoordinator.handleActiveReelChange(from: oldID, to: newID)
    }

    func player(for reel: Reel) -> ReelPlayer? {
        playbackCoordinator.player(for: reel)
    }

    func toggleLike(for reelId: String) {
        guard let index = reels.firstIndex(where: { $0.id == reelId }) else { return }
        reels[index].isLiked.toggle()
    }

    func handleComposerFocus(_ focused: Bool, reel: Reel) {
        isTyping = focused
        let player = playbackCoordinator.player(for: reel)
        if focused {
            player?.pause()
        } else {
            player?.play()
        }
    }

    func handleTap(on reel: Reel) {
        guard let player = playbackCoordinator.player(for: reel) else { return }
        switch player.timeControlStatus {
        case .paused:
            player.play()
        case .waitingToPlayAtSpecifiedRate:
            break
        case .playing:
            player.pause()
        @unknown default:
            break
        }
    }

    func handleSend(_ text: String, for reel: Reel) {
        // Placeholder for message pipeline
        print("Send \"\(text)\" on reel \(reel.id)")
    }
}
