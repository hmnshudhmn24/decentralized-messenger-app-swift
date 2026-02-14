//
//  MessageQueue.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation

class MessageQueue: ObservableObject {
    static let shared = MessageQueue()
    
    @Published private(set) var queuedMessages: [QueuedMessage] = []
    
    private let maxQueueSize = 1000
    private let maxRetries = 5
    private let retryInterval: TimeInterval = 30
    
    private var retryTimer: Timer?
    
    private init() {
        loadQueue()
        startRetryTimer()
    }
    
    // MARK: - Queue Management
    func enqueue(_ message: Message, for peerId: String) {
        let queuedMessage = QueuedMessage(
            message: message,
            peerId: peerId,
            retryCount: 0,
            queuedAt: Date()
        )
        
        queuedMessages.append(queuedMessage)
        
        // Enforce max queue size
        if queuedMessages.count > maxQueueSize {
            queuedMessages.removeFirst()
        }
        
        saveQueue()
    }
    
    func dequeue(messageId: UUID) {
        queuedMessages.removeAll { $0.message.id == messageId }
        saveQueue()
    }
    
    func getQueuedMessages(for peerId: String) -> [QueuedMessage] {
        return queuedMessages.filter { $0.peerId == peerId }
    }
    
    func incrementRetryCount(for messageId: UUID) {
        if let index = queuedMessages.firstIndex(where: { $0.message.id == messageId }) {
            queuedMessages[index].retryCount += 1
            
            // Remove if max retries reached
            if queuedMessages[index].retryCount >= maxRetries {
                queuedMessages.remove(at: index)
            }
            
            saveQueue()
        }
    }
    
    func clearQueue(for peerId: String) {
        queuedMessages.removeAll { $0.peerId == peerId }
        saveQueue()
    }
    
    func clearAll() {
        queuedMessages.removeAll()
        saveQueue()
    }
    
    // MARK: - Retry Logic
    private func startRetryTimer() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: retryInterval, repeats: true) { [weak self] _ in
            self?.attemptRetry()
        }
    }
    
    private func attemptRetry() {
        // Notify subscribers to retry sending queued messages
        // This will be handled by ChatViewModel
        NotificationCenter.default.post(name: .retryQueuedMessages, object: nil)
    }
    
    // MARK: - Persistence
    private func saveQueue() {
        if let encoded = try? JSONEncoder().encode(queuedMessages) {
            UserDefaults.standard.set(encoded, forKey: "messageQueue")
        }
    }
    
    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: "messageQueue"),
           let decoded = try? JSONDecoder().decode([QueuedMessage].self, from: data) {
            queuedMessages = decoded
        }
    }
    
    deinit {
        retryTimer?.invalidate()
    }
}

// MARK: - Queued Message
struct QueuedMessage: Identifiable, Codable {
    var id: UUID { message.id }
    let message: Message
    let peerId: String
    var retryCount: Int
    let queuedAt: Date
}

// MARK: - Notification Names
extension Notification.Name {
    static let retryQueuedMessages = Notification.Name("retryQueuedMessages")
}
