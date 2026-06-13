import SwiftUI

struct WaterGlassIcon: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    /// When false, hides the outer ring so the asset can sit inside a parent progress ring.
    var showsOuterStroke: Bool

    init(progress: Double = 0.0, size: CGFloat = 114, showsOuterStroke: Bool = true) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.size = size
        self.showsOuterStroke = showsOuterStroke
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F2FAFF"))
                .frame(width: size, height: size)

            Image("waterglass")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.92, height: size * 0.92)

            if showsOuterStroke {
                Circle()
                    .stroke(Color(hex: "#ADC8FF"), lineWidth: 2)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }
}



#Preview {
    WaterGlassIcon(progress: 0.5, size: 114)
        .padding()
        .background(Color(hex: "#F5F5F7"))
}
