#!/bin/bash
# Script to get SHA-1 fingerprint for Google Sign-In

echo "Getting SHA-1 fingerprint for debug keystore..."
echo ""

# Try to get SHA-1 from debug keystore
SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -A 1 "SHA1:" | grep -o "[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]")

if [ -z "$SHA1" ]; then
    echo "Could not find SHA-1 automatically."
    echo ""
    echo "Please run this command manually:"
    echo "keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
    echo ""
    echo "Or use Gradle:"
    echo "cd android && ./gradlew signingReport"
else
    echo "SHA-1 Fingerprint:"
    echo "$SHA1"
    echo ""
    echo "Next steps:"
    echo "1. Go to Firebase Console: https://console.firebase.google.com/"
    echo "2. Select your project: medlistapp"
    echo "3. Go to Project Settings > Your apps > Android app"
    echo "4. Click 'Add fingerprint' and paste the SHA-1 above"
    echo "5. Download updated google-services.json"
    echo "6. Replace medlistapp/android/app/google-services.json"
fi



