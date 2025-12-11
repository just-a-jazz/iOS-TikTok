//
//  PrefetchConfig.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-10.
//

import Foundation

struct PrefetchConfig {
    // Pool size must be big enough to accomodate prefetching
    static let playerPoolSize = 5

    static var prefetchAheadCount: Int { 2 }
    static var prefetchBehindCount: Int { 2 }
    
    static let activeBufferDuration: TimeInterval = 10     // seconds
    static let activePeakBitRate: Double = 0               // no cap (best available)

    static let neighborBufferDuration: TimeInterval = 7
    static let neighborPeakBitRate: Double = 0

    static let prefetchFarBufferDuration: TimeInterval = 5
    static let prefetchFarPeakBitRate: Double = 4_000_000  // ~4 Mbps
}
