//
//  PhotoInfoView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI

/// 写真の詳細情報を表示するビュー
struct PhotoInfoView: View {
    let photoAsset: PhotoAsset
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let creationDate = photoAsset.creationDate {
                    Section("撮影日時") {
                        Text(creationDate, style: .date)
                        Text(creationDate, style: .time)
                    }
                }
                
                Section("詳細") {
                    HStack {
                        Text("幅")
                        Spacer()
                        Text("\(photoAsset.asset.pixelWidth) px")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("高さ")
                        Spacer()
                        Text("\(photoAsset.asset.pixelHeight) px")
                            .foregroundColor(.secondary)
                    }
                    
                    if photoAsset.isFavorite {
                        HStack {
                            Text("お気に入り")
                            Spacer()
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let location = photoAsset.location {
                    Section("位置情報") {
                        HStack {
                            Text("緯度")
                            Spacer()
                            Text("\(location.coordinate.latitude, specifier: "%.6f")")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("経度")
                            Spacer()
                            Text("\(location.coordinate.longitude, specifier: "%.6f")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("写真情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
}
