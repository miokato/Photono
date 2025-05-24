//
//  PhotoAsset.swift
//  Photono
//
//  Created by mio-kato on 2025/05/24.
//

import Photos

struct PhotoAsset: Sendable, Identifiable {
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
