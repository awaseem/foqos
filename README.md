<p align="center">
  <img src="./Foqos/Assets.xcassets/AppIcon.appiconset/AppIcon~ios-marketing.png" width="250" style="border-radius: 40px;">
</p>

<p align="center">
  <a href="https://apps.apple.com/ca/app/foqos/id6736793117">
    <img src="https://img.shields.io/badge/App_Store-000000?style=for-the-badge&logo=app-store&logoColor=white" alt="App Store">
  </a>
</p>

<h1 align="center">Foqos</h1>

<p align="center">
  <strong>Focus through physical blocking</strong>
</p>

<p align="center">
  Foqos allows you to lock distracting apps behind the tap of an NFC tag, helping you stay focused and build better digital habits.
</p>

---

## ✨ Features

- **🏷️ NFC-Based Blocking**: Use NFC tags to start and stop app blocking sessions
- **📱 Customizable Profiles**: Create multiple blocking profiles for different scenarios (work, study, sleep, etc.)
- **📊 Habit Tracking**: Visual tracking of your blocked sessions to monitor your focus habits
- **⏸️ Break Functionality**: Take breaks during blocking sessions when needed
- **🔄 Live Activities**: Real-time updates on your Lock Screen showing blocking status
- **🏠 Widgets**: Home Screen widgets to quickly see your blocking status
- **🔗 Universal Links**: Deep linking support for automation and shortcuts
- **🌙 Background Tasks**: Continues working even when the app is closed
- **💡 Smart Strategies**: Multiple blocking strategies to fit your workflow

## 📋 Requirements

- iOS 16.0+
- iPhone with NFC capability
- Screen Time permissions (for app blocking functionality)

## 🚀 Getting Started

### From the App Store

1. Download Foqos from the [App Store](https://apps.apple.com/ca/app/foqos/id6736793117)
2. Grant Screen Time permissions when prompted
3. Create your first blocking profile
4. Set up your NFC tags and start focusing!

### Setting Up NFC Tags

1. Purchase NFC tags (NTAG213 or similar recommended)
2. In Foqos, create a blocking profile
3. Use the NFC writing feature to program your tags
4. Place tags in strategic locations (desk, study area, etc.)
5. Tap to start/stop blocking sessions

## 🛠️ Development

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ SDK
- Swift 5.9+
- Apple Developer Account (for Screen Time and NFC entitlements)

### Building the Project

```bash
git clone https://github.com/awaseem/foqos.git
cd foqos
open foqos.xcodeproj
```

### Project Structure

```
foqos/
├── Foqos/                    # Main app target
│   ├── Views/               # SwiftUI views
│   ├── Modals/              # Data models
│   ├── Components/          # Reusable UI components
│   ├── Utils/               # Utility functions
│   └── Intents/             # App Intents & Shortcuts
├── FoqosWidget/             # Widget extension
└── FoqosDeviceMonitor/      # Device monitoring extension
```

### Key Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Local data persistence
- **Family Controls** - App blocking functionality
- **Core NFC** - NFC tag reading/writing
- **BackgroundTasks** - Background processing
- **Live Activities** - Dynamic Island and Lock Screen updates
- **WidgetKit** - Home Screen widgets
- **App Intents** - Shortcuts and automation support

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**
2. **Make your changes** and test as much as you can
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Open a Pull Request**

### Contribution Guidelines

- Follow Swift coding conventions
- Update documentation as needed
- Test on multiple iOS versions when possible

## 🐛 Issues & Support

Having trouble? We're here to help!

- **Bug Reports**: [Open an issue](https://github.com/awaseem/foqos/issues) with detailed steps to reproduce
- **Feature Requests**: Share your ideas via [GitHub Issues](https://github.com/awaseem/foqos/issues)
- **Questions**: Use GitHub Discussions for general questions

When reporting issues, please include:

- iOS version
- Device model
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [App Store](https://apps.apple.com/ca/app/foqos/id6736793117)
- [GitHub Issues](https://github.com/awaseem/foqos/issues)
- [Support the Project](https://apps.apple.com/ca/app/foqos/id6736793117) (via in-app purchases)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/awaseem">Ali Waseem</a>
</p>
