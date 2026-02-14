//
//  ConversationListView.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var multipeerService: MultipeerService
    @StateObject private var chatViewModel = ChatViewModel()
    
    @State private var showPeerDiscovery = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            List {
                // Active Conversations
                if !chatViewModel.conversations.isEmpty {
                    Section("Conversations") {
                        ForEach(chatViewModel.conversations.sorted(by: { $0.lastActivity > $1.lastActivity })) { conversation in
                            NavigationLink(destination: ChatView(conversation: conversation)) {
                                ConversationRow(conversation: conversation, chatViewModel: chatViewModel)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    chatViewModel.deleteConversation(conversation.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Nearby Peers
                if !multipeerService.discoveredPeers.isEmpty || !multipeerService.connectedPeers.isEmpty {
                    Section("Nearby Peers") {
                        ForEach(multipeerService.connectedPeers) { peer in
                            NavigationLink(destination: ChatView(peer: peer)) {
                                PeerRow(peer: peer, isConnected: true)
                            }
                        }
                        
                        ForEach(multipeerService.discoveredPeers.filter { peer in
                            !multipeerService.connectedPeers.contains(where: { $0.id == peer.id })
                        }) { peer in
                            NavigationLink(destination: ChatView(peer: peer)) {
                                PeerRow(peer: peer, isConnected: false)
                            }
                        }
                    }
                }
                
                // Empty State
                if chatViewModel.conversations.isEmpty && multipeerService.discoveredPeers.isEmpty && multipeerService.connectedPeers.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Start by discovering nearby peers")
                    )
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPeerDiscovery = true
                    } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            .sheet(isPresented: $showPeerDiscovery) {
                PeerDiscoveryView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .environmentObject(chatViewModel)
        }
        .onAppear {
            // Ensure multipeer service is running
            if !multipeerService.isAdvertising {
                multipeerService.initialize(displayName: appState.displayName, userId: appState.userId)
                multipeerService.start()
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(conversation.peerName.prefix(1).uppercased())
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.peerName)
                        .font(.headline)
                    
                    if chatViewModel.isTyping[conversation.peerId] == true {
                        Text("typing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.content.displayText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Time & Badge
            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue, in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Peer Row
struct PeerRow: View {
    let peer: Peer
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.green.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(peer.displayName.prefix(1).uppercased())
                        .font(.title3.bold())
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationListView()
        .environmentObject(AppState())
        .environmentObject(MultipeerService.shared)
}
