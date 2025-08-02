# UnisightLib Build Configuration Fix

## Issue
The sample app is showing "Undefined symbol" errors for UnisightLib symbols, indicating that the library is not being built or linked properly.

## Root Cause
The UnisightLib is not being built or linked to the UnisightSampleApp properly in Xcode.

## Solution

### Step 1: Clean Build Folder
1. In Xcode, go to **Product** → **Clean Build Folder** (or press `Shift+Cmd+K`)
2. Close Xcode completely
3. Reopen the project

### Step 2: Check Target Dependencies
1. Select the **UnisightSampleApp** target in Xcode
2. Go to **Build Phases** tab
3. Expand **Target Dependencies**
4. Ensure **UnisightLib** is listed as a dependency
5. If not, click **+** and add **UnisightLib**

### Step 3: Check Link Binary With Libraries
1. In the same **Build Phases** tab
2. Expand **Link Binary With Libraries**
3. Ensure **UnisightLib.framework** or **UnisightLib** is listed
4. If not, click **+** and add it

### Step 4: Check Framework Search Paths
1. Select the **UnisightSampleApp** target
2. Go to **Build Settings** tab
3. Search for **Framework Search Paths**
4. Ensure the path to UnisightLib is included:
   ```
   $(SRCROOT)/../unisight_lib/.build/release
   ```

### Step 5: Check Swift Package Dependencies
1. Go to **File** → **Add Package Dependencies**
2. If UnisightLib is not listed, add it as a local package:
   - Click **Add Local...**
   - Navigate to `../unisight_lib`
   - Select the package

### Step 6: Build UnisightLib First
1. Select the **UnisightLib** target
2. Build it first (**Product** → **Build** or `Cmd+B`)
3. Then build the **UnisightSampleApp** target

### Step 7: Check Import Statements
Ensure all necessary imports are in place:

```swift
import SwiftUI
import UnisightLib
```

### Step 8: Alternative: Use Swift Package Manager
If the above doesn't work, try adding UnisightLib as a Swift Package:

1. In the sample app's **Package.swift** or **Package Dependencies**:
```swift
dependencies: [
    .package(path: "../unisight_lib")
]
```

2. Add the dependency to the target:
```swift
targets: [
    .target(
        name: "UnisightSampleApp",
        dependencies: ["UnisightLib"]
    )
]
```

## Verification
After applying these fixes:
1. Clean build folder again
2. Build the project
3. Check that all symbols are resolved

## Common Issues and Solutions

### Issue: "Cannot find 'DeviceInfo' in scope"
**Solution**: Ensure `import UnisightLib` is present

### Issue: "Undefined symbol: UnisightLib.UnisightConfiguration.init"
**Solution**: Ensure UnisightLib is built and linked properly

### Issue: "SwiftUICore linking error"
**Solution**: This is a framework linking issue - clean build folder and rebuild

### Issue: "TLS version warning"
**Solution**: This is just a warning - update Info.plist to use TLSv1.2 or higher

## Final Steps
1. Clean build folder
2. Build UnisightLib target first
3. Build UnisightSampleApp target
4. Run the app

The library should now compile and link properly.