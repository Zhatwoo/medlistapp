#!/bin/bash

echo "🔍 Getting SHA-1 Fingerprint..."
echo ""

# Method 1: Using keytool (if Java is installed)
if command -v keytool &> /dev/null; then
    echo "Method 1: Using keytool..."
    SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -i "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')
    if [ ! -z "$SHA1" ]; then
        echo "✅ SHA-1: $SHA1"
        echo ""
        echo "📋 Copy this to Firebase Console:"
        echo "$SHA1"
        exit 0
    fi
fi

# Method 2: Using Gradle (if in Android directory)
if [ -f "medlistapp/android/gradlew" ]; then
    echo "Method 2: Using Gradle..."
    cd medlistapp/android
    SHA1=$(./gradlew signingReport 2>/dev/null | grep -A 5 "Variant: debug" | grep -i "SHA1" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')
    if [ ! -z "$SHA1" ]; then
        echo "✅ SHA-1: $SHA1"
        echo ""
        echo "📋 Copy this to Firebase Console:"
        echo "$SHA1"
        exit 0
    fi
fi

# Method 3: Manual instructions
echo "⚠️  Could not automatically get SHA-1"
echo ""
echo "Please run one of these commands manually:"
echo ""
echo "Option 1 (keytool):"
echo "  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1"
echo ""
echo "Option 2 (Gradle):"
echo "  cd medlistapp/android"
echo "  ./gradlew signingReport"
echo "  (Look for SHA1 under 'Variant: debug')"
echo ""
echo "Option 3 (Flutter):"
echo "  cd medlistapp"
echo "  flutter build apk --debug"
echo "  (Check the build output for signing information)"



