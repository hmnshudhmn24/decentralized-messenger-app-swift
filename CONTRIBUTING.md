# Contributing to Decentralized Messenger Swift

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ device (Multipeer Connectivity requires physical devices)
- Git

### Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/decentralized-messenger-swift.git`
3. Open `DecentralizedMessenger.xcodeproj` in Xcode
4. Build and run on physical devices (minimum 2 devices for testing)

## How to Contribute

### Reporting Bugs
- Check existing issues first
- Include device model, iOS version, and app version
- Provide steps to reproduce
- Include screenshots/logs if applicable

### Feature Requests
- Open an issue with [Feature Request] prefix
- Describe the feature and use case
- Explain why it would be useful

### Pull Requests
1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Make your changes
3. Write/update tests
4. Update documentation
5. Commit with clear messages
6. Push and open a PR

## Code Guidelines

### Swift Style
- Follow Swift API Design Guidelines
- Use meaningful names
- Add comments for complex logic
- Keep functions focused and small

### Architecture
- Follow MVVM pattern
- Services handle business logic
- ViewModels manage state
- Views are declarative SwiftUI

### Testing
- Test on real devices (2+ devices)
- Test peer discovery and connection
- Test message encryption/decryption
- Test offline queue functionality

## Areas for Contribution

### High Priority
- Voice message implementation (AVFoundation)
- File sharing with progress tracking
- Message search functionality
- Export chat history
- Improved error handling

### Medium Priority
- Message reactions
- Read receipts
- Group chat improvements
- Dark mode optimization
- Accessibility improvements

### Advanced
- Mesh routing (relay through peers)
- Video messages
- Voice/video calls
- Message editing
- Custom encryption options

## Testing

### Manual Testing
1. Install on 2+ devices
2. Test peer discovery
3. Send messages (text, voice, files)
4. Test offline queue
5. Test encryption key exchange

### Unit Tests
```bash
⌘ + U in Xcode
```

## Documentation
- Update README for new features
- Add inline documentation
- Update CHANGELOG.md

## License
By contributing, you agree that your contributions will be licensed under Apache License 2.0.

## Questions?
Open an issue or discussion on GitHub!
