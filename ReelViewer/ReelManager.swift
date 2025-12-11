//
//  ReelManager.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import Foundation

struct CDNResponse: Codable {
    let videos: [String]
}

@Observable
class ReelManager {
    static let cdnUrl = URL(string: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/manifest.json")!
    var reels = [Reel]()
    
    func loadReels() async throws {
        let (data, _) = try await URLSession.shared.data(from: Self.cdnUrl)
        
        guard let json = try? JSONDecoder().decode(CDNResponse.self, from: data) else {
            print("Couldn't decode JSON for reels")
            return
        }

        for video in json.videos {
            guard let reelUrl = URL(string: video) else {
                print("Couldn't create URL for \(video)")
                continue
            }
            reels.append(Reel(url: reelUrl))
        }
    }
    
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
    
    func playerForRender(for reel: Reel) -> ReelPlayer? {
        reelPlayers[reel.id]
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

        // Ensure players exist for all the reels in the caching/playback window
        guard let windowIndices = windowIndices else { return }
        
        for index in windowIndices {
            let reel = reels[index]
            let player = self.ensurePlayer(for: reel)

            if index == newIndex {
                player.status = .active        // current
            } else if index == newIndex - 1 || index == newIndex + 1 {
                player.status = .neighbor      // immediate up/down
            } else if index > newIndex + 1 {
                player.status = .prefetchFar   // 2+ ahead
            } else {
                player.status = .idle
            }
        }
        
        // Start current reel when ready
        let newReel = reels[newIndex]
        guard let currentPlayer = reelPlayers[newReel.id] else { return }
        
        currentPlayer.whenReadyToPlay { [weak self] in
            // Make sure this reel is still active when readiness fires
            guard self?.activeReelId == newID else { return }
            currentPlayer.play()
        }
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
        
        // Reconfigure the victim player for the new reel.
        victim.configure(for: reel)
        // Map new reel -> victim.
        reelPlayers[reel.id] = victim
        
        // Remove old mapping for the victim's reelID.
        reelPlayers.removeValue(forKey: oldReel.id)
        
        return victim
    }
    
    /// Choose a player from the pool to reuse when the pool is full.
    private func pickPlayerToReuse(for newReel: Reel) -> ReelPlayer {
        guard let newIndex = index(for: newReel) else {
            // Fallback: just pick any coordinator;
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
        
        // Prefer a player whose reel is furthest away from the new reel.
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
        
        // Fallback: reuse from inside the window (this is rare with sensible prefetch settings).
        return farthest(from: newIndex, in: insideWindow) ?? reelPlayers.first!.value
    }
}

// MARK: Constants for managing prefetch logic
extension ReelManager {
    private static let poolSize = 4
    
    private static var prefetchAheadCount: Int { 2 }   // Current + next 2
    private static var prefetchBehindCount: Int { 1 }  // One behind
}
