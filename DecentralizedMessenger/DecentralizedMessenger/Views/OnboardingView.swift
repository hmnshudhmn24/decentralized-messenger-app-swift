//
//  OnboardingView.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var displayName = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image(systemName: "network")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("Mesh Chat")
                    .font(.title.bold())
                
                Text("Decentralized. Encrypted. Offline-first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Display Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a display name")
                    .font(.headline)
                
                TextField("Enter your name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
            }
            .padding(.horizontal)
            
            // Continue Button
            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .disabled(displayName.isEmpty)
            
            Text("📡 No servers. No internet required.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
    }
    
    private func completeOnboarding() {
        appState.completeOnboarding(displayName: displayName)
        
        // Initialize multipeer service
        MultipeerService.shared.initialize(
            displayName: displayName,
            userId: appState.userId
        )
        MultipeerService.shared.start()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
