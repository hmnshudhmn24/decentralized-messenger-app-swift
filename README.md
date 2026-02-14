# 🔗 Decentralized Messenger Swift

A fully decentralized iOS messaging app that works without internet or servers. Connect directly with nearby users via WiFi and Bluetooth using Apple's Multipeer Connectivity framework. All messages are end-to-end encrypted and work completely offline.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)
![P2P](https://img.shields.io/badge/Architecture-P2P-purple.svg)

## 🌟 Features

### Core Messaging
- **Zero-Server Architecture**: True peer-to-peer, no central server required
- **Offline First**: Works without internet connection
- **End-to-End Encryption**: AES-256-GCM encryption with CryptoKit
- **Real-time Messaging**: Instant delivery when peers are nearby
- **Group Chats**: Support for up to 8 simultaneous peers
- **Message Queuing**: Automatic delivery when peer comes back online

### Rich Communication
- **Text Messages**: Standard chat messaging
- **Voice Messages**: Record and send voice notes
- **File Sharing**: Share photos, documents, videos up to 100MB
- **Typing Indicators**: See when someone is typing
- **Read Receipts**: Know when messages are delivered and read
- **Message Reactions**: React to messages with emojis

### User Experience
- **Discovery**: Automatic peer discovery via WiFi/Bluetooth
- **Profiles**: Customizable display name and avatar
- **Dark Mode**: Full dark mode support
- **Notifications**: Local notifications for new messages
- **Search**: Search messages and conversations
- **Export**: Export chat history

## 🛠️ Tech Stack

### Frameworks
- **SwiftUI**: Modern declarative UI
- **Multipeer Connectivity**: P2P networking over WiFi/Bluetooth
- **CryptoKit**: End-to-end encryption (AES-256-GCM, X25519)
- **AVFoundation**: Voice message recording/playback
- **Combine**: Reactive programming
- **Core Data**: Local message persistence
- **UserNotifications**: Local notifications

### Architecture
- **MVVM**: Clean separation of concerns
- **Repository Pattern**: Data access abstraction
- **Singleton Services**: Centralized connectivity management
- **Async/Await**: Modern concurrency

## 📋 Requirements

- iOS 16.0+
- Xcode 15.0+
- Physical iOS devices (2+ for testing P2P features)
- WiFi or Bluetooth enabled
- Same WiFi network or Bluetooth range

**Note**: Multipeer Connectivity requires physical devices and does NOT work in the iOS Simulator.

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/decentralized-messenger-swift.git
cd decentralized-messenger-swift
```

2. Open the project:
```bash
cd DecentralizedMessenger
open DecentralizedMessenger.xcodeproj
```

3. Configure your development team in Xcode project settings

4. Build and run on **two or more physical iOS devices**

### First Launch

1. Launch app on first device
2. Set your display name
3. Enable Bluetooth and WiFi
4. Launch app on second device
5. Devices will automatically discover each other
6. Tap on discovered peer to start chatting!

## 📱 Usage

### Starting a Conversation

1. Open the app
2. Nearby peers appear in the "Nearby" list
3. Tap on a peer to start chatting
4. Messages are automatically encrypted and sent

### Sending Messages

- **Text**: Type and tap send
- **Voice**: Tap and hold microphone icon
- **Files**: Tap attachment icon, select file
- **Photos**: Tap camera icon

### Group Chats

1. Multiple peers connect automatically
2. Messages broadcast to all connected peers
3. Each peer sees all messages in real-time

### Offline Mode

1. Messages queue automatically when peer is offline
2. Auto-delivery when peer comes back in range
3. Queue persists across app restarts

## 🏗️ Architecture

```
DecentralizedMessenger/
├── App/
│   └── DecentralizedMessengerApp.swift
├── Models/
│   ├── Message.swift              # Message data model
│   ├── Peer.swift                 # Peer information
│   ├── Conversation.swift         # Chat conversation
│   └── MessageType.swift          # Text/Voice/File types
├── Services/
│   ├── MultipeerService.swift     # P2P connectivity
│   ├── EncryptionService.swift    # E2E encryption
│   ├── MessageQueue.swift         # Offline message queue
│   ├── VoiceRecorder.swift        # Voice message recording
│   ├── FileManager+Extension.swift # File handling
│   └── NotificationService.swift  # Local notifications
├── ViewModels/
│   ├── ConversationListViewModel.swift
│   ├── ChatViewModel.swift
│   └── PeerDiscoveryViewModel.swift
├── Views/
│   ├── ConversationListView.swift
│   ├── ChatView.swift
│   ├── MessageBubble.swift
│   ├── VoiceMessageView.swift
│   ├── PeerDiscoveryView.swift
│   └── SettingsView.swift
├── Utilities/
│   ├── KeychainHelper.swift       # Secure key storage
│   ├── Extensions.swift           # Helper extensions
│   └── Constants.swift            # App constants
└── Persistence/
    └── PersistenceController.swift # Core Data stack
```

## 🔒 Security

### Encryption

- **Algorithm**: AES-256-GCM (Galois/Counter Mode)
- **Key Exchange**: X25519 Elliptic Curve Diffie-Hellman
- **Key Storage**: iOS Keychain with hardware encryption
- **Forward Secrecy**: New session keys for each conversation
- **Authentication**: Message authentication codes (MAC)

### Privacy

- **No Server**: Messages never touch a server
- **No Cloud**: All data stored locally on device
- **No Tracking**: Zero analytics or tracking
- **Ephemeral**: Optional self-destructing messages
- **Local Only**: Messages stay on your device

### Security Features

```swift
// Each message is encrypted with:
// - Unique nonce (never reused)
// - AES-256-GCM encryption
// - Authentication tag for integrity
// - Encrypted with shared secret from key exchange
```

## 🌐 Networking

### Multipeer Connectivity

- **Discovery**: Automatic via Bonjour over WiFi/Bluetooth
- **Range**: WiFi ~100m, Bluetooth ~10m
- **Peers**: Up to 8 simultaneous connections
- **Bandwidth**: ~1-2 MB/s typical
- **Reliability**: Automatic retry and acknowledgment

### Connection Flow

1. **Advertise**: Device advertises presence
2. **Browse**: Discover nearby peers
3. **Invite**: Send connection invitation
4. **Accept**: Peer accepts invitation
5. **Connected**: Secure session established
6. **Messaging**: Encrypted messages flow

### Offline Queue

```
┌─────────────┐
│   Message   │
│   Created   │
└──────┬──────┘
       │
       ▼
   Peer Online? ──Yes──▶ Send Immediately
       │
       No
       │
       ▼
┌─────────────┐
│ Add to      │
│ Queue       │
└──────┬──────┘
       │
       ▼
   Peer Returns ────▶ Auto Deliver
```

## 🎨 Features Deep Dive

### Voice Messages

- **Recording**: AVAudioRecorder with AAC codec
- **Compression**: Optimized for low bandwidth
- **Playback**: Inline playback with waveform visualization
- **Duration**: Up to 5 minutes per message

### File Sharing

- **Types**: Images, videos, documents, PDFs
- **Size Limit**: 100 MB per file
- **Compression**: Automatic image compression
- **Progress**: Real-time transfer progress
- **Chunking**: Large files sent in chunks

### Message Types

```swift
enum MessageType {
    case text(String)
    case voice(URL, duration: TimeInterval)
    case image(Data)
    case file(URL, filename: String, size: Int64)
    case system(String)
}
```

## 🔧 Configuration

### Multipeer Service ID

Edit `MultipeerService.swift` to customize:
```swift
private let serviceType = "mesh-chat" // Max 15 characters
```

### Encryption Settings

Configure in `EncryptionService.swift`:
```swift
// Default: AES-256-GCM
// Nonce size: 12 bytes
// Tag size: 16 bytes
```

### Message Queue Settings

```swift
// Max queue size: 1000 messages
// Retry interval: 30 seconds
// Max retries: 5
```

## 🧪 Testing

### Unit Tests
```bash
⌘ + U in Xcode
```

### Testing P2P

**Minimum Setup**: 2 physical iOS devices

1. Install on Device A and Device B
2. Enable WiFi/Bluetooth on both
3. Launch app on both devices
4. Devices should discover each other
5. Send test messages

**Recommended**: Test with 3-5 devices for group chat

### Common Issues

**Peers not discovering:**
- Check WiFi/Bluetooth enabled
- Verify on same WiFi network
- Check firewall settings
- Restart both devices

**Messages not sending:**
- Verify connection status
- Check encryption keys initialized
- Review console logs

## 📊 Performance

- **Message Latency**: <100ms in good conditions
- **Discovery Time**: 2-5 seconds
- **Battery Impact**: ~5-10% per hour active use
- **Storage**: ~1MB per 1000 messages
- **Memory**: ~50-100MB typical usage

## 🗺️ Roadmap

### Phase 1 (Current)
- [x] Basic P2P messaging
- [x] End-to-end encryption
- [x] Voice messages
- [x] File sharing
- [x] Offline queue

### Phase 2
- [ ] Video messages
- [ ] Voice/video calls
- [ ] Message editing
- [ ] Message search
- [ ] Custom themes

### Phase 3
- [ ] Mesh routing (relay through peers)
- [ ] QR code connection
- [ ] Backup/restore
- [ ] Advanced encryption options
- [ ] Desktop companion app

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This is educational software demonstrating P2P messaging concepts. While it implements strong encryption, it has not undergone a professional security audit. Use at your own risk for non-critical communications.

## 🙏 Acknowledgments

- Apple's Multipeer Connectivity framework
- CryptoKit for encryption
- SwiftUI and Combine
- Open source Swift community

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/decentralized-messenger-swift/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/decentralized-messenger-swift/discussions)

## 🎯 Use Cases

- **Privacy-focused messaging**
- **Offline/remote area communication**
- **Local team collaboration**
- **Conference/event networking**
- **Emergency communication**
- **Protest coordination**
- **Learning P2P networking**

## 🔬 Technical Details

### Why Multipeer Connectivity?

- ✅ Works offline
- ✅ No server required
- ✅ Built into iOS
- ✅ WiFi + Bluetooth
- ✅ Automatic discovery
- ✅ Reliable delivery

### Encryption Details

```
Key Exchange: X25519 ECDH
Symmetric Encryption: AES-256-GCM
Key Derivation: HKDF-SHA256
Session Keys: Unique per conversation
Forward Secrecy: Session keys not persisted
```

---

**Built with ❤️ and Swift | Decentralized. Encrypted. Free.**

🔗 **No servers. No tracking. Just pure P2P messaging.**
