#!/bin/bash

echo "🧹 Cleaning build artifacts..."

# Remove any .build directories
find . -name ".build" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove any DerivedData references (if they exist)
find . -name "DerivedData" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove any .swiftpm directories
find . -name ".swiftpm" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove any build artifacts
find . -name "*.o" -delete 2>/dev/null || true
find . -name "*.d" -delete 2>/dev/null || true

echo "✅ Build cache cleaned!"
echo ""
echo "📋 Next steps:"
echo "1. Open your project in Xcode"
echo "2. Go to Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. Try building again"
echo ""
echo "If you're still seeing the OTLPExporters.swift error, try:"
echo "- Closing Xcode completely"
echo "- Reopening the project"
echo "- Clean Build Folder again"