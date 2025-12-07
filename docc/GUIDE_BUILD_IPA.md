# 📱 Guide : Builder un IPA pour iOS

## Problème rencontré

Erreur lors de `pod install` :
```
CocoaPods could not find compatible versions for pod "GoogleUtilities/Environment"
```

### Cause
Conflit de dépendances entre :
- **Firebase** nécessite `GoogleUtilities ~> 8.1`
- **mobile_scanner** nécessite `GoogleUtilities ~> 7.7`

## Solutions

### ✅ Solution 1 : Mettre à jour mobile_scanner (Recommandée)

La version actuelle `mobile_scanner: ^5.2.3` est ancienne. Mettez à jour vers une version plus récente qui supporte GoogleUtilities 8.1.

1. **Modifier `pubspec.yaml` :**
```yaml
# Remplacer
mobile_scanner: ^5.2.3

# Par
mobile_scanner: ^7.1.3
```

2. **Mettre à jour les dépendances :**
```bash
flutter pub get
```

3. **Nettoyer et réinstaller les pods :**
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
pod install --repo-update
cd ..
```

### ✅ Solution 2 : Forcer GoogleUtilities dans le Podfile

Si la solution 1 ne fonctionne pas, ajoutez cette ligne dans `ios/Podfile` :

```ruby
target 'Runner' do
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Forcer GoogleUtilities pour résoudre le conflit
  pod 'GoogleUtilities', '8.1.0', :modular_headers => true
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end
```

### ✅ Solution 3 : Utiliser le script automatique

Un script a été créé pour automatiser tout le processus :

```bash
./fix_pod_install.sh
```

## 📋 Procédure complète pour builder l'IPA

### Étape 1 : Configuration de l'encodage

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

Pour rendre cette configuration permanente, ajoutez dans `~/.zshrc` ou `~/.bash_profile` :
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Étape 2 : Nettoyer le projet

```bash
cd "/Users/pegamac/development/Mobile Flutter Points-Master"
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
```

### Étape 3 : Mettre à jour les dépendances

```bash
flutter pub get
```

### Étape 4 : Installer les pods

```bash
cd ios
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
pod install --repo-update
cd ..
```

Si cela échoue, essayez :
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

### Étape 5 : Builder l'IPA

```bash
flutter build ipa
```

Ou pour spécifier des options :
```bash
flutter build ipa --release --build-number=2
```

## 🐛 Dépannage

### Erreur : "Unicode Normalization not appropriate"

**Solution :** Configurer l'encodage UTF-8
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Erreur : Conflit de dépendances GoogleUtilities

**Solution 1 :** Mettre à jour mobile_scanner vers ^7.1.3

**Solution 2 :** Forcer GoogleUtilities 8.1 dans le Podfile

### Erreur : "Pod install failed"

**Solutions :**
1. Mettre à jour CocoaPods : `sudo gem install cocoapods`
2. Nettoyer le cache : `pod cache clean --all`
3. Réinstaller : `pod deintegrate && pod install`

### Erreur : Build failed dans Xcode

**Solutions :**
1. Ouvrir `ios/Runner.xcworkspace` (pas .xcodeproj)
2. Clean Build Folder (Cmd + Shift + K)
3. Vérifier que le fichier audio `clic-square.mp3` est dans le bundle

## 📦 Localisation de l'IPA

Une fois le build réussi, l'IPA se trouve dans :
```
build/ios/ipa/Points_Points.ipa
```

## ✅ Checklist finale

- [ ] Encodage UTF-8 configuré
- [ ] Projet nettoyé (`flutter clean`)
- [ ] Dépendances mises à jour (`flutter pub get`)
- [ ] Pods installés avec succès (`pod install`)
- [ ] IPA buildé avec succès (`flutter build ipa`)
- [ ] Fichier audio iOS dans le bundle
- [ ] Certificats de signature configurés dans Xcode

## 🔗 Ressources

- [Documentation Flutter iOS](https://docs.flutter.dev/deployment/ios)
- [CocoaPods Troubleshooting](https://guides.cocoapods.org/using/troubleshooting)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)

