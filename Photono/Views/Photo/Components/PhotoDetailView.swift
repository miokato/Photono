//
//  PhotoDetailView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI
import UIKit
import CoreLocation
import MusicKit

struct PhotoDetailView: View {
    let photoAsset: PhotoAsset
    
    @State private var fullSizeImage: UIImage?
    @State private var isLoading = true
    @State private var showingInfo = false
    @State private var musicPlayer = MusicPlayer()
    @State private var isPlaying = false
    
    private func loadFullSizeImage() async {
        let image = await PhotoLibrary.shared.loadFullSizeImage(for: photoAsset)
        await MainActor.run {
            fullSizeImage = image
            isLoading = false
        }
    }
    
    private func setupMusicAndPlay() async {
        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { return }
            
            let sampleSongID = "1450695739"
            try await musicPlayer.setSong(with: sampleSongID)
            try await musicPlayer.play()
            await MainActor.run {
                isPlaying = true
            }
        } catch {
            print("Music setup failed: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if let image = fullSizeImage {
                photoImage(image)
            } else if isLoading {
                progressView
            } else {
                placeholder
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                infoButton
            }
        }
        .sheet(isPresented: $showingInfo) {
            PhotoInfoView(photoAsset: photoAsset)
        }
        .task {
            await loadFullSizeImage()
            await setupMusicAndPlay()
        }
    }
    
    @ViewBuilder
    private var infoButton: some View {
        Button {
            showingInfo.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func photoImage(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
    }
    
    @ViewBuilder
    private var progressView: some View {
        ProgressView("Loading…")
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    private var placeholder: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Failed to load image.")
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    // プレビューでは実際のPhotoAssetは使用できないため、ダミーのビューを表示
    Text("PhotoDetailView Preview")
}
