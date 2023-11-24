//
//  LoadingView.swift
//  Kami
//
//  Created by Alex Widua on 23.11.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
//            Text("Loading")
            Rectangle()
                .fill(.clear)
                .overlay {
                    HStack(spacing: 8.0) {
                        ProgressView()
//                            .controlSize(.small)
//                        Text("Loading")
                    }
                  
                }
        }
        .background(.windowBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
