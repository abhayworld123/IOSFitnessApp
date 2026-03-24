import SwiftUI

struct WaterGlassIcon: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    
    init(progress: Double = 0.0, size: CGFloat = 114) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color(hex: "#F2FAFF"))
                .frame(width: size, height: size)
            
            // Water glass image
            Image("waterglass")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            
            // Border
            Circle()
                .stroke(Color(hex: "#ADC8FF"), lineWidth: 2)
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}



#Preview {
    WaterGlassIcon(progress: 0.5, size: 114)
        .padding()
        .background(Color(hex: "#F5F5F7"))
}
