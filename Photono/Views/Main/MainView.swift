//
//  MainView.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            Tab("Photo", systemImage: "photo") {
                PhotoView()
            }
            
            Tab("Music", systemImage: "music.note") {
                MusicView()
            }
        }
    }
}

#Preview {
    MainView()
}
