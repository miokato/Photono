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
    @State private var currentSong: String = "Sample Song"
    @State private var currentArtist: String = "Sample Artist"
    
    private func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    await musicPlayer.pause()
                    isPlaying = false
                } else {
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
                try await musicPlayer.skipToPreviousEntry()
            } catch {
                print("Skip to previous error: \(error)")
            }
        }
    }
    
    private func skipToNext() {
        Task {
            do {
                try await musicPlayer.skipToNextEntry()
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
        isPlaying: .constant(false)
    )
}
