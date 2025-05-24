//
//  PhotoPermissionView.swift
//  Photono
//
//  Created by mio-kato on 2025/05/24.
//

import SwiftUI

struct PhotoPermissionView: View {
    var onTapButton: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Photo access is required.")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please grant photo access to display images from the camera roll.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Allow") {
                onTapButton()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    PhotoPermissionView(onTapButton: {})
}
