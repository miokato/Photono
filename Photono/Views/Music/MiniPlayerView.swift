//
//  MiniPlayerView.swift
//  Photono
//
//  Created by mio-kato on 2025/05/25.
//

import SwiftUI

struct MiniMusicView: View {
    func play() {
        print("play")
    }
    
    func pause() {
        print("pause")
    }
    
    func stop() {
        print("stop")
    }
    
    func forward() {
        print("forward")
    }
    
    func backward() {
        print("backward")
    }
    
    var body: some View {
        HStack {
            Text("Hello World")
            Text("Aico")
            Button(action: play) {
                Image(systemName: "play")
            }
            Button(action: stop) {
                Image(systemName: "stop")
            }
            Button(action: backward) {
                Image(systemName: "backward")
            }
            Button(action: forward) {
                Image(systemName: "forward")
            }
        }
    }
}

#Preview {
    MiniMusicView()
}
