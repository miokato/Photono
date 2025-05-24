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
            .navigationTitle("photo")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard photos.isEmpty else { return }
                await requestPermissionAndLoadPhotos()
            }
            .alert("Photo access is required.", isPresented: $showingPermissionAlert) {
                Button("Open Settings") { openSettings() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please grant photo access to display images from the camera roll.")
            }
        }
    }
    
    @ViewBuilder
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photoAsset in
                    NavigationLink(destination: PhotoDetailView(photoAsset: photoAsset)) {
                        AsyncPhotoView(photoAsset: photoAsset)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .refreshable {
            await loadPhotos()
        }
        .overlay {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    @ViewBuilder
    private var permissionView: some View {
        PhotoPermissionView {
            Task { await requestPermissionAndLoadPhotos() }
        }
    }
}

#Preview {
    PhotoView()
        .environment(\.locale, Locale(identifier: "ja"))
}
