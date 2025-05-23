//
//  View+.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import SwiftUI

extension View {
    func zoomable() -> some View {
        modifier(ZoomableModifier())
    }
}

