# Xcode Setup Guide - Fix UnisightLib Linking Issues

## Quick Fix for Undefined Symbols

### Option 1: Use Swift Package Manager (Recommended)

1. **Close Xcode completely**

2. **Open the sample app project in Xcode**
   - Open `sample_app/UnisightSampleApp.xcodeproj`

3. **Add UnisightLib as a Local Package**
   - Go to **File** → **Add Package Dependencies**
   - Click **Add Local...**
   - Navigate to `../unisight_lib` (relative to the sample app)
   - Select the folder and click **Add Package**

4. **Add UnisightLib to your target**
   - Select the **UnisightSampleApp** target
   - Go to **General** tab
   - Scroll down to **Frameworks, Libraries, and Embedded Content**
   - Click **+** and add **UnisightLib**

5. **Clean and Build**
   - **Product** → **Clean Build Folder** (`Shift+Cmd+K`)
   - **Product** → **Build** (`Cmd+B`)

### Option 2: Manual Framework Linking

1. **Build UnisightLib as Framework**
   - Open `unisight_lib/Package.swift` in Xcode
   - Build the project (`Cmd+B`)
   - The framework will be in `.build/release/UnisightLib.framework`

2. **Add Framework to Sample App**
   - Drag the `UnisightLib.framework` to your sample app project
   - Make sure it's added to the target

3. **Clean and Build**
   - **Product** → **Clean Build Folder**
   - **Product** → **Build**

### Option 3: Direct Source Integration (Fallback)

If the above doesn't work:

1. **Copy UnisightLib source files**
   - Copy all files from `unisight_lib/Sources/UnisightLib/` to your sample app
   - Add them to your target

2. **Add OpenTelemetry dependencies**
   - Add the OpenTelemetry Swift package to your project
   - Link the required products

## Verification

After applying any of the above solutions:

1. **Check imports are correct:**
```swift
import SwiftUI
import UnisightLib
```

2. **Test basic functionality:**
```swift
// This should compile without errors
let config = UnisightConfiguration(
    serviceName: "TestApp",
    version: "1.0.0",
    dispatcherEndpoint: "https://test.com"
)
```

3. **Check DeviceInfo access:**
```swift
// This should work
let model = DeviceInfo.model
let version = DeviceInfo.appVersion
```

## Common Issues and Solutions

### Issue: "Undefined symbol: UnisightLib.UnisightConfiguration.init"
**Solution**: Ensure UnisightLib is properly linked as a package or framework

### Issue: "Cannot find 'DeviceInfo' in scope"
**Solution**: Ensure `import UnisightLib` is present

### Issue: "SwiftUICore linking error"
**Solution**: Clean build folder and rebuild

### Issue: "Package resolution failed"
**Solution**: Check that the path to UnisightLib is correct

## Final Steps

1. **Clean build folder**
2. **Build the project**
3. **Run the app**
4. **Test telemetry functionality**

The library should now compile and link properly.