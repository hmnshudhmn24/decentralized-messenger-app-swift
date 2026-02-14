//
//  Conversation.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation

struct Conversation: Identifiable, Codable {
    let id: String // Usually peer's userId
    let peerId: String
    let peerName: String
    var messages: [Message]
    var unreadCount: Int
    var lastMessage: Message?
    var lastActivity: Date
    var isTyping: Bool
    
    init(
        id: String? = nil,
        peerId: String,
        peerName: String,
        messages: [Message] = [],
        unreadCount: Int = 0,
        lastMessage: Message? = nil,
        lastActivity: Date = Date(),
        isTyping: Bool = false
    ) {
        self.id = id ?? peerId
        self.peerId = peerId
        self.peerName = peerName
        self.messages = messages
        self.unreadCount = unreadCount
        self.lastMessage = lastMessage
        self.lastActivity = lastActivity
        self.isTyping = isTyping
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        lastMessage = message
        lastActivity = message.timestamp
        
        // Increment unread if from peer
        if message.senderId != message.conversationId {
            unreadCount += 1
        }
        
        // Sort messages by timestamp
        messages.sort { $0.timestamp < $1.timestamp }
    }
    
    mutating func markAsRead() {
        unreadCount = 0
        for i in messages.indices {
            messages[i].isRead = true
        }
    }
    
    mutating func updateMessage(_ message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            if message.timestamp > lastActivity {
                lastMessage = message
                lastActivity = message.timestamp
            }
        }
    }
    
    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Equatable
extension Conversation: Equatable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Conversation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
