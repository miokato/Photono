//
//  MusicPlayer.swift
//  Photono
//
//  Created by mio-kato on 2025/05/25.
//
@preconcurrency import MusicKit

extension ApplicationMusicPlayer: @unchecked @retroactive Sendable {}

enum MusicPlayerError: Error {
    case noSongsFound
    case searchFailed
}

actor MusicPlayer {
    private let player = ApplicationMusicPlayer.shared
    
    var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }
    
    func setSong(with appleId: String) async throws {
        let songs = try await getMusicItem(by: appleId)
        player.queue = .init(for: songs)
        player.state.repeatMode = .one
        try await player.prepareToPlay()
    }
    
    func setRandomSong() async throws -> (title: String, artist: String) {
        let songs = try await getRandomSongs()
        guard let randomSong = songs.randomElement() else {
            throw MusicPlayerError.noSongsFound
        }
        
        player.queue = .init(for: [randomSong])
        player.state.repeatMode = .one
        try await player.prepareToPlay()
        
        return (title: randomSong.title, artist: randomSong.artistName)
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
    
    func skipToNextEntry() async throws {
        try await player.skipToNextEntry()
    }
    
    func skipToPreviousEntry() async throws {
        try await player.skipToPreviousEntry()
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
    
    private func getRandomSongs() async throws -> MusicItemCollection<Song> {
        // ポピュラーな楽曲を検索するためのキーワード配列
        let searchTerms = ["pop", "rock", "jazz", "electronic", "indie", "classic", "alternative", "dance"]
        let randomTerm = searchTerms.randomElement() ?? "pop"
        
        var request = MusicCatalogSearchRequest(term: randomTerm, types: [Song.self])
        request.limit = 25
        
        do {
            let response = try await request.response()
            guard !response.songs.isEmpty else {
                throw MusicPlayerError.noSongsFound
            }
            return response.songs
        } catch {
            throw MusicPlayerError.searchFailed
        }
    }
}

