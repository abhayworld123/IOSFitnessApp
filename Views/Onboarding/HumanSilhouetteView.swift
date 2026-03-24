import SwiftUI

struct HumanSilhouetteView: View {
    // Fixed height silhouette (doesn't scale with height value)
    // Keep it larger than Figma, but fit within the height card without pushing controls off-screen.
    private let fixedHeight: CGFloat = 360
    
    var body: some View {
        // Human silhouette from Public/Images/silihoute.png
        Group {
            if let uiImage = UIImage(named: "silihoute") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fixedHeight * 0.6, height: fixedHeight) // Set both width and height for proper scaling
            } else if let path = Bundle.main.path(forResource: "silihoute", ofType: "png", inDirectory: "Public/Images"),
                      let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fixedHeight * 0.6, height: fixedHeight) // Set both width and height for proper scaling
            } else {
                // Fallback to SF Symbol if image not found
                Image(systemName: "figure.stand")
                    .font(.system(size: fixedHeight * 0.8))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
        }
        .frame(height: fixedHeight)
        .opacity(0.3)
    }
}

#Preview {
    VStack(spacing: 40) {
        HumanSilhouetteView()
        HumanSilhouetteView()
        HumanSilhouetteView()
    }
    .padding()
}
