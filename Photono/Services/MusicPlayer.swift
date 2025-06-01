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
    private var cachedSongInfo: (title: String, artist: String)? = nil
    
    var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }
    
    var playbackStatus: ApplicationMusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }
    
    var hasQueue: Bool {
        !player.queue.entries.isEmpty
    }
    
    var currentSongInfo: (title: String, artist: String)? {
        
        // まずキャッシュされた情報を返す
        if let cached = cachedSongInfo {
            return cached
        }
        
        // まず現在のアイテムを直接取得してみる
        if let playingItem = player.queue.currentEntry?.item {
            
            if let song = playingItem as? Song {
                let songInfo = (title: song.title, artist: song.artistName)
                cachedSongInfo = songInfo
                return songInfo
            }
        }
        
        // 代替手段：エントリから直接取得
        if let entries = player.queue.entries.first {
            if let song = entries.item as? Song {
                let songInfo = (title: song.title, artist: song.artistName)
                cachedSongInfo = songInfo
                return songInfo
            }
        }
        
        return nil
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
        
        let songInfo = (title: randomSong.title, artist: randomSong.artistName)
        cachedSongInfo = songInfo
        print("🎵 Cached song info: \(songInfo)")
        
        return songInfo
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

