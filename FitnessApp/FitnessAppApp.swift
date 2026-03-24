//
//  FitnessAppApp.swift
//  FitnessApp
//
//  Created by abhay chaturvedi on 11/29/25.
//

import SwiftUI
import GoogleSignIn

@main
struct FitnessAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Fallback: ignore exceptions from Google Sign-In URL handling (e.g. invalid/cancelled)
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
