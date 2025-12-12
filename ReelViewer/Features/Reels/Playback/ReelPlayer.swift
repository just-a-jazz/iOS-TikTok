//
//  ReelPlayer.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-08.
//

import Foundation
import AVFoundation

@Observable
class ReelPlayer {
    enum Status {
        case idle
        case prefetchFar   // 2+ steps ahead
        case neighbor      // previous / next
        case active
    }
    
    private(set) var reel: Reel
    private(set) var player: AVQueuePlayer
    
    private(set) var isReadyToPlay = false
    var onReadyToPlay: (() -> Void)?
    
    var status: Status = .idle {
        didSet { applyStatus() }
    }
    
    private var playerReadinessObservation: NSKeyValueObservation?
    private var endOfReelObserver: NSObjectProtocol?
    
    init(reel: Reel) {
        self.reel = reel
        self.player = AVQueuePlayer()
        self.player.actionAtItemEnd = .advance
        
        buildQueueForReel()
        observePlayerReadiness()
        setUpLooping()
    }
    
    private func buildQueueForReel() {
        let current = makeItem(url: reel.url)
        player.insert(current, after: nil)
    }
    
    private func makeItem(url: URL, withLoopingBuffer: Bool = false) -> AVPlayerItem {
        let item = AVPlayerItem(url: url)
        applyQualitySettings(for: item)
        if withLoopingBuffer {
            // Override the forward buffer if item is queued in advance for looping purposes
            item.preferredForwardBufferDuration = PrefetchConfig.nextLoopForwardBufferDuration
        }
        return item
    }
    
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
    
    // MARK: - Looping
    
    private func setUpLooping() {
        guard endOfReelObserver == nil else {
            return
        }
        
        endOfReelObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Ensure 2-item loop monitoring is only used for active reel
            guard self.status == .active else { return }
            
            // Append one new “next loop” item so we always have 2
            let tail = self.makeItem(url: self.reel.url, withLoopingBuffer: true)
            if let last = self.player.items().last {
                self.player.insert(tail, after: last)
            } else {
                self.player.insert(tail, after: nil)
            }
            
            // Make sure the new current item has appropriate settings
            self.applyStatus()
        }
    }
    
    private func tearDownLooping() {
        if let observer = endOfReelObserver {
            NotificationCenter.default.removeObserver(observer)
            endOfReelObserver = nil
        }
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
    
    // MARK: - Reel Quality and Queue Management
    
    private func applyStatus() {
        guard let item = player.currentItem else { return }
        
        applyQualitySettings(for: item)
        
        switch status {
        // Ensure current and neighboring reels have 2 item queues for looping
        case .active, .neighbor:
            ensureTwoItemsInQueue()
        default:
            player.pause()
            trimQueueToSingleItem()
        }
    }
    
    private func applyQualitySettings(for item: AVPlayerItem) {
        switch status {
        case .active:
            // Prioritize high quality playback for the active reel onscreen
            item.preferredForwardBufferDuration = PrefetchConfig.activeBufferDuration
            item.preferredPeakBitRate = PrefetchConfig.activePeakBitRate
        case .neighbor:
            // Ensure neighbor of current reel are at good enough settings
            item.preferredForwardBufferDuration = PrefetchConfig.neighborBufferDuration
            item.preferredPeakBitRate = PrefetchConfig.neighborPeakBitRate
        case .prefetchFar:
            // Warm up further away reels with judicious settings
            item.preferredForwardBufferDuration = PrefetchConfig.prefetchFarBufferDuration
            item.preferredPeakBitRate = PrefetchConfig.prefetchFarPeakBitRate
        case .idle:
            // Stop buffering for reels that are far away enough
            item.preferredForwardBufferDuration = 0
        }
    }
    
    private func ensureTwoItemsInQueue() {
        let items = player.items()
        
        if items.count == 1 {
            let next = makeItem(url: reel.url, withLoopingBuffer: true)
            player.insert(next, after: items[0])
        }
        
        // Safety: never allow > 2
        while player.items().count > 2 {
            player.remove(player.items().first!)
        }
    }
    
    private func trimQueueToSingleItem() {
        let items = player.items()
        guard items.count > 1 else { return }
        for item in items.dropFirst() { player.remove(item) }
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
        
        // Re-establish player queue
        player.removeAllItems()
        buildQueueForReel()
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
