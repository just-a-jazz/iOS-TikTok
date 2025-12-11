//
//  Reel.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-07.
//

import Foundation

struct Reel: Identifiable, Equatable {
    let id = UUID().uuidString
    var url: URL
    var isLiked: Bool = false
}
