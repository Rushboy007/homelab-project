<div align="center">
  <img src="fotogithub/IMG_8870.PNG" width="18%" />
  <img src="fotogithub/IMG_8871.PNG" width="18%" />
  <img src="fotogithub/IMG_8872.PNG" width="18%" />
  <img src="fotogithub/IMG_8873.PNG" width="18%" />
  <img src="fotogithub/IMG_8874.PNG" width="18%" />
  <br />
  <img src="fotogithub/IMG_8875.PNG" width="18%" />
  <img src="fotogithub/IMG_8876.PNG" width="18%" />
  <img src="fotogithub/IMG_8877.jpg" width="18%" />
  <img src="fotogithub/IMG_8878.PNG" width="18%" />
  <img src="fotogithub/IMG_8879.jpg" width="18%" />
</div>

<p align="center">
  <b>🌍 Supported Languages: English, Italian, French, Spanish, German</b>
</p>

<br />


# 🏠 Homelab Dashboard App

A beautifully crafted, fully native iOS dashboard for monitoring and managing your personal Homelab ecosystem. Built with a focus on premium aesthetics, this app seamlessly connects to your local services to provide real-time status updates and deep integrations, completely re-engineered in pure SwiftUI.

## ✨ Core Features

- **Premium Native UI**: High-end visual design utilizing authentic native iOS `.glassEffect` components, SF Symbols, and natural, fluid navigation structures.
- **Advanced Service Monitoring**: Actively verify the status of your local services in real time. Maintain individual status connections to your entire network stack (Proxmox, Pi-hole, Beszel, TrueNAS, etc.).
- **Smart Fallback URLs**: Configurable internal (Local IP) and external (Cloudflare Tunnels/DDNS) URLs that auto-switch based on your current network accessibility.
- **Native Gitea Integration**: Browse your Git repositories, check heatmap contribution activity, view latest commits, and read code files natively with full syntax highlighting. Includes customizable sorting (Recent / A-Z) and counts total branches.
- **Portainer Integration**: Monitor your Docker node environments, view running containers, check resource limits, and instantly restart or stop containers directly from your iPhone (Secured via API Keys). 
- **Pi-hole API Connectivity**: Monitor your DNS queries in real time, view blocked domains metrics, and temporarily disable tracking blocking (e.g., for 5 minutes) via quick action buttons.

## 🛠 Tech Stack

- **Framework**: Native [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- **Language**: [Swift 6](https://swift.org)
- **Networking**: Configurable Async/Await custom REST clients with offline caching and native `URLSession` routing.
- **Security**: Keychain Services securely backing all credentials.
- **Platform**: iOS 17.0+ 

## 🚀 Getting Started

To run this project locally on your machine or deploy it to your iPhone:

### Prerequisites
- macOS Native Environment
- Xcode 16.0+
- An Apple Developer account (Free tier is sufficient for direct installation)
- A connected iPhone (for physical device testing)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <YOUR_GIT_URL>
   cd Homelab
   ```

2. **Open the Project:**
   Double-click the `HomelabSwift/Homelab.xcodeproj` file to open the project tightly coupled in Xcode.

3. **Build & Run:**
   Select your connected iOS Device from the top device dropdown in Xcode, and press `Cmd + R` (Run) to build and install the application directly onto your iPhone.

## 🌍 Language Support
The app features comprehensive native localization support for 5 languages: English 🇺🇸, Italian 🇮🇹, French 🇫🇷, Spanish 🇪🇸, and German 🇩🇪. It automatically detects your device's system language and adapts the interface seamlessly via Swift's String Catalogs.

## 📝 License
This project is meant for personal homelab use. Build, tweak, and enjoy your beautiful dashboard!
