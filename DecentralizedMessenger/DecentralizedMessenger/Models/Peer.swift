//
//  Peer.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation
import MultipeerConnectivity

struct Peer: Identifiable, Hashable, Codable {
    let id: String // Peer ID
    let displayName: String
    var status: PeerStatus
    var lastSeen: Date
    var publicKey: Data?
    
    init(id: String, displayName: String, status: PeerStatus = .disconnected, lastSeen: Date = Date(), publicKey: Data? = nil) {
        self.id = id
        self.displayName = displayName
        self.status = status
        self.lastSeen = lastSeen
        self.publicKey = publicKey
    }
    
    init(from peerID: MCPeerID, status: PeerStatus = .connected) {
        self.id = peerID.displayName
        self.displayName = peerID.displayName
        self.status = status
        self.lastSeen = Date()
        self.publicKey = nil
    }
}

// MARK: - Peer Status
enum PeerStatus: String, Codable {
    case connected
    case connecting
    case disconnected
    
    var icon: String {
        switch self {
        case .connected: return "circle.fill"
        case .connecting: return "circle.dotted"
        case .disconnected: return "circle"
        }
    }
    
    var color: String {
        switch self {
        case .connected: return "green"
        case .connecting: return "orange"
        case .disconnected: return "gray"
        }
    }
}

// MARK: - Equatable
extension Peer: Equatable {
    static func == (lhs: Peer, rhs: Peer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Peer Discovery Info
struct PeerDiscoveryInfo: Codable {
    let userId: String
    let displayName: String
    let publicKey: Data
    
    var discoveryInfo: [String: String] {
        return [
            "userId": userId,
            "displayName": displayName,
            "publicKey": publicKey.base64EncodedString()
        ]
    }
    
    static func from(discoveryInfo: [String: String]?) -> PeerDiscoveryInfo? {
        guard let info = discoveryInfo,
              let userId = info["userId"],
              let displayName = info["displayName"],
              let publicKeyString = info["publicKey"],
              let publicKey = Data(base64Encoded: publicKeyString) else {
            return nil
        }
        
        return PeerDiscoveryInfo(userId: userId, displayName: displayName, publicKey: publicKey)
    }
}
