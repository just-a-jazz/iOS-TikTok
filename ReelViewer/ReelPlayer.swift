//
//  ReelPlayer.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-08.
//

import Foundation
import AVFoundation

class ReelPlayer {
    let url: URL
    let player: AVPlayer

    // Used for manual looping
    private var endObserver: NSObjectProtocol?

    init(url: URL) {
        self.url = url
        self.player = AVPlayer(url: url)

        // Don’t pause at the end of the reel; we’ll manually seek
        player.actionAtItemEnd = .none

        setUpLooping()
    }

    deinit {
        print("Deinit for \(url)")
        tearDownLooping()
    }

    // MARK: - Playback API
    
    var timeControlStatus: AVPlayer.TimeControlStatus {
        player.timeControlStatus
    }

    func play() {
        print("Playing \(url)")
        player.play()
    }

    func pause() {
        player.pause()
    }

    // MARK: - Looping

    private func setUpLooping() {
        guard endObserver == nil,
              let item = player.currentItem else {
            return
        }
        
        let player = self.player  // capture player only
        
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private func tearDownLooping() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }
}
