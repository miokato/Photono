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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = fullSizeImage {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .zoomable()
                } else if isLoading {
                    ProgressView("読み込み中...")
                        .foregroundColor(.white)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("画像を読み込めませんでした")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingInfo) {
            PhotoInfoView(photoAsset: photoAsset)
        }
        .task {
            await loadFullSizeImage()
        }
    }
    
    private func loadFullSizeImage() async {
        let image = await PhotoLibrary.shared.loadFullSizeImage(for: photoAsset)
        await MainActor.run {
            fullSizeImage = image
            isLoading = false
        }
    }
}

#Preview {
    // プレビューでは実際のPhotoAssetは使用できないため、ダミーのビューを表示
    Text("PhotoDetailView Preview")
}
