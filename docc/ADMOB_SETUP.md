# Configuration AdMob

## Configuration des App IDs (Publisher IDs)

Les App IDs (identifiants du compte publicitaire) doivent être configurés dans **deux endroits** :

### 1. Backend Laravel (Panel Admin)
- Accédez au panel admin : **Configuration > Publicités AdMob**
- Configurez les App IDs Android et iOS
- Ces IDs sont utilisés par l'API pour les récupérer dynamiquement

### 2. Fichiers natifs (Requis par AdMob)

#### Android
Fichier : `android/app/src/main/AndroidManifest.xml`

Ajoutez dans la section `<application>` :
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="VOTRE_APP_ID_ANDROID"/>
```

Remplacez `VOTRE_APP_ID_ANDROID` par l'App ID Android configuré dans le panel admin.

#### iOS
Fichier : `ios/Runner/Info.plist`

Ajoutez avant la balise `</dict>` :
```xml
<key>GADApplicationIdentifier</key>
<string>VOTRE_APP_ID_IOS</string>
```

Remplacez `VOTRE_APP_ID_IOS` par l'App ID iOS configuré dans le panel admin.

## Configuration des Ad Unit IDs

Les Ad Unit IDs (identifiants des unités publicitaires) sont **uniquement configurés dans le backend** :
- Bannière Android/iOS
- Interstitiel Android/iOS
- Interstitiel Vidéo Android/iOS

Ces IDs sont récupérés automatiquement par l'application depuis l'API `/api/admob/ids`.

## Workflow recommandé

1. **Configurer les App IDs dans le panel admin Laravel**
2. **Copier les App IDs et les ajouter dans les fichiers natifs** (AndroidManifest.xml et Info.plist)
3. **Configurer les Ad Unit IDs dans le panel admin Laravel**
4. **Rebuild l'application** pour que les changements dans les fichiers natifs prennent effet

## Notes importantes

- Les App IDs dans les fichiers natifs doivent correspondre à ceux du backend
- Les Ad Unit IDs sont gérés uniquement depuis le backend (pas besoin de modifier les fichiers natifs)
- Après modification des fichiers natifs, il faut rebuild l'application (`flutter clean && flutter build`)

