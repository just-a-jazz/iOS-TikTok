//
//  ReelService.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-10.
//

import Foundation

struct CDNResponse: Codable {
    let videos: [String]
}

protocol ReelServiceProtocol {
    func fetchReels() async throws -> [Reel]
}

struct ReelService: ReelServiceProtocol {
    static let cdnUrl = URL(string: "https://cdn.dev.airxp.app/AgentVideos-HLS-Progressive/manifest.json")!

    func fetchReels() async throws -> [Reel] {
        let (data, _) = try await URLSession.shared.data(from: Self.cdnUrl)
        let response = try JSONDecoder().decode(CDNResponse.self, from: data)
        return response.videos.compactMap { URL(string: $0) }.map { Reel(url: $0) }
    }
}
