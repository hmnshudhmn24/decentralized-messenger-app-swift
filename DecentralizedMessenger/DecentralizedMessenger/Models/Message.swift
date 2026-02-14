//
//  Message.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let conversationId: String
    let senderId: String
    let senderName: String
    let content: MessageContent
    let timestamp: Date
    var status: MessageStatus
    var isRead: Bool
    
    init(
        id: UUID = UUID(),
        conversationId: String,
        senderId: String,
        senderName: String,
        content: MessageContent,
        timestamp: Date = Date(),
        status: MessageStatus = .sent,
        isRead: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.isRead = isRead
    }
}

// MARK: - Message Content
enum MessageContent: Codable, Equatable {
    case text(String)
    case voice(Data, duration: TimeInterval)
    case image(Data)
    case file(Data, filename: String, mimeType: String)
    case system(String)
    
    var displayText: String {
        switch self {
        case .text(let text):
            return text
        case .voice(_, let duration):
            return "Voice message (\(Int(duration))s)"
        case .image:
            return "📷 Photo"
        case .file(_, let filename, _):
            return "📎 \(filename)"
        case .system(let text):
            return text
        }
    }
}

// MARK: - Message Status
enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case failed
    case queued
    
    var icon: String {
        switch self {
        case .sending: return "circle.dotted"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .failed: return "exclamationmark.circle"
        case .queued: return "clock"
        }
    }
}

// MARK: - Encrypted Message (for transmission)
struct EncryptedMessage: Codable {
    let messageId: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let encryptedData: Data
    let nonce: Data
    let timestamp: Date
    
    init(from message: Message, encryptedData: Data, nonce: Data) {
        self.messageId = message.id.uuidString
        self.conversationId = message.conversationId
        self.senderId = message.senderId
        self.senderName = message.senderName
        self.encryptedData = encryptedData
        self.nonce = nonce
        self.timestamp = message.timestamp
    }
}

// MARK: - Hashable
extension Message: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
