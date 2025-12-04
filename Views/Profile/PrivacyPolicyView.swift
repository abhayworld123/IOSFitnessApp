import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Privacy Policy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        
                        Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        SectionView(title: "Information We Collect") {
                            Text("We collect information you provide directly to us, such as when you create an account, complete your profile, or use our services. This may include:")
                            BulletPoint("Name and email address")
                            BulletPoint("Fitness goals and preferences")
                            BulletPoint("Workout history and progress")
                            BulletPoint("Subscription information")
                        }
                        
                        SectionView(title: "How We Use Your Information") {
                            Text("We use the information we collect to:")
                            BulletPoint("Provide and improve our services")
                            BulletPoint("Personalize your workout experience")
                            BulletPoint("Send you important updates and notifications")
                            BulletPoint("Process payments and manage subscriptions")
                        }
                        
                        SectionView(title: "Data Security") {
                            Text("We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                        }
                        
                        SectionView(title: "Your Rights") {
                            Text("You have the right to:")
                            BulletPoint("Access your personal data")
                            BulletPoint("Correct inaccurate data")
                            BulletPoint("Request deletion of your data")
                            BulletPoint("Opt-out of marketing communications")
                        }
                        
                        SectionView(title: "Contact Us") {
                            Text("If you have questions about this Privacy Policy, please contact us at privacy@fitnessapp.com")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            content
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
}

struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(AppConstants.Colors.primary)
            Text(text)
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
    }
}

#Preview {
    PrivacyPolicyView()
}


