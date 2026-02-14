//
//  MultipeerService.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation
import MultipeerConnectivity
import Combine

class MultipeerService: NSObject, ObservableObject {
    static let shared = MultipeerService()
    
    // MARK: - Published Properties
    @Published var discoveredPeers: [Peer] = []
    @Published var connectedPeers: [Peer] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    
    // MARK: - Multipeer Properties
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    private let serviceType = "mesh-chat" // Max 15 chars, lowercase, no special chars
    
    // MARK: - Callbacks
    var onMessageReceived: ((EncryptedMessage, MCPeerID) -> Void)?
    var onPeerConnected: ((MCPeerID) -> Void)?
    var onPeerDisconnected: ((MCPeerID) -> Void)?
    var onTypingIndicator: ((MCPeerID, Bool) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    func initialize(displayName: String, userId: String) {
        peerID = MCPeerID(displayName: userId)
        
        session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
        
        // Setup advertiser with discovery info
        let discoveryInfo = createDiscoveryInfo(displayName: displayName, userId: userId)
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser.delegate = self
        
        // Setup browser
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    private func createDiscoveryInfo(displayName: String, userId: String) -> [String: String] {
        // Include public key for key exchange
        let publicKey = EncryptionService.shared.getPublicKey()
        return [
            "displayName": displayName,
            "userId": userId,
            "publicKey": publicKey.base64EncodedString()
        ]
    }
    
    // MARK: - Start/Stop Services
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        isAdvertising = true
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        isBrowsing = true
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        isBrowsing = false
    }
    
    func start() {
        startAdvertising()
        startBrowsing()
    }
    
    func stop() {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
    }
    
    // MARK: - Connection Management
    func invitePeer(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }
    
    func disconnect() {
        session.disconnect()
        connectedPeers.removeAll()
    }
    
    // MARK: - Messaging
    func sendMessage(_ encryptedMessage: EncryptedMessage, to peerIds: [MCPeerID]) {
        guard !peerIds.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(encryptedMessage)
            try session.send(data, toPeers: peerIds, with: .reliable)
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func sendMessage(_ encryptedMessage: EncryptedMessage, to peerUserId: String) {
        guard let peerID = session.connectedPeers.first(where: { $0.displayName == peerUserId }) else {
            print("Peer not connected: \(peerUserId)")
            return
        }
        sendMessage(encryptedMessage, to: [peerID])
    }
    
    func sendToAll(_ encryptedMessage: EncryptedMessage) {
        sendMessage(encryptedMessage, to: session.connectedPeers)
    }
    
    // MARK: - Typing Indicator
    func sendTypingIndicator(to peerUserId: String, isTyping: Bool) {
        guard let peerID = session.connectedPeers.first(where: { $0.displayName == peerUserId }) else {
            return
        }
        
        let indicator = ["type": "typing", "isTyping": isTyping ? "true" : "false"]
        if let data = try? JSONEncoder().encode(indicator) {
            try? session.send(data, toPeers: [peerID], with: .unreliable)
        }
    }
    
    // MARK: - Helper Methods
    func getPeer(for peerID: MCPeerID) -> Peer? {
        return connectedPeers.first { $0.id == peerID.displayName }
    }
    
    func isConnected(to peerUserId: String) -> Bool {
        return session.connectedPeers.contains { $0.displayName == peerUserId }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Connected to: \(peerID.displayName)")
                let peer = Peer(from: peerID, status: .connected)
                if !self.connectedPeers.contains(where: { $0.id == peer.id }) {
                    self.connectedPeers.append(peer)
                }
                self.onPeerConnected?(peerID)
                
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
                
            case .notConnected:
                print("Disconnected from: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0.id == peerID.displayName }
                self.onPeerDisconnected?(peerID)
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Try to decode as encrypted message
        if let encryptedMessage = try? JSONDecoder().decode(EncryptedMessage.self, from: data) {
            DispatchQueue.main.async {
                self.onMessageReceived?(encryptedMessage, peerID)
            }
            return
        }
        
        // Try to decode as typing indicator
        if let indicator = try? JSONDecoder().decode([String: String].self, from: data),
           indicator["type"] == "typing",
           let isTypingString = indicator["isTyping"] {
            let isTyping = isTypingString == "true"
            DispatchQueue.main.async {
                self.onTypingIndicator?(peerID, isTyping)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle streams if needed
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle resource transfer start
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle resource transfer completion
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            let displayName = info?["displayName"] ?? peerID.displayName
            var peer = Peer(id: peerID.displayName, displayName: displayName, status: .disconnected)
            
            // Extract public key if available
            if let publicKeyString = info?["publicKey"],
               let publicKey = Data(base64Encoded: publicKeyString) {
                peer.publicKey = publicKey
            }
            
            if !self.discoveredPeers.contains(where: { $0.id == peer.id }) {
                self.discoveredPeers.append(peer)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0.id == peerID.displayName }
        }
    }
}
