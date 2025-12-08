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
        
        if let json = try? JSONDecoder().decode(CDNResponse.self, from: data) {
            for video in json.videos {
                if let reelUrl = URL(string: video) {
                    print("Downloaded reel for \(reelUrl)")
                    reels.append(Reel(url: reelUrl))
                } else {
                    print("Couldn't create URL for \(video)")
                }
            }
        } else {
            print("Couldn't decode JSON for reels")
        }
        
    }
}
