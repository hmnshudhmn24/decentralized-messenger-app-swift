//
//  DecentralizedMessengerApp.swift
//  DecentralizedMessenger
//
//  Created on 2026.
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0

import SwiftUI

@main
struct DecentralizedMessengerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var multipeerService = MultipeerService.shared
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                ConversationListView()
                    .environmentObject(appState)
                    .environmentObject(multipeerService)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
    
    private func setupAppearance() {
        // Configure app-wide appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var displayName: String
    @Published var userId: String
    
    init() {
        // Load from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        
        // Save userId if new
        if UserDefaults.standard.string(forKey: "userId") == nil {
            UserDefaults.standard.set(userId, forKey: "userId")
        }
    }
    
    func completeOnboarding(displayName: String) {
        self.displayName = displayName
        self.hasCompletedOnboarding = true
        
        UserDefaults.standard.set(displayName, forKey: "displayName")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        displayName = ""
        
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "displayName")
    }
}
