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
    
    // MARK: - Image States
    @State private var currentImage: UIImage?
    @State private var previousImage: UIImage?
    @State private var nextImage: UIImage?
    @State private var isLoading = true
    
    // MARK: - Navigation States
    @State private var dragOffset: CGFloat = 0
    @State private var isTransitioning = false
    
    // MARK: - Zoom States
    @State private var zoomScale: CGFloat = 1.0
    @State private var baseZoomScale: CGFloat = 1.0
    @State private var zoomOffset: CGSize = .zero
    @State private var isZoomed: Bool = false
    
    // MARK: - Music States
    @State private var musicPlayer = MusicPlayer()
    @State private var isPlaying = false
    @State private var currentSongTitle: String = "Loading..."
    @State private var currentArtist: String = ""
    
    // MARK: - UI States
    @State private var showingInfo = false
    @State private var playerOffset: CGSize = .zero
    @State private var isDraggingPlayer = false
    @State private var lastPlayerPosition: CGSize = .zero
    
    // MARK: - methods
    
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
    
    private func loadAdjacentImage(photoAsset: PhotoAsset?, isNext: Bool) async {
        if let asset = photoAsset {
            let image = await PhotoLibrary.shared.loadFullSizeImage(for: asset)
            await MainActor.run {
                if isNext {
                    nextImage = image
                } else {
                    previousImage = image
                }
            }
        } else {
            await MainActor.run {
                if isNext {
                    nextImage = nil
                } else {
                    previousImage = nil
                }
            }
        }
    }
    
    private func setupMusicAndPlay() async {
        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else { return }
            
            // 既存の音楽がある場合の処理
            if await musicPlayer.hasQueue {
                let playbackStatus = await musicPlayer.playbackStatus
                let currentPlaying = await musicPlayer.isPlaying
                
                // 現在の楽曲情報を取得
                if let songInfo = await musicPlayer.currentSongInfo {
                    await MainActor.run {
                        currentSongTitle = songInfo.title
                        currentArtist = songInfo.artist
                        isPlaying = currentPlaying
                    }
                }
                
                // 一時停止中の場合のみ再生を再開（停止中は新しい曲をロード）
                if playbackStatus == .paused {
                    try await musicPlayer.play()
                    await MainActor.run {
                        isPlaying = true
                    }
                }
                // 既に再生中の場合は何もしない
                else if playbackStatus == .playing {
                    return
                }
                // 停止中の場合は新しい曲をロード
                else {
                    let songInfo = try await musicPlayer.setRandomSong()
                    try await musicPlayer.play()
                    
                    await MainActor.run {
                        isPlaying = true
                        currentSongTitle = songInfo.title
                        currentArtist = songInfo.artist
                    }
                }
            } else {
                // キューが空の場合は新しい曲をセット
                let songInfo = try await musicPlayer.setRandomSong()
                try await musicPlayer.play()
                
                await MainActor.run {
                    isPlaying = true
                    currentSongTitle = songInfo.title
                    currentArtist = songInfo.artist
                }
            }
        } catch {
            print("Music setup failed: \(error)")
            await MainActor.run {
                currentSongTitle = "Failed to load"
                currentArtist = "Error"
            }
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
                await loadAdjacentImage(photoAsset: previousPhotoAsset, isNext: false)
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
                await loadAdjacentImage(photoAsset: nextPhotoAsset, isNext: true)
            }
        }
    }
    
    private func resetZoom() {
        zoomScale = 1.0
        baseZoomScale = 1.0
        zoomOffset = .zero
        isZoomed = false
    }
    
    private func updateCurrentSongInfo() async {
        print("🎵 updateCurrentSongInfo called")
        let hasQueue = await musicPlayer.hasQueue
        print("🎵 hasQueue: \(hasQueue)")
        
        if hasQueue {
            let songInfo = await musicPlayer.currentSongInfo
            print("🎵 songInfo: \(String(describing: songInfo))")
            
            if let songInfo = songInfo {
                let currentPlaying = await musicPlayer.isPlaying
                print("🎵 Updating UI with: \(songInfo.title) by \(songInfo.artist)")
                await MainActor.run {
                    currentSongTitle = songInfo.title
                    currentArtist = songInfo.artist
                    isPlaying = currentPlaying
                }
            }
        }
    }
    
    private func calculateSnapPosition(for geometry: GeometryProxy, with offset: CGSize) -> CGSize {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let playerHeight: CGFloat = 80 // Approximate height of MiniPlayerView
        let playerWidth: CGFloat = screenWidth - 32 // Width with padding
        let padding: CGFloat = 16
        let safeArea = geometry.safeAreaInsets
        
        // Calculate the center position of the player with the current offset
        let centerX = screenWidth / 2 + offset.width
        let centerY = screenHeight - playerHeight / 2 - 20 - safeArea.bottom + offset.height
        
        // Define snap zones (edges of the screen)
        let snapMargin: CGFloat = 100
        
        // Determine which edge to snap to
        var finalOffset = offset
        
        // Horizontal snapping
        if centerX < snapMargin {
            // Snap to left edge
            finalOffset.width = -(screenWidth / 2 - playerWidth / 2 - padding)
        } else if centerX > screenWidth - snapMargin {
            // Snap to right edge
            finalOffset.width = screenWidth / 2 - playerWidth / 2 - padding
        }
        
        // Vertical snapping
        if centerY < snapMargin + safeArea.top {
            // Snap to top edge
            finalOffset.height = -(screenHeight - playerHeight - padding - safeArea.top - safeArea.bottom - 20)
        } else if centerY > screenHeight - snapMargin - safeArea.bottom {
            // Snap to bottom edge (original position)
            finalOffset.height = 0
        }
        
        // Corner snapping - if close to a corner, snap to both edges
        let cornerSnapMargin: CGFloat = 150
        if centerX < cornerSnapMargin && centerY < cornerSnapMargin + safeArea.top {
            // Top-left corner
            finalOffset.width = -(screenWidth / 2 - playerWidth / 2 - padding)
            finalOffset.height = -(screenHeight - playerHeight - padding - safeArea.top - safeArea.bottom - 20)
        } else if centerX > screenWidth - cornerSnapMargin && centerY < cornerSnapMargin + safeArea.top {
            // Top-right corner
            finalOffset.width = screenWidth / 2 - playerWidth / 2 - padding
            finalOffset.height = -(screenHeight - playerHeight - padding - safeArea.top - safeArea.bottom - 20)
        }
        
        return finalOffset
    }
    
    private func miniPlayerDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                playerOffset = value.translation
                isDraggingPlayer = true
            }
            .onEnded { value in
                let totalOffset = CGSize(
                    width: lastPlayerPosition.width + value.translation.width,
                    height: lastPlayerPosition.height + value.translation.height
                )
                
                let snapPosition = calculateSnapPosition(for: geometry, with: totalOffset)
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    lastPlayerPosition = snapPosition
                    playerOffset = .zero
                    isDraggingPlayer = false
                }
            }
    }
    
    // MARK: - body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                photoCarousel(geometry: geometry)
                miniPlayerOverlay(geometry: geometry)
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
            // 楽曲情報を即座に更新
            await updateCurrentSongInfo()
            await loadAllImages()
            await setupMusicAndPlay()
        }
    }
    
    // MARK: - View builders
    
    @ViewBuilder
    private func photoCarousel(geometry: GeometryProxy) -> some View {
        ZStack {
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
        }
    }
    
    @ViewBuilder
    private func miniPlayerOverlay(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            MiniPlayerView(
                musicPlayer: $musicPlayer,
                isPlaying: $isPlaying,
                currentSong: $currentSongTitle,
                currentArtist: $currentArtist
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .offset(x: playerOffset.width + lastPlayerPosition.width,
                    y: playerOffset.height + lastPlayerPosition.height)
            .scaleEffect(isDraggingPlayer ? 1.05 : 1.0)
            .shadow(radius: isDraggingPlayer ? 15 : 10)
            .animation(.easeInOut(duration: 0.2), value: isDraggingPlayer)
            .gesture(miniPlayerDragGesture(geometry: geometry))
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
