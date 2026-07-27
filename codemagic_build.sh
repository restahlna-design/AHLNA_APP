#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# 1. Clean
echo "Cleaning project..."
rm -rf ios build Podfile.lock
flutter clean

# 2. Recreate iOS
echo "Recreating iOS platform..."
flutter create . --platforms ios

# 3. Inject Permissions (using PlistBuddy)
echo "Injecting permissions into Info.plist..."
PLIST="ios/Runner/Info.plist"

# Helper function to add or set keys
add_key() {
    /usr/libexec/PlistBuddy -c "$1" "$PLIST" || echo "Command failed: $1"
}

# App Transport Security & Networking
add_key "Add :NSAppTransportSecurity dict"
add_key "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool true"
add_key "Add :NSAppTransportSecurity:NSAllowsArbitraryLoadsInWebContent bool true"
add_key "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true"
add_key "Add :NSLocalNetworkUsageDescription string 'نحتاج الوصول للشبكة للاتصال بقاعدة البيانات'"

# NSLocationWhenInUseUsageDescription
add_key "Add :NSLocationWhenInUseUsageDescription string 'لتوصيل الطلب'"

# NSPhotoLibraryUsageDescription
add_key "Add :NSPhotoLibraryUsageDescription string 'لرفع الصور'"

# LSApplicationQueriesSchemes (Array)
add_key "Add :LSApplicationQueriesSchemes array"
add_key "Add :LSApplicationQueriesSchemes:0 string 'comgooglemaps'"

# 4. Install Dependencies
echo "Installing dependencies..."
flutter pub get
cd ios
pod install --repo-update
cd ..

# 5. Build Customer App
echo "Building Customer App..."
flutter build ipa --target lib/main.dart --release
mv build/ios/ipa/*.ipa Customer.ipa
echo "Customer.ipa created."

# 6. Build Admin App
echo "Building Admin App..."
# Change Display Name
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'Ahlna Admin'" "$PLIST"

flutter build ipa --target lib/admin/main_admin.dart --release
mv build/ios/ipa/*.ipa Admin.ipa
echo "Admin.ipa created."

echo "Build process completed successfully!"
