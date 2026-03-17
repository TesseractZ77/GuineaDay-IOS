<div align="center">
  
  # 🐹 GuineaDay (iOS)
  
  **A cozy, everyday companion app for you and your guinea pigs!**
  
  [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift)](https://swift.org)
  [![iOS 17](https://img.shields.io/badge/iOS-17.0+-black.svg?style=for-the-badge&logo=apple)](https://developer.apple.com/ios/)
  [![SwiftData](https://img.shields.io/badge/SwiftData-Local%20Storage-blue?style=for-the-badge)](https://developer.apple.com/xcode/swiftdata/)
  
</div>

---

## 🌟 What is GuineaDay?

**GuineaDay** is a beautifully designed, standalone iOS application built entirely in **SwiftUI** designed to make caring for your guinea pigs fun and organized. Featuring a delightful pastel "Chiikawa-inspired" aesthetic, the app stores everything locally on your device using **SwiftData**.

<br/>

### ✨ Features at a Glance

*   **🐾 Piggy Profiles:** Keep track of your guinea pigs' names, birthdays, breeds, and genders.
*   **⚖️ Health & Weight Logs:** Log weekly weigh-ins to monitor their health, visualized in an easy-to-read history list.
*   **📋 Daily Duties:** A built-in task manager for feeding, cleaning, and floor time routines. Check them off daily!
*   **📸 Memories Gallery:** Snap and save precious moments with your piggies directly to a local, private photo gallery.
*   **🎮 Game Room:** Take a break and play **Piggy Crush**, a fully functional match-3 mini-game right inside the app!

---

## 🛠 Tech Stack

This project showcases modern iOS development patterns:

*   **UI Framework:** SwiftUI (with custom styling, animations, and transitions)
*   **Data Persistence:** SwiftData (`@Model`, `@Query`, `@Environment(\.modelContext)`)
*   **Architecture:** MVVM-inspired component breakdown tailored for declarative SwiftUI
*   **Local Storage:** `FileManager` & `UserDefaults` for caching full-resolution images locally without iCloud/Firebase dependence.

---

## 🚀 Getting Started

Want to run GuineaDay on your own simulator or iPhone? It's plug-and-play!

### Prerequisites
*   A Mac running macOS Sonoma (or later).
*   Xcode 15.0 or later (required for iOS 17 and SwiftData).

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YourUsername/GuineaDay.git
   cd GuineaDay
   ```

2. **Open the project in Xcode:**
   Double-click the `GuineaDay.xcodeproj` file.

3. **Build and Run:**
   * Choose your preferred iOS Simulator (e.g., iPhone 15 Pro) from the top toolbar.
   * Press `Cmd + R` or click the Play button to build and run the app.
   
*(Note: Because this is a 100% local app using SwiftData, there are no API keys, Firebase configurations, or backend servers to set up!)*

---

## 🎨 Walkthrough

<details>
<summary><b>🏡 Dashboard</b></summary>
A welcoming home screen tracking your total piggies, pending tasks, and memories, featuring a custom bouncy Chiikawa-style Tab Bar.
</details>

<details>
<summary><b>🐾 My Piggies</b></summary>
A grid view of your furry friends. Tap on a profile to edit their details, log a new weight, and see their health history.
</details>

<details>
<summary><b>📋 Duties Manager</b></summary>
Add new tasks with priorities. Swipe to delete, tap to complete.
</details>

<details>
<summary><b>📸 Gallery</b></summary>
Uses `PhotosPicker` to save images locally via the device's `FileManager`, persisting filenames in SwiftData.
</details>

<details>
<summary><b>🎮 Piggy Crush mini-game</b></summary>
A dynamic SwiftUI-based match-3 game engine. Swap piggies, chain combos, and beat your high score before the 30-move limit!
</details>

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check out the [issues page](https://github.com/YourUsername/GuineaDay/issues).

---

<div align="center">
  <i>Built with ❤️ for Guinea Pigs everywhere.</i>
</div>
