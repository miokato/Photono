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
    let photos: [PhotoAsset]
    @State var currentIndex: Int
    
    @State private var currentImage: UIImage?
    @State private var previousImage: UIImage?
    @State private var nextImage: UIImage?
    @State private var isLoading = true
    @State private var showingInfo = false
    @State private var musicPlayer = MusicPlayer()
    @State private var isPlaying = false
    @State private var dragOffset: CGFloat = 0
    @State private var isTransitioning = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var baseZoomScale: CGFloat = 1.0
    @State private var zoomOffset: CGSize = .zero
    @State private var isZoomed: Bool = false
    
    private var currentPhotoAsset: PhotoAsset {
        photos[currentIndex]
    }
    
    private var previousPhotoAsset: PhotoAsset? {
        guard currentIndex > 0 else { return nil }
        return photos[currentIndex - 1]
    }
    
    private var nextPhotoAsset: PhotoAsset? {
        guard currentIndex < photos.count - 1 else { return nil }
        return photos[currentIndex + 1]
    }
    
    private func loadAllImages() async {
        await withTaskGroup(of: Void.self) { group in
            // 現在の画像を優先的にロード
            group.addTask {
                let image = await PhotoLibrary.shared.loadFullSizeImage(for: currentPhotoAsset)
                await MainActor.run {
                    currentImage = image
                    isLoading = false
                }
            }
            
            // 前の画像をロード
            if let prevAsset = previousPhotoAsset {
                group.addTask {
                    let image = await PhotoLibrary.shared.loadFullSizeImage(for: prevAsset)
                    await MainActor.run {
                        previousImage = image
                    }
                }
            } else {
                await MainActor.run {
                    previousImage = nil
                }
            }
            
            // 次の画像をロード
            if let nextAsset = nextPhotoAsset {
                group.addTask {
                    let image = await PhotoLibrary.shared.loadFullSizeImage(for: nextAsset)
                    await MainActor.run {
                        nextImage = image
                    }
                }
            } else {
                await MainActor.run {
                    nextImage = nil
                }
            }
        }
    }
    
    private func loadPreviousImage() async {
        if let prevAsset = previousPhotoAsset {
            let image = await PhotoLibrary.shared.loadFullSizeImage(for: prevAsset)
            await MainActor.run {
                previousImage = image
            }
        } else {
            await MainActor.run {
                previousImage = nil
            }
        }
    }
    
    private func loadNextImage() async {
        if let nextAsset = nextPhotoAsset {
            let image = await PhotoLibrary.shared.loadFullSizeImage(for: nextAsset)
            await MainActor.run {
                nextImage = image
            }
        } else {
            await MainActor.run {
                nextImage = nil
            }
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
    
    private func moveToPreviousPhoto() {
        guard currentIndex > 0, !isTransitioning else { return }
        isTransitioning = true
        
        // ズーム状態をリセット
        resetZoom()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 既存の画像を再利用してスムーズに移動
            let oldCurrent = currentImage
            let oldNext = nextImage
            
            currentIndex -= 1
            dragOffset = 0
            
            // 前の写真が新しい現在の写真になる
            currentImage = previousImage
            // 元の現在の写真が新しい次の写真になる
            nextImage = oldCurrent
            
            isTransitioning = false
            
            // 新しい前の写真のみロード
            Task {
                await loadPreviousImage()
            }
        }
    }
    
    private func moveToNextPhoto() {
        guard currentIndex < photos.count - 1, !isTransitioning else { return }
        isTransitioning = true
        
        // ズーム状態をリセット
        resetZoom()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = -UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 既存の画像を再利用してスムーズに移動
            let oldCurrent = currentImage
            let oldPrevious = previousImage
            
            currentIndex += 1
            dragOffset = 0
            
            // 次の写真が新しい現在の写真になる
            currentImage = nextImage
            // 元の現在の写真が新しい前の写真になる
            previousImage = oldCurrent
            
            isTransitioning = false
            
            // 新しい次の写真のみロード
            Task {
                await loadNextImage()
            }
        }
    }
    
    private func resetZoom() {
        zoomScale = 1.0
        baseZoomScale = 1.0
        zoomOffset = .zero
        isZoomed = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                // 前の写真
                if let prevImage = previousImage {
                    photoImage(prevImage)
                        .offset(x: -geometry.size.width + dragOffset)
                        .opacity(dragOffset > 0 ? 1 : 0)
                }
                
                // 現在の写真
                if let currentImg = currentImage {
                    photoImage(currentImg)
                        .scaleEffect(zoomScale)
                        .offset(x: dragOffset + zoomOffset.width, y: zoomOffset.height)
                } else if isLoading {
                    progressView
                        .offset(x: dragOffset)
                } else {
                    placeholder
                        .offset(x: dragOffset)
                }
                
                // 次の写真
                if let nextImg = nextImage {
                    photoImage(nextImg)
                        .offset(x: geometry.size.width + dragOffset)
                        .opacity(dragOffset < 0 ? 1 : 0)
                }
                
                // MiniPlayerView を画面下部に配置
                VStack {
                    Spacer()
                    MiniPlayerView(
                        musicPlayer: $musicPlayer,
                        isPlaying: $isPlaying
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                infoButton
            }
        }
        .sheet(isPresented: $showingInfo) {
            PhotoInfoView(photoAsset: currentPhotoAsset)
        }
        .gesture(
            SimultaneousGesture(
                // ピンチジェスチャー（ズーム）
                MagnificationGesture()
                    .onChanged { value in
                        // ベース倍率に対してピンチ倍率を適用
                        let newScale = baseZoomScale * value
                        zoomScale = max(0.5, min(5.0, newScale))
                        isZoomed = zoomScale > 1.0
                    }
                    .onEnded { value in
                        // 新しいベース倍率を保存
                        let newScale = baseZoomScale * value
                        
                        if newScale < 1.0 {
                            // 1.0倍未満の場合はリセット
                            withAnimation(.easeOut(duration: 0.3)) {
                                resetZoom()
                            }
                        } else if newScale > 5.0 {
                            // 5.0倍を超える場合は5.0倍に制限
                            withAnimation(.easeOut(duration: 0.3)) {
                                zoomScale = 5.0
                                baseZoomScale = 5.0
                                isZoomed = true
                            }
                        } else {
                            // 通常の場合は新しいベース倍率として保存
                            baseZoomScale = newScale
                            zoomScale = newScale
                            isZoomed = newScale > 1.0
                        }
                    },
                
                // ドラッグジェスチャー
                DragGesture()
                    .onChanged { value in
                        if !isTransitioning {
                            if isZoomed {
                                // ズーム時はパン操作
                                zoomOffset = value.translation
                            } else {
                                // 通常時はスワイプ操作
                                dragOffset = value.translation.width
                            }
                        }
                    }
                    .onEnded { value in
                        if isTransitioning { return }
                        
                        if isZoomed {
                            // ズーム時は画像境界内に収める
                            let maxOffset: CGFloat = 100
                            withAnimation(.easeOut(duration: 0.3)) {
                                zoomOffset.width = max(-maxOffset, min(maxOffset, zoomOffset.width))
                                zoomOffset.height = max(-maxOffset, min(maxOffset, zoomOffset.height))
                            }
                        } else {
                            // 通常時はスワイプ判定
                            let threshold: CGFloat = 100
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            
                            if value.translation.width > threshold || velocity > 500 {
                                // 右にスワイプ：前の写真
                                if currentIndex > 0 {
                                    moveToPreviousPhoto()
                                } else {
                                    // 最初の写真の場合は元に戻す
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = 0
                                    }
                                }
                            } else if value.translation.width < -threshold || velocity < -500 {
                                // 左にスワイプ：次の写真
                                if currentIndex < photos.count - 1 {
                                    moveToNextPhoto()
                                } else {
                                    // 最後の写真の場合は元に戻す
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                // 閾値に達しない場合は元に戻す
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                    }
            )
        )
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if isZoomed {
                    resetZoom()
                } else {
                    zoomScale = 2.0
                    baseZoomScale = 2.0
                    isZoomed = true
                }
            }
        }
        .task {
            await loadAllImages()
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
