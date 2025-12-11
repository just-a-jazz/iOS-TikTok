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
    // Track the active reel ID and last ready reel ID for policy decisions
    var activeReelId: String?
    private var lastReadyReelId: String?
    
    var isTyping = false
    var isLoading = false
    var errorMessage: String?

    func indexOfReel(_ reelId: String) -> Int? {
        reels.firstIndex { $0.id == reelId }
    }

    func isReelReady(for reelId: String) -> Bool {
        guard let reel = reels.first(where: { $0.id == reelId }),
              let player = playbackCoordinator.player(for: reel) else {
            return false
        }
        return player.isReadyToPlay
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

    /// Resolves an attempted active-reel change. Returns a fallback ID if the change should be blocked.
    func resolveActiveReelChange(from oldID: String?, to newID: String?) -> String? {
        guard let newID else { return nil }

        if shouldBlockChange(to: newID) {
            return oldID ?? lastReadyReelId
        }

        applyActiveReelChange(from: oldID, to: newID)
        return nil
    }

    private func shouldBlockChange(to newID: String) -> Bool {
        guard let anchorID = lastReadyReelId ?? activeReelId,
              let anchorIndex = indexOfReel(anchorID),
              let newIndex = indexOfReel(newID) else {
            return false
        }
        
        // If the new reel isn't ready, block access to reels further than the non-ready reel.
        let distance = abs(newIndex - anchorIndex)
        let isNewReady = isReelReady(for: newID)

        return !isNewReady && distance > 1
    }
    
    private func applyActiveReelChange(from oldID: String?, to newID: String) {
        activeReelId = newID
        playbackCoordinator.handleActiveReelChange(from: oldID, to: newID) { [weak self] in
            self?.updateLastReadyAnchorIfNeeded()
        }
    }

    private func updateLastReadyAnchorIfNeeded() {
        guard let currentId = activeReelId else {
            return
        }
        lastReadyReelId = currentId
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
