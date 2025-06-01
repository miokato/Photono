//
//  MusicPlayer.swift
//  Photono
//
//  Created by mio-kato on 2025/05/25.
//
import MusicKit

extension ApplicationMusicPlayer: @unchecked @retroactive Sendable {}

actor MusicPlayer {
    private let player = ApplicationMusicPlayer.shared
    
    func setSong(with appleId: String) async throws {
        let songs = try await getMusicItem(by: appleId)
        player.queue = .init(for: songs)
        player.state.repeatMode = .one
        try await player.prepareToPlay()
    }
    
    func play() async throws {
        try await player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    func forward() {
        player.beginSeekingForward()
    }
    
    func backward() {
        player.beginSeekingBackward()
    }
    
    private func getMusicItem(by appleId: String) async throws -> MusicItemCollection<Song> {
        let musicItemID = MusicItemID(appleId)
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        let songs: MusicItemCollection<Song> = response.items
        return songs
    }
}

