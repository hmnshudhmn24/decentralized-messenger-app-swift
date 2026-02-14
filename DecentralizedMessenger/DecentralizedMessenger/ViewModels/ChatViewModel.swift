//
//  ChatViewModel.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import MultipeerConnectivity

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isTyping: [String: Bool] = [:]
    
    private let multipeerService = MultipeerService.shared
    private let encryptionService = EncryptionService.shared
    private let messageQueue = MessageQueue.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMultipeerCallbacks()
        setupRetryTimer()
        loadConversations()
    }
    
    // MARK: - Setup
    private func setupMultipeerCallbacks() {
        // Handle received messages
        multipeerService.onMessageReceived = { [weak self] encryptedMessage, peerID in
            Task { @MainActor in
                await self?.handleReceivedMessage(encryptedMessage, from: peerID)
            }
        }
        
        // Handle peer connected
        multipeerService.onPeerConnected = { [weak self] peerID in
            Task { @MainActor in
                await self?.handlePeerConnected(peerID)
            }
        }
        
        // Handle peer disconnected
        multipeerService.onPeerDisconnected = { [weak self] peerID in
            Task { @MainActor in
                self?.handlePeerDisconnected(peerID)
            }
        }
        
        // Handle typing indicator
        multipeerService.onTypingIndicator = { [weak self] peerID, isTyping in
            Task { @MainActor in
                self?.isTyping[peerID.displayName] = isTyping
            }
        }
    }
    
    private func setupRetryTimer() {
        NotificationCenter.default.publisher(for: .retryQueuedMessages)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.retryQueuedMessages()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Message Handling
    func sendMessage(content: MessageContent, to peer: Peer, currentUserId: String, currentUserName: String) async {
        let message = Message(
            conversationId: peer.id,
            senderId: currentUserId,
            senderName: currentUserName,
            content: content
        )
        
        // Add to conversation immediately
        addMessageToConversation(message, peerId: peer.id, peerName: peer.displayName)
        
        // Try to send
        if multipeerService.isConnected(to: peer.id) {
            do {
                let encryptedMessage = try encryptionService.encrypt(message: message, for: peer.id)
                multipeerService.sendMessage(encryptedMessage, to: peer.id)
                
                // Update status to sent
                updateMessageStatus(message.id, status: .sent, in: peer.id)
            } catch {
                print("Failed to send message: \(error)")
                // Queue for later
                messageQueue.enqueue(message, for: peer.id)
                updateMessageStatus(message.id, status: .queued, in: peer.id)
            }
        } else {
            // Peer offline, queue message
            messageQueue.enqueue(message, for: peer.id)
            updateMessageStatus(message.id, status: .queued, in: peer.id)
        }
        
        saveConversations()
    }
    
    private func handleReceivedMessage(_ encryptedMessage: EncryptedMessage, from peerID: MCPeerID) async {
        do {
            let content = try encryptionService.decrypt(encryptedMessage: encryptedMessage, from: peerID.displayName)
            
            let message = Message(
                id: UUID(uuidString: encryptedMessage.messageId) ?? UUID(),
                conversationId: encryptedMessage.conversationId,
                senderId: encryptedMessage.senderId,
                senderName: encryptedMessage.senderName,
                content: content,
                timestamp: encryptedMessage.timestamp,
                status: .delivered
            )
            
            addMessageToConversation(message, peerId: peerID.displayName, peerName: encryptedMessage.senderName)
            saveConversations()
            
            // Send notification
            NotificationService.shared.showNotification(
                title: encryptedMessage.senderName,
                body: content.displayText
            )
            
        } catch {
            print("Failed to decrypt message: \(error)")
        }
    }
    
    private func handlePeerConnected(_ peerID: MCPeerID) async {
        // Exchange public keys if needed
        if let peer = multipeerService.getPeer(for: peerID),
           let publicKey = peer.publicKey {
            _ = encryptionService.deriveSharedSecret(peerPublicKey: publicKey, peerId: peerID.displayName)
        }
        
        // Retry queued messages
        await retryQueuedMessagesForPeer(peerID.displayName)
    }
    
    private func handlePeerDisconnected(_ peerID: MCPeerID) {
        // Clean up encryption keys
        encryptionService.clearSharedSecret(for: peerID.displayName)
    }
    
    // MARK: - Queue Management
    private func retryQueuedMessages() async {
        for peer in multipeerService.connectedPeers {
            await retryQueuedMessagesForPeer(peer.id)
        }
    }
    
    private func retryQueuedMessagesForPeer(_ peerId: String) async {
        let queuedMessages = messageQueue.getQueuedMessages(for: peerId)
        
        for queuedMessage in queuedMessages {
            do {
                let encryptedMessage = try encryptionService.encrypt(message: queuedMessage.message, for: peerId)
                multipeerService.sendMessage(encryptedMessage, to: peerId)
                
                // Successfully sent, remove from queue
                messageQueue.dequeue(messageId: queuedMessage.message.id)
                updateMessageStatus(queuedMessage.message.id, status: .sent, in: peerId)
                
            } catch {
                // Failed to send, increment retry count
                messageQueue.incrementRetryCount(for: queuedMessage.message.id)
            }
        }
        
        saveConversations()
    }
    
    // MARK: - Conversation Management
    func getOrCreateConversation(with peer: Peer) -> Conversation {
        if let existing = conversations.first(where: { $0.peerId == peer.id }) {
            return existing
        }
        
        let conversation = Conversation(peerId: peer.id, peerName: peer.displayName)
        conversations.append(conversation)
        saveConversations()
        return conversation
    }
    
    private func addMessageToConversation(_ message: Message, peerId: String, peerName: String) {
        if let index = conversations.firstIndex(where: { $0.peerId == peerId }) {
            conversations[index].addMessage(message)
        } else {
            var newConversation = Conversation(peerId: peerId, peerName: peerName)
            newConversation.addMessage(message)
            conversations.append(newConversation)
        }
    }
    
    private func updateMessageStatus(_ messageId: UUID, status: MessageStatus, in conversationId: String) {
        if let convIndex = conversations.firstIndex(where: { $0.id == conversationId }),
           let msgIndex = conversations[convIndex].messages.firstIndex(where: { $0.id == messageId }) {
            conversations[convIndex].messages[msgIndex].status = status
        }
    }
    
    func markConversationAsRead(_ conversationId: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].markAsRead()
            saveConversations()
        }
    }
    
    func deleteConversation(_ conversationId: String) {
        conversations.removeAll { $0.id == conversationId }
        messageQueue.clearQueue(for: conversationId)
        saveConversations()
    }
    
    // MARK: - Typing Indicator
    func sendTypingIndicator(to peerId: String, isTyping: Bool) {
        multipeerService.sendTypingIndicator(to: peerId, isTyping: isTyping)
    }
    
    // MARK: - Persistence
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "conversations")
        }
    }
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "conversations"),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }
    }
}
