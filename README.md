# Project Details

A proof of concept that shows infinitely scrolling reels with an inline messaging bar that expands up to 5 lines to fit text before allowing text scrolling. The app is sprinkled with animations and smooth transitions, and the backend has been written to intelligently use resources, so that CPU, network and memory usage are kept to a minimum.


https://github.com/user-attachments/assets/b1d17fc5-ee48-4d71-bad4-26e657b69e37


# Getting Started

The following guide shows you how to download the project from GitHub and run it in the iOS Simulator or on your own iPhone using Xcode.

> No extra dependencies (no CocoaPods, no custom install scripts). Just Xcode.

---

## Requirements

- A Mac running at least macOS Sequoia
- Xcode 16 and above
- (Optional) An iPhone or iPad for running on a real device
- A free Apple ID (needed only if you want to run on a real device)

---

## 1. Get the Code

### Option A — Clone with Git

```bash
git clone https://github.com/just-a-jazz/iOS-TikTok.git
cd iOS-TikTok
```

### Option B — Download ZIP
Go to the repository on GitHub.
Click Code → Download ZIP.
Unzip the file and open the extracted folder.

## 2. Open the Project in Xcode
Open Finder and navigate to the project folder.
Double-click the ```.xcodeproj``` file.
If you see a ```.xcworkspace``` file, open that instead.
Xcode will index the project and prepare it for building.

## 3. Run the App in the iOS Simulator
In Xcode’s top toolbar, make sure the app scheme `ReelViewer` is selected.
Choose a simulator device (e.g., iPhone 16 Pro) from the device menu.
Press Run ▶ or hit Cmd + R.
The simulator will launch and run the app automatically.

## 4. Run the App on a Physical Device (Optional)
### 4.1 Add your Apple ID to Xcode
1. Connect your iPhone/iPad to your Mac.
2. Open Xcode → Settings… → Accounts.
3. Click the + button and select Add Apple ID….
4. Sign in using your Apple ID.
### 4.2 Enable Signing
1. In the Project Navigator, select the top-level project (blue icon).
2. Under **TARGETS**, select the app.
3. Open the Signing & Capabilities tab.
4. Enable Automatically manage signing.
5. Choose your Team (your Apple ID / Personal Team).
### 4.3 Run on Your Device
1. In the device menu at the top of Xcode, select your connected iPhone/iPad.
2. Press Run ▶ (Cmd + R).
3. Xcode will build and install the app on your device.
### 4.4 Trust the Developer (first time only)
1. On your device, open Settings → General → VPN & Device Management.
2. Tap your Developer App profile.
3. Tap Trust.
4. Run the app again from Xcode.

## 5. Common Issues
### “No signing certificate” or “No provisioning profile”
- Ensure Automatically manage signing is enabled.
- Make sure a Team is selected.
### No simulators appear
- Go to Window → Devices and Simulators and confirm you have at least one iOS Simulator installed.
### Build succeeds but nothing launches
- Make sure a run destination (simulator or device) is selected in the toolbar.
