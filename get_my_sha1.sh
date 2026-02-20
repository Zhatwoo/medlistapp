#!/bin/bash

echo "🔍 Getting your SHA-1 Fingerprint..."
echo ""

# Check if Java is available
if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed!"
    echo ""
    echo "Please install Java first:"
    echo "  brew install openjdk@17"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ keytool is not found!"
    echo "Java JDK is required (not just JRE)"
    exit 1
fi

# Check if keystore exists
KEYSTORE_PATH="$HOME/.android/debug.keystore"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Debug keystore not found at: $KEYSTORE_PATH"
    echo ""
    echo "The keystore will be created on first build."
    echo "Try: cd medlistapp && flutter build apk --debug"
    exit 1
fi

echo "✅ Keystore found: $KEYSTORE_PATH"
echo ""
echo "Extracting SHA-1..."
echo ""

# Get SHA-1
SHA1=$(keytool -list -v -keystore "$KEYSTORE_PATH" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -i "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')

if [ -z "$SHA1" ]; then
    echo "❌ Could not extract SHA-1"
    echo ""
    echo "Trying full output..."
    keytool -list -v -keystore "$KEYSTORE_PATH" -alias androiddebugkey -storepass android -keypass android 2>&1 | grep -A 2 -i "SHA"
    exit 1
fi

echo "✅ SHA-1 Found!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 COPY THIS TO FIREBASE CONSOLE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$SHA1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Go to Firebase Console → Project Settings → Your apps"
echo "2. Click on your Android app"
echo "3. Click 'Add fingerprint'"
echo "4. Paste the SHA-1 above"
echo "5. Click 'Save'"
echo "6. Download updated google-services.json"
echo "7. Replace medlistapp/android/app/google-services.json"
echo "8. Rebuild: flutter clean && flutter run"



