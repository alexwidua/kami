// Little loading spinner that is shown while the pasteboard is being parsed...
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
        .background(.regularMaterial)
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
}
