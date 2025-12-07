#!/bin/bash

# Script pour résoudre les problèmes de pod install et builder l'IPA

echo "🔧 Résolution des problèmes CocoaPods et build IPA"
echo "=================================================="

# Configuration UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Aller dans le répertoire du projet
cd "$(dirname "$0")"

echo ""
echo "1️⃣  Nettoyage du projet Flutter..."
flutter clean

echo ""
echo "2️⃣  Récupération des dépendances Flutter..."
flutter pub get

echo ""
echo "3️⃣  Nettoyage des pods iOS..."
cd ios
rm -rf Pods Podfile.lock .symlinks Flutter/Flutter.framework Flutter/Flutter.podspec

echo ""
echo "4️⃣  Installation des pods (avec encodage UTF-8)..."
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Tentative 1 : Installation normale
if pod install --repo-update; then
    echo "✅ Pod install réussi !"
else
    echo "⚠️  Pod install a échoué, tentative avec résolution de conflit..."
    
    # Tentative 2 : Forcer la résolution avec --verbose pour voir l'erreur
    pod install --repo-update --verbose || {
        echo "❌ Échec de pod install"
        echo ""
        echo "Solutions possibles :"
        echo "1. Mettez à jour mobile_scanner dans pubspec.yaml vers ^7.1.3"
        echo "2. Ou forcez GoogleUtilities 8.1 dans le Podfile"
        echo ""
        exit 1
    }
fi

cd ..

echo ""
echo "5️⃣  Build de l'application iOS..."
flutter build ios --release

echo ""
echo "6️⃣  Création de l'IPA..."
flutter build ipa

echo ""
echo "✅ Build terminé !"
echo "📦 L'IPA se trouve dans : build/ios/ipa/"

