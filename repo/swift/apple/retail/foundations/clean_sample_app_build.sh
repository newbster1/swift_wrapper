#!/bin/bash

echo "🧹 Cleaning UnisightSampleApp build cache..."

# Navigate to the sample app directory
cd /workspace/repo/swift/apple/retail/foundations/sample_app

# Remove Xcode build artifacts
echo "Removing Xcode build artifacts..."
rm -rf UnisightSampleApp.xcodeproj/project.xcworkspace/xcuserdata
rm -rf UnisightSampleApp.xcodeproj/xcuserdata
rm -rf UnisightSampleApp.xcodeproj/project.xcworkspace/xcshareddata
rm -rf UnisightSampleApp.xcodeproj/project.xcworkspace/xcuserdata

# Remove DerivedData for this project
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*UnisightSampleApp*
rm -rf ~/Library/Developer/Xcode/DerivedData/*unisight*

# Remove Swift Package Manager cache
echo "Removing Swift Package Manager cache..."
rm -rf .build
rm -rf *.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# Remove any temporary files
echo "Removing temporary files..."
find . -name "*.swiftmodule" -delete
find . -name "*.swiftdoc" -delete
find . -name "*.swiftsourceinfo" -delete

echo "✅ Sample app build cache cleaned successfully!"
echo "🔄 Please rebuild the project in Xcode"