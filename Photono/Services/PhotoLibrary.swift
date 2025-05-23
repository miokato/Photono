//
//  PhotoLibrary.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import Photos
import UIKit
import SwiftUI

actor PhotoLibrary {
    static let shared = PhotoLibrary()
    
    private init() {}
    
    /// フォトライブラリへのアクセス許可を要求
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// カメラロールから最新の写真を取得
    func fetchRecentPhotos(limit: Int = 20) async -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var photoAssets: [PhotoAsset] = []
        
        assets.enumerateObjects { asset, _, _ in
            photoAssets.append(PhotoAsset(asset: asset))
        }
        
        return photoAssets
    }
    
    /// PHAssetから画像データを取得
    func loadImage(for photoAsset: PhotoAsset, targetSize: CGSize = CGSize(width: 300, height: 300)) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: photoAsset.asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    /// フルサイズの画像を取得
    func loadFullSizeImage(for photoAsset: PhotoAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: photoAsset.asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

/// フォトライブラリのアセットを表現するモデル
struct PhotoAsset: Identifiable {
    let id = UUID()
    let asset: PHAsset
    
    var creationDate: Date? {
        asset.creationDate
    }
    
    var location: CLLocation? {
        asset.location
    }
    
    var isFavorite: Bool {
        asset.isFavorite
    }
}
