//
//  ReelPlayer.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-08.
//

import Foundation
import AVFoundation

@Observable
class ReelPlayer: ObservableObject {
    enum Status {
        case idle
        case prefetchFar   // 2+ steps ahead
        case neighbor      // previous / next
        case active
    }
    
    private(set) var reel: Reel
    private(set) var player: AVPlayer

    private(set) var isReadyToPlay = false
    var onReadyToPlay: (() -> Void)?
    
    var status: Status = .idle {
        didSet { applyStatus() }
    }
    
    private var playerReadinessObservation: NSKeyValueObservation?
    private var endOfReelObserver: NSObjectProtocol?

    init(reel: Reel) {
        self.reel = reel
        self.player = AVPlayer(url: reel.url)

        // Don’t pause at the end of the reel; we’ll manually loop
        player.actionAtItemEnd = .none

        observePlayerReadiness()
        setUpLooping()
    }
    

    // MARK: - Playback API
    
    var timeControlStatus: AVPlayer.TimeControlStatus {
        player.timeControlStatus
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }
    
    func whenReadyToPlay(_ action: @escaping () -> Void) {
        if isReadyToPlay {
            action()
        } else {
            // Capture latest user intent
            onReadyToPlay = action
        }
    }
    
    // MARK: - Looping

    private func setUpLooping() {
        guard endOfReelObserver == nil,
              let item = player.currentItem else {
            return
        }
        
        endOfReelObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }
    }

    private func tearDownLooping() {
        if let observer = endOfReelObserver {
            NotificationCenter.default.removeObserver(observer)
            endOfReelObserver = nil
        }
    }
    
    // MARK: - Prefetch Logic
    
    private func observePlayerReadiness() {
        guard let item = player.currentItem else { return }
        
        playerReadinessObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            
            if item.status == .readyToPlay {
                self.isReadyToPlay = true
                if let callback = self.onReadyToPlay {
                    self.onReadyToPlay = nil
                    callback()
                }
            }
        }
    }
    
    private func applyStatus() {
        guard let item = player.currentItem else { return }
        
        switch status {
        case .active:
            // Prioritize smooth playback for the active reel onscreen
            item.preferredForwardBufferDuration = ReelPlayerStatusConfig.activeBufferDuration
            item.preferredPeakBitRate = ReelPlayerStatusConfig.activePeakBitRate
        case .neighbor:
            // Ensure neighbor of current reel are at good enough settings
            item.preferredForwardBufferDuration = ReelPlayerStatusConfig.neighborBufferDuration
            item.preferredPeakBitRate = ReelPlayerStatusConfig.neighborPeakBitRate
        case .prefetchFar:
            // Warm up further away reels with judicious settings
            item.preferredForwardBufferDuration = ReelPlayerStatusConfig.prefetchFarBufferDuration
            item.preferredPeakBitRate = ReelPlayerStatusConfig.prefetchFarPeakBitRate
        case .idle:
            // Stop buffering for reels that are far away enough
            item.preferredForwardBufferDuration = 0
            player.pause()
        }
    }
    
    // MARK: - Re-use Logic
    
    func configure(for newReel: Reel) {
        // If player is already configured for this reel, no work needed.
        if reel.url == newReel.url {
            return
        }
        
        prepareForItemSwap()
        resetReadinessState()
        
        // Point to the new reel.
        reel = newReel
        
        // Attach new item.
        let item = AVPlayerItem(url: reel.url)
        player.replaceCurrentItem(with: item)
        
        // Re-establish readiness + looping.
        observePlayerReadiness()
        setUpLooping()
    }
    
    private func prepareForItemSwap() {
        // Stop KVO
        playerReadinessObservation?.invalidate()
        playerReadinessObservation = nil
        
        // Stop looping notifications for current reel
        tearDownLooping()
    }
    
    private func resetReadinessState() {
        isReadyToPlay = false
        onReadyToPlay = nil
    }
}
