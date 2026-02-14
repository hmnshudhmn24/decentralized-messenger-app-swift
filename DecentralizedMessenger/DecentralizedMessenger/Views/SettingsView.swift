//
//  SettingsView.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var multipeerService: MultipeerService
    @Environment(\.dismiss) var dismiss
    
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section("Profile") {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        Text(appState.displayName)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("User ID")
                        Spacer()
                        Text(appState.userId.prefix(8))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Network
                Section("Network") {
                    Toggle("Advertising", isOn: .constant(multipeerService.isAdvertising))
                        .disabled(true)
                    
                    Toggle("Browsing", isOn: .constant(multipeerService.isBrowsing))
                        .disabled(true)
                    
                    HStack {
                        Text("Connected Peers")
                        Spacer()
                        Text("\(multipeerService.connectedPeers.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Nearby Peers")
                        Spacer()
                        Text("\(multipeerService.discoveredPeers.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Security
                Section("Security") {
                    HStack {
                        Text("Encryption")
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.green)
                        Text("AES-256-GCM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Key Exchange")
                        Spacer()
                        Text("X25519")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/decentralized-messenger-swift")!) {
                        HStack {
                            Label("GitHub Repository", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("License")
                        Spacer()
                        Text("Apache 2.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset App", systemImage: "trash")
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will delete all conversations and reset the app to initial state")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset App", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("Are you sure you want to reset the app? This will delete all conversations and cannot be undone.")
            }
        }
    }
    
    private func resetApp() {
        // Stop multipeer services
        multipeerService.stop()
        
        // Clear data
        UserDefaults.standard.removeObject(forKey: "conversations")
        UserDefaults.standard.removeObject(forKey: "messageQueue")
        MessageQueue.shared.clearAll()
        EncryptionService.shared.clearAllSecrets()
        KeychainHelper.clearAll()
        
        // Reset onboarding
        appState.resetOnboarding()
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(MultipeerService.shared)
}
