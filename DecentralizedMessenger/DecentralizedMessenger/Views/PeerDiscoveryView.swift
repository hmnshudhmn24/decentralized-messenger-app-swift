//
//  PeerDiscoveryView.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import SwiftUI

struct PeerDiscoveryView: View {
    @EnvironmentObject var multipeerService: MultipeerService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Service Status
                Section("Status") {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Advertising")
                        Spacer()
                        Circle()
                            .fill(multipeerService.isAdvertising ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Browsing")
                        Spacer()
                        Circle()
                            .fill(multipeerService.isBrowsing ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Connected Peers
                if !multipeerService.connectedPeers.isEmpty {
                    Section("Connected") {
                        ForEach(multipeerService.connectedPeers) { peer in
                            PeerDiscoveryRow(peer: peer, isConnected: true)
                        }
                    }
                }
                
                // Discovered Peers
                if !multipeerService.discoveredPeers.isEmpty {
                    Section("Nearby") {
                        ForEach(multipeerService.discoveredPeers.filter { peer in
                            !multipeerService.connectedPeers.contains(where: { $0.id == peer.id })
                        }) { peer in
                            PeerDiscoveryRow(peer: peer, isConnected: false)
                        }
                    }
                } else {
                    Section("Nearby") {
                        Text("No peers discovered")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Help
                Section {
                    Text("Make sure WiFi and Bluetooth are enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Devices must be on the same WiFi network or within Bluetooth range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Tips")
                }
            }
            .navigationTitle("Peer Discovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Peer Discovery Row
struct PeerDiscoveryRow: View {
    let peer: Peer
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isConnected ? Color.green.gradient : Color.blue.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(peer.displayName.prefix(1).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(peer.displayName)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(isConnected ? "Connected" : "Nearby")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    PeerDiscoveryView()
        .environmentObject(MultipeerService.shared)
}
