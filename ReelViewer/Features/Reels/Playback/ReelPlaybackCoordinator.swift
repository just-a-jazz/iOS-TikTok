//
//  ReelPlaybackCoordinator.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-10.
//

import Foundation
import AVFoundation

@Observable
@MainActor
class ReelPlaybackCoordinator {
    private var reels: [Reel] = []
    // Track the active reel ID for policy decisions
    private var activeReelId: String?
    // Manage a player for each reel keyed by reel.id to avoid hash/equality coupling
    private var reelPlayers = [String: ReelPlayer]()
    
    private func index(for reel: Reel) -> Int? {
        reels.firstIndex(where: { $0.id == reel.id })
    }

    private func index(for reelID: String) -> Int? {
        reels.firstIndex(where: { $0.id == reelID })
    }

    var isReadyForPlayback: Bool {
        if let activeReelId {
            return reelPlayers[activeReelId]?.isReadyToPlay ?? false
        }
        return false
    }

    func updateReels(_ newReels: [Reel]) {
        reels = newReels
        prunePlayersNotInReels()
    }

    func handleActiveReelChange(from oldID: String?, to newID: String?) {
        guard let newID,
              let newIndex = index(for: newID) else {
            return
        }

        // Change the active reel
        activeReelId = newID

        // Pause old active reel
        if let oldID,
           let oldPlayer = reelPlayers[oldID] {
            oldPlayer.pause()
        }

        guard let windowIndices = windowIndices else { return }

        // Ensure players exist for all the reels in the caching/playback window
        for index in windowIndices {
            let reel = reels[index]
            let player = ensurePlayer(for: reel)

            if index == newIndex {
                player.status = .active
            } else if index == newIndex - 1 || index == newIndex + 1 {
                player.status = .neighbor
            } else if index > newIndex + 1 {
                player.status = .prefetchFar
            } else {
                player.status = .idle
            }
        }

        // Start current reel when ready
        let newReel = reels[newIndex]
        guard let currentPlayer = reelPlayers[newReel.id] else { return }

        currentPlayer.whenReadyToPlay { [weak self] in
            guard self?.activeReelId == newID else { return }
            currentPlayer.play()
        }
    }
    
    // Build the window of reels we want to keep alive
    private var windowIndices: ClosedRange<Int>? {
        guard let activeReelId, let activeIndex = index(for: activeReelId) else { return nil }
        let lower = max(0, activeIndex - Self.prefetchBehindCount)
        let upper = min(reels.count - 1, activeIndex + Self.prefetchAheadCount)
        return lower...upper
    }

    private func isInWindow(reel: Reel) -> Bool {
        guard let windowIndices else { return true }
        guard let reelIndex = index(for: reel) else { return false }
        return windowIndices.contains(reelIndex)
    }

    func player(for reel: Reel) -> ReelPlayer? {
        reelPlayers[reel.id]
    }

    private func ensurePlayer(for reel: Reel) -> ReelPlayer {
        guard Self.poolSize > 0 else {
            fatalError("Pool size misconfigured. No reels can play without a player.")
        }

        // 1. Return a player if one has already been created for this reel
        if let existingPlayer = reelPlayers[reel.id] {
            return existingPlayer
        }

        // 2. If the pool is not full yet, create a new player and add it.
        if reelPlayers.count < Self.poolSize {
            let newPlayer = ReelPlayer(reel: reel)
            reelPlayers[reel.id] = newPlayer
            return newPlayer
        }

        // 3. Pool is full: reuse an existing player. Prefer one that is farthest from the reel.
        let victim = pickPlayerToReuse(for: reel)
        let oldReel = victim.reel

        victim.configure(for: reel)
        reelPlayers[reel.id] = victim

        reelPlayers.removeValue(forKey: oldReel.id)

        return victim
    }

    private func pickPlayerToReuse(for newReel: Reel) -> ReelPlayer {
        guard let newIndex = index(for: newReel) else {
            // Fallback: just pick any coordinator
            return reelPlayers.first!.value
        }

        // Split pool into:
        // - candidates outside the window
        // - candidates inside the window (fallback)
        let outsideWindow = reelPlayers.values.filter { player in
            !isInWindow(reel: player.reel)
        }
        let insideWindow = reelPlayers.values.filter { player in
            isInWindow(reel: player.reel)
        }

        func farthest(from targetIndex: Int, in group: [ReelPlayer]) -> ReelPlayer? {
            group.max { a, b in
                let idxA = index(for: a.reel) ?? Int.max
                let idxB = index(for: b.reel) ?? Int.max
                let distA = abs(idxA - targetIndex)
                let distB = abs(idxB - targetIndex)
                return distA < distB
            }
        }

        if let best = farthest(from: newIndex, in: outsideWindow), !outsideWindow.isEmpty {
            return best
        }

        return farthest(from: newIndex, in: insideWindow) ?? reelPlayers.first!.value
    }

    private func prunePlayersNotInReels() {
        let validIds = Set(reels.map(\.id))
        reelPlayers = reelPlayers.filter { validIds.contains($0.key) }
    }
}

// MARK: Constants for managing prefetch logic
private extension ReelPlaybackCoordinator {
    static let poolSize = 4

    static var prefetchAheadCount: Int { 2 }
    static var prefetchBehindCount: Int { 1 }
}
