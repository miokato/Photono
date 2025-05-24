//
//  PhotoView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI
import UIKit

struct PhotoView: View {
    @State private var photos: [PhotoAsset] = []
    @State private var isLoading = false
    @State private var hasPermission = false
    @State private var showingPermissionAlert = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
   
    // MARK: - private methods
    
    private func requestPermissionAndLoadPhotos() async {
        isLoading = true
        let granted = await PhotoLibrary.shared.requestAuthorization()
        
        await MainActor.run {
            hasPermission = granted
            if !granted {
                showingPermissionAlert = true
            }
        }
        
        if granted {
            await loadPhotos()
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func loadPhotos() async {
        let photoAssets = await PhotoLibrary.shared.fetchRecentPhotos(limit: 100)
        await MainActor.run {
            photos = photoAssets
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - body
    
    var body: some View {
        NavigationStack {
            Group {
                if hasPermission {
                    photoGridView
                } else {
                    permissionView
                }
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .task { await requestPermissionAndLoadPhotos() }
            .alert("写真へのアクセスが必要です", isPresented: $showingPermissionAlert) {
                Button("設定を開く") {
                    openSettings()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("カメラロールの写真を表示するために、写真へのアクセス許可が必要です。")
            }
        }
    }
    
    @ViewBuilder
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photoAsset in
                    NavigationLink(destination: PhotoDetailView(photoAsset: photoAsset)) {
                        AsyncPhotoView(photoAsset: photoAsset)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .refreshable {
            await loadPhotos()
        }
        .overlay {
            if isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    @ViewBuilder
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("写真へのアクセスが必要です")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("カメラロールの写真を表示するために、写真へのアクセス許可をお願いします。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("許可する") {
                Task {
                    await requestPermissionAndLoadPhotos()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    PhotoView()
}
