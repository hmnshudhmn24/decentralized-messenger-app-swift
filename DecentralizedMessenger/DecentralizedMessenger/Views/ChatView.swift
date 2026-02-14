//
//  ChatView.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var multipeerService: MultipeerService
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    let peer: Peer?
    @State private var conversation: Conversation
    
    @State private var messageText = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    
    init(peer: Peer) {
        self.peer = peer
        _conversation = State(initialValue: Conversation(peerId: peer.id, peerName: peer.displayName))
    }
    
    init(conversation: Conversation) {
        self.peer = nil
        _conversation = State(initialValue: conversation)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation.sortedMessages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == appState.userId
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _, _ in
                    if let lastMessage = conversation.sortedMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Typing Indicator
            if chatViewModel.isTyping[conversation.peerId] == true {
                HStack {
                    Text("\(conversation.peerName) is typing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Spacer()
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onChange(of: messageText) { oldValue, newValue in
                        handleTyping(oldValue: oldValue, newValue: newValue)
                    }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle(conversation.peerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(isConnected ? "Connected" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            loadConversation()
            markAsRead()
            
            // Establish encryption if connected
            if isConnected, let peer = peer ?? getPeerFromService() {
                if let publicKey = peer.publicKey {
                    _ = EncryptionService.shared.deriveSharedSecret(
                        peerPublicKey: publicKey,
                        peerId: peer.id
                    )
                }
            }
        }
        .onDisappear {
            markAsRead()
        }
    }
    
    // MARK: - Helper Properties
    private var isConnected: Bool {
        multipeerService.isConnected(to: conversation.peerId)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let content = MessageContent.text(trimmed)
        
        Task {
            if let peer = peer ?? getPeerFromService() {
                await chatViewModel.sendMessage(
                    content: content,
                    to: peer,
                    currentUserId: appState.userId,
                    currentUserName: appState.displayName
                )
            }
        }
        
        messageText = ""
        isTyping = false
        chatViewModel.sendTypingIndicator(to: conversation.peerId, isTyping: false)
    }
    
    private func handleTyping(oldValue: String, newValue: String) {
        let wasEmpty = oldValue.isEmpty
        let isEmpty = newValue.isEmpty
        
        if wasEmpty && !isEmpty {
            // Started typing
            isTyping = true
            chatViewModel.sendTypingIndicator(to: conversation.peerId, isTyping: true)
        } else if !wasEmpty && isEmpty {
            // Stopped typing
            isTyping = false
            chatViewModel.sendTypingIndicator(to: conversation.peerId, isTyping: false)
        }
    }
    
    private func loadConversation() {
        if let existing = chatViewModel.conversations.first(where: { $0.peerId == conversation.peerId }) {
            conversation = existing
        } else if let peer = peer ?? getPeerFromService() {
            conversation = chatViewModel.getOrCreateConversation(with: peer)
        }
    }
    
    private func markAsRead() {
        chatViewModel.markConversationAsRead(conversation.id)
    }
    
    private func getPeerFromService() -> Peer? {
        return multipeerService.connectedPeers.first { $0.id == conversation.peerId }
            ?? multipeerService.discoveredPeers.first { $0.id == conversation.peerId }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                switch message.content {
                case .text(let text):
                    Text(text)
                        .padding(12)
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(isFromCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                case .voice(_, let duration):
                    HStack {
                        Image(systemName: "waveform")
                        Text("\(Int(duration))s")
                    }
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                case .image:
                    Image(systemName: "photo")
                        .font(.title)
                        .padding(12)
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(isFromCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                case .file(_, let filename, _):
                    HStack {
                        Image(systemName: "doc")
                        Text(filename)
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                case .system(let text):
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                
                // Metadata
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isFromCurrentUser {
                        Image(systemName: message.status.icon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(peer: Peer(id: "test", displayName: "Test User"))
            .environmentObject(AppState())
            .environmentObject(MultipeerService.shared)
            .environmentObject(ChatViewModel())
    }
}
