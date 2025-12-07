# 🔧 Correction de l'erreur AppIcon

## Problème

```
Error (Xcode): None of the input catalogs contained a matching stickers icon set or app icon set named "AppIcon".
```

## Cause

La structure de `AppIcon` dans `Assets.xcassets` n'est pas correcte. Xcode cherche un format standard d'icône d'application.

## Solution

Il y a deux solutions possibles :

### Solution 1 : Créer un AppIcon standard (Recommandée)

Xcode a besoin d'un format d'icône standard. Vous devez :

1. **Ouvrir Xcode** :
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Dans Xcode** :
   - Sélectionnez `Runner` dans le navigateur de projet
   - Allez dans l'onglet `Assets.xcassets`
   - Supprimez le dossier `AppIcon` actuel (clic droit → Delete)
   - Cliquez sur le bouton `+` en bas
   - Sélectionnez `New iOS App Icon`
   - Cela créera un nouveau AppIcon standard

3. **Ajouter vos icônes** :
   - Glissez vos images d'icônes aux tailles appropriées dans le nouveau AppIcon
   - Les tailles nécessaires sont affichées dans Xcode

### Solution 2 : Corriger la structure actuelle

Si vous voulez garder votre structure actuelle, vous devez créer un `Contents.json` correct qui référence vos images.

Le problème est que votre structure a :
- Un dossier `Assets/` avec des images
- Un dossier `icon.dataset/` avec un format moderne

Xcode cherche un format standard avec des images directement dans AppIcon ou référencées correctement.

## Instructions rapides

1. Ouvrez Xcode : `open ios/Runner.xcworkspace`
2. Allez dans Assets.xcassets
3. Supprimez le AppIcon actuel
4. Créez un nouveau AppIcon via le bouton `+`
5. Ajoutez vos icônes aux bonnes tailles

## Tailles d'icônes nécessaires pour iOS

- 20x20 @2x et @3x (Notifications)
- 29x29 @2x et @3x (Settings)
- 40x40 @2x et @3x (Spotlight)
- 60x60 @2x et @3x (App)
- 1024x1024 @1x (App Store)

