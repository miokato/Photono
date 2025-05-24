//
//  PhotoDetailView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI
import UIKit
import CoreLocation

struct PhotoDetailView: View {
    let photoAsset: PhotoAsset
    
    @State private var fullSizeImage: UIImage?
    @State private var isLoading = true
    @State private var showingInfo = false
    
    private func loadFullSizeImage() async {
        let image = await PhotoLibrary.shared.loadFullSizeImage(for: photoAsset)
        await MainActor.run {
            fullSizeImage = image
            isLoading = false
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
        ProgressView("読み込み中...")
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    private var placeholder: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("画像を読み込めませんでした")
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    // プレビューでは実際のPhotoAssetは使用できないため、ダミーのビューを表示
    Text("PhotoDetailView Preview")
}
