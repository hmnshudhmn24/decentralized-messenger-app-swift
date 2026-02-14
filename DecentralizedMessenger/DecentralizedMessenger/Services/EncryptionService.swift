//
//  EncryptionService.swift
//  DecentralizedMessenger
//
//  Copyright © 2026 Decentralized Messenger Swift. All rights reserved.
//  Licensed under the Apache License, Version 2.0

import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()
    
    private var privateKey: Curve25519.KeyAgreement.PrivateKey!
    private var sharedSecrets: [String: SymmetricKey] = [:] // PeerID -> SharedSecret
    
    private init() {
        loadOrGenerateKeys()
    }
    
    // MARK: - Key Management
    private func loadOrGenerateKeys() {
        // Try to load from Keychain
        if let keyData = KeychainHelper.load(key: "privateKey") {
            do {
                privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
                print("Loaded existing private key")
            } catch {
                generateNewKeys()
            }
        } else {
            generateNewKeys()
        }
    }
    
    private func generateNewKeys() {
        privateKey = Curve25519.KeyAgreement.PrivateKey()
        
        // Save to Keychain
        let keyData = privateKey.rawRepresentation
        KeychainHelper.save(key: "privateKey", data: keyData)
        print("Generated new key pair")
    }
    
    func getPublicKey() -> Data {
        return privateKey.publicKey.rawRepresentation
    }
    
    // MARK: - Key Exchange
    func deriveSharedSecret(peerPublicKey: Data, peerId: String) -> Bool {
        do {
            let peerPublic = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublic)
            
            // Derive symmetric key using HKDF
            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data(),
                sharedInfo: Data(),
                outputByteCount: 32
            )
            
            sharedSecrets[peerId] = symmetricKey
            print("Derived shared secret for peer: \(peerId)")
            return true
        } catch {
            print("Failed to derive shared secret: \(error)")
            return false
        }
    }
    
    // MARK: - Encryption
    func encrypt(message: Message, for peerId: String) throws -> EncryptedMessage {
        guard let sharedSecret = sharedSecrets[peerId] else {
            throw EncryptionError.noSharedSecret
        }
        
        // Encode message content
        let messageData = try JSONEncoder().encode(message.content)
        
        // Generate nonce
        let nonce = AES.GCM.Nonce()
        
        // Encrypt
        let sealedBox = try AES.GCM.seal(messageData, using: sharedSecret, nonce: nonce)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        // Create encrypted message
        return EncryptedMessage(
            from: message,
            encryptedData: combined,
            nonce: Data(nonce)
        )
    }
    
    // MARK: - Decryption
    func decrypt(encryptedMessage: EncryptedMessage, from peerId: String) throws -> MessageContent {
        guard let sharedSecret = sharedSecrets[peerId] else {
            throw EncryptionError.noSharedSecret
        }
        
        // Create sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedMessage.encryptedData)
        
        // Decrypt
        let decryptedData = try AES.GCM.open(sealedBox, using: sharedSecret)
        
        // Decode message content
        let content = try JSONDecoder().decode(MessageContent.self, from: decryptedData)
        
        return content
    }
    
    // MARK: - Cleanup
    func clearSharedSecret(for peerId: String) {
        sharedSecrets.removeValue(forKey: peerId)
    }
    
    func clearAllSecrets() {
        sharedSecrets.removeAll()
    }
}

// MARK: - Encryption Errors
enum EncryptionError: Error, LocalizedError {
    case noSharedSecret
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    
    var errorDescription: String? {
        switch self {
        case .noSharedSecret:
            return "No shared secret established with peer"
        case .encryptionFailed:
            return "Failed to encrypt message"
        case .decryptionFailed:
            return "Failed to decrypt message"
        case .invalidKey:
            return "Invalid encryption key"
        }
    }
}
