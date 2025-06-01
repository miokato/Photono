//
//  MiniPlayerView.swift
//  Photono
//
//  Created by mio-kato on 2025/05/25.
//

import SwiftUI
import MusicKit

struct MiniPlayerView: View {
    @Binding var musicPlayer: MusicPlayer
    @Binding var isPlaying: Bool
    @Binding var currentSong: String
    @Binding var currentArtist: String
    
    private func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    await musicPlayer.pause()
                    isPlaying = false
                } else {
                    // 楽曲が設定されていない場合は新しいランダム楽曲を設定
                    if currentSong == "Loading..." || currentSong == "Failed to load" {
                        let songInfo = try await musicPlayer.setRandomSong()
                        await MainActor.run {
                            currentSong = songInfo.title
                            currentArtist = songInfo.artist
                        }
                    }
                    try await musicPlayer.play()
                    isPlaying = true
                }
            } catch {
                print("Music playback error: \(error)")
            }
        }
    }
    
    private func stopMusic() {
        Task {
            await musicPlayer.stop()
            isPlaying = false
        }
    }
    
    private func skipToPrevious() {
        Task {
            do {
                let songInfo = try await musicPlayer.setRandomSong()
                try await musicPlayer.play()
                
                await MainActor.run {
                    isPlaying = true
                    currentSong = songInfo.title
                    currentArtist = songInfo.artist
                }
            } catch {
                print("Skip to previous error: \(error)")
            }
        }
    }
    
    private func skipToNext() {
        Task {
            do {
                let songInfo = try await musicPlayer.setRandomSong()
                try await musicPlayer.play()
                
                await MainActor.run {
                    isPlaying = true
                    currentSong = songInfo.title
                    currentArtist = songInfo.artist
                }
            } catch {
                print("Skip to next error: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 楽曲情報
            VStack(spacing: 4) {
                Text(currentSong)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(currentArtist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // コントロールボタン
            HStack(spacing: 20) {
                // 前の曲
                Button(action: skipToPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // 再生/一時停止
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                
                // 停止
                Button(action: stopMusic) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // 次の曲
                Button(action: skipToNext) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MiniPlayerView(
        musicPlayer: .constant(MusicPlayer()),
        isPlaying: .constant(false),
        currentSong: .constant("Sample Song"),
        currentArtist: .constant("Sample Artist")
    )
}
