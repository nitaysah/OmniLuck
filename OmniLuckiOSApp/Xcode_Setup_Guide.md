# How to Import into Xcode & Set App Logo

Since you have the source files and the generated App Icon, follow these steps to get everything running in Xcode.

## 1. Create a New Xcode Project
1.  Open **Xcode**.
2.  Click **Create New Project...**
3.  Select **iOS** -> **App** and click **Next**.
4.  **Product Name**: Enter `HoroscopeApp` (or your preferred name).
5.  **Interface**: Ensure **SwiftUI** is selected.
6.  **Language**: Ensure **Swift** is selected.
7.  Save the project in a *different* folder (e.g., `Documents`) or inside `Antigravity` if you prefer, but don't overwrite your files yet.

## 2. Import Your Code
1.  In the Xcode **Project Navigator** (left sidebar), delete the default `ContentView.swift` and `HoroscopeApp.swift` (Move to Trash).
2.  Open **Finder** and navigate to your `Antigravity` folder.
3.  Select your Swift files: `HoroscopeApp.swift`, `ContentView.swift`, `HoroscopeLogic.swift`, `ResultView.swift`, and `TestRunner.swift`.
4.  **Drag and drop** them into the Xcode Project Navigator (under the folder with your project name).
5.  In the dialog that appears, make sure **"Copy items if needed"** is Checked and your target is selected. Click **Finish**.

## 3. Set the App Icon (Crucial Step)

I have generated a **complete set of icons** for you in the `Assets.xcassets` folder in your Antigravity directory.

**To ensure it works, follow these exact steps to replace your current assets:**

1.  Open your project in **Xcode**.
2.  In the Project Navigator (left sidebar), find `Assets` (or `Assets.xcassets`).
3.  **Right-click** on `Assets` and select **Delete** -> **Move to Trash**.
4.  Open **Finder** and navigate to your `Antigravity` folder.
5.  Locate the `Assets.xcassets` folder I prepared.
6.  **Drag and drop** this entire `Assets.xcassets` folder into your Xcode Project Navigator (right where the old one was).
7.  In the confirmation dialog, check **"Copy items if needed"** and click **Finish**.

This will forcefully replace the empty icon set with the fully populated one.

## 4. Verify Project Settings
1.  Click on the top-level Project file in the Navigator (the blue icon with your app name).
2.  Select your **Target** (under "Targets").
3.  Go to the **General** tab.
4.  Scroll down to **App Icons and Launch Images**.
5.  Ensure **App Icon Source** is set to `AppIcon` (the one showing your new logo).

## 5. Build and Run
1.  Select your simulator (e.g., iPhone 15 Pro).
2.  Press **Cmd + R** or click the **Play** button.
3.  Go to the Home Screen (Shift + Cmd + H) in the simulator to see your shiny new App Icon!
