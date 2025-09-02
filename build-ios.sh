#!/bin/bash
# Build iOS debug app for the simulator. This script assumes Flutter is installed
# and Xcode command line tools are available.
set -e
echo "Installing dependencies..."
flutter pub get
echo "Building iOS debug for simulator..."
flutter build ios --debug --simulator
echo "Build complete. The .app bundle is located under build/ios/iphonesimulator/Runner.app"