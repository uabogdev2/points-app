# 🔧 Résolution du conflit CocoaPods : Firebase vs mobile_scanner

## Problème

Conflit de dépendances entre :
- **Firebase** nécessite `GoogleUtilities ~> 8.1`
- **mobile_scanner** nécessite `GoogleUtilities ~> 7.7`

## Solutions

### Solution 1 : Forcer la version GoogleUtilities dans le Podfile (Recommandée)

Ajoutez cette ligne dans le Podfile avant `post_install` :

```ruby
target 'Runner' do
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Forcer GoogleUtilities à la version 8.1 pour résoudre le conflit
  pod 'GoogleUtilities', '8.1.0'
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end
```

### Solution 2 : Mettre à jour mobile_scanner

Mettre à jour `mobile_scanner` vers une version plus récente qui supporte GoogleUtilities 8.1 :

```yaml
# Dans pubspec.yaml
mobile_scanner: ^7.1.3  # Version plus récente
```

Puis :
```bash
flutter pub get
cd ios && pod install
```

### Solution 3 : Utiliser un fork ou une version compatible

Si aucune des solutions ci-dessus ne fonctionne, considérez :
- Mettre à jour toutes les dépendances Firebase vers les dernières versions
- Vérifier les issues GitHub de mobile_scanner pour ce conflit

## Commandes à exécuter

1. **Nettoyer le projet :**
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter clean
flutter pub get
```

2. **Configurer l'encodage UTF-8 :**
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

3. **Installer les pods :**
```bash
cd ios
pod install --repo-update
```

4. **Builder l'IPA :**
```bash
cd ..
flutter build ipa
```

