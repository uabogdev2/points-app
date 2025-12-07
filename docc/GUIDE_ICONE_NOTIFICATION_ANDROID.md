# Guide : Correction de l'icône de notification Android

## Problème

Sur certains appareils Android, l'icône de notification affiche un carré noir ou blanc au lieu de l'icône personnalisée. Cela se produit lorsque l'icône n'est pas au format monochrome requis par Android.

## Solution

Les icônes de notification Android doivent être **monochromes** (blanc transparent sur fond transparent). Android convertit automatiquement les icônes colorées en monochrome, ce qui peut donner un résultat indésirable.

### Format requis

- **Format** : PNG
- **Couleur** : Blanc transparent (#FFFFFF avec transparence)
- **Fond** : Transparent
- **Taille** : 24x24 dp (mais fournir en différentes densités)

### Densités requises

L'icône doit être fournie dans les différentes densités :

- `drawable-mdpi/ic_stat_motification_logo.png` : 24x24 px
- `drawable-hdpi/ic_stat_motification_logo.png` : 36x36 px
- `drawable-xhdpi/ic_stat_motification_logo.png` : 48x48 px
- `drawable-xxhdpi/ic_stat_motification_logo.png` : 72x72 px
- `drawable-xxxhdpi/ic_stat_motification_logo.png` : 96x96 px

### Comment créer l'icône monochrome

1. **Ouvrir l'icône originale** dans un éditeur d'images (Photoshop, GIMP, etc.)

2. **Convertir en niveaux de gris** :
   - Désaturer l'image (Image > Mode > Niveaux de gris)
   - Ajuster le contraste pour que l'icône soit bien visible

3. **Inverser les couleurs** si nécessaire :
   - Si l'icône est sombre, l'inverser pour obtenir du blanc
   - Image > Ajustements > Inverser (ou Ctrl+I)

4. **Rendre le fond transparent** :
   - Supprimer le fond ou le rendre transparent
   - Exporter en PNG avec transparence

5. **Ajuster la couleur finale** :
   - L'icône doit être en **blanc pur** (#FFFFFF)
   - Utiliser un filtre ou un ajustement pour s'assurer que toutes les parties visibles sont blanches

6. **Exporter aux différentes tailles** :
   - Redimensionner l'icône aux différentes tailles requises
   - Exporter chaque taille dans le dossier correspondant

### Vérification

Pour vérifier que l'icône est correcte :

1. L'icône doit être visible sur un fond sombre (blanc)
2. L'icône doit être visible sur un fond clair (blanc également, mais peut nécessiter un ajustement)
3. L'icône ne doit pas avoir de couleurs, seulement du blanc et de la transparence

### Alternative : Utiliser un outil en ligne

Vous pouvez utiliser des outils en ligne pour convertir une icône en format monochrome :
- [Android Asset Studio - Notification Icon Generator](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)
- Cet outil génère automatiquement toutes les densités nécessaires

### Emplacement des fichiers

Les fichiers doivent être placés dans :
```
android/app/src/main/res/
├── drawable-mdpi/
│   └── ic_stat_motification_logo.png
├── drawable-hdpi/
│   └── ic_stat_motification_logo.png
├── drawable-xhdpi/
│   └── ic_stat_motification_logo.png
├── drawable-xxhdpi/
│   └── ic_stat_motification_logo.png
└── drawable-xxxhdpi/
    └── ic_stat_motification_logo.png
```

### Après modification

1. Nettoyer le build : `flutter clean`
2. Rebuild l'application : `flutter build apk` ou `flutter run`
3. Tester sur différents appareils Android

### Note importante

Si l'icône continue d'afficher un carré noir ou blanc après ces modifications, vérifiez que :
- Le fichier est bien nommé `ic_stat_motification_logo.png` (sans fautes)
- Le fichier est bien dans le bon dossier de densité
- Le fichier n'est pas corrompu
- Le build a bien été nettoyé et reconstruit

