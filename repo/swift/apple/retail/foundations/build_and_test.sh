#!/bin/bash

echo "🔨 Building UnisightLib and Sample App..."

# Navigate to the foundations directory
cd /workspace/repo/swift/apple/retail/foundations

# Clean any existing build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf unisight_lib/.build
rm -rf sample_app/.build
rm -rf .build

# Build UnisightLib first
echo "📦 Building UnisightLib..."
cd unisight_lib
if command -v swift &> /dev/null; then
    swift build
    if [ $? -eq 0 ]; then
        echo "✅ UnisightLib built successfully"
    else
        echo "❌ UnisightLib build failed"
        exit 1
    fi
else
    echo "⚠️ Swift command not found, skipping build test"
fi

# Go back to foundations
cd ..

# Build sample app
echo "📱 Building Sample App..."
cd sample_app
if command -v swift &> /dev/null; then
    swift build
    if [ $? -eq 0 ]; then
        echo "✅ Sample App built successfully"
    else
        echo "❌ Sample App build failed"
        exit 1
    fi
else
    echo "⚠️ Swift command not found, skipping build test"
fi

echo "🎉 Build process completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Open the sample app in Xcode"
echo "2. Clean build folder (Product → Clean Build Folder)"
echo "3. Build the project"
echo "4. If issues persist, check the BUILD_CONFIGURATION_FIX.md guide"