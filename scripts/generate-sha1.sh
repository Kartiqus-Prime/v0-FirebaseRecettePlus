#!/bin/bash

echo "🔑 Génération du SHA-1 pour le debug keystore..."

# Méthode 1: Avec keytool (recommandée)
echo "📍 Méthode 1: keytool"
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

echo ""
echo "📍 Méthode 2: Gradle signingReport"
cd android
./gradlew signingReport | grep SHA1

echo ""
echo "📍 Méthode 3: Keystore local"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

echo ""
echo "✅ Copiez le SHA-1 et ajoutez-le dans Firebase Console"
echo "🔗 https://console.firebase.google.com/project/recette-plus-app/settings/general"
