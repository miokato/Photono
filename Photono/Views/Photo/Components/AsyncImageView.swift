//
//  AsyncImageView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI

/// 非同期で画像を読み込んで表示するビュー
struct AsyncPhotoView: View {
    let photoAsset: PhotoAsset
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let loadedImage = await PhotoLibrary.shared.loadImage(
            for: photoAsset,
            targetSize: CGSize(width: 200, height: 200)
        )
        
        await MainActor.run {
            image = loadedImage
            isLoading = false
        }
    }
}

