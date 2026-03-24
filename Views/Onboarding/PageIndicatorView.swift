import SwiftUI

struct PageIndicatorView: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index == currentPage ? Color(hex: "#D89644") : Color(hex: "#E0E0E0"))
                    .frame(width: index == currentPage ? 28 : 8, height: 4)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PageIndicatorView(currentPage: 0, totalPages: 3)
        PageIndicatorView(currentPage: 1, totalPages: 3)
        PageIndicatorView(currentPage: 2, totalPages: 3)
    }
    .padding()
}
