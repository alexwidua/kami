//
// LoadingView.swift
//
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .overlay {
                    HStack(spacing: 8.0) {
                        ProgressView()
                    }
                }
        }
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
