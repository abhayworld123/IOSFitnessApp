import SwiftUI

struct DashboardHeaderView: View {
    let userName: String
    let profileImageName: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let imageName = profileImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppConstants.Colors.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.primary)
                    )
            }
            
            // Greeting
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello,")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8E8E93"))
                
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

#Preview {
    DashboardHeaderView(userName: "Abhay", profileImageName: nil)
        .background(Color(hex: "#F5F5F7"))
}
