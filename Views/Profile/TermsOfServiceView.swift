import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Terms of Service")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        
                        Text("Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        SectionView(title: "Acceptance of Terms") {
                            Text("By accessing and using this fitness application, you accept and agree to be bound by the terms and provision of this agreement.")
                        }
                        
                        SectionView(title: "Use License") {
                            Text("Permission is granted to temporarily use this application for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:")
                            BulletPoint("Modify or copy the materials")
                            BulletPoint("Use the materials for any commercial purpose")
                            BulletPoint("Attempt to decompile or reverse engineer any software")
                            BulletPoint("Remove any copyright or other proprietary notations")
                        }
                        
                        SectionView(title: "Subscription Terms") {
                            Text("Subscriptions are billed on a recurring basis. You may cancel your subscription at any time through your account settings. Refunds are subject to our refund policy.")
                        }
                        
                        SectionView(title: "Health and Safety Disclaimer") {
                            Text("This application provides fitness information for educational purposes only. Consult with a healthcare provider before beginning any exercise program. We are not responsible for any injuries that may occur from using this application.")
                        }
                        
                        SectionView(title: "Limitation of Liability") {
                            Text("In no event shall the application or its suppliers be liable for any damages arising out of the use or inability to use the application.")
                        }
                        
                        SectionView(title: "Contact Information") {
                            Text("For questions about these Terms of Service, please contact us at support@fitnessapp.com")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Terms of Service")
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

#Preview {
    TermsOfServiceView()
}


