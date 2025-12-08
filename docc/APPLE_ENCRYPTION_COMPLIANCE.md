# 🔐 Conformité au Chiffrement - Apple App Store

## ✅ Configuration effectuée

La clé `ITSAppUsesNonExemptEncryption` a été ajoutée dans `ios/Runner/Info.plist` avec la valeur `false`.

## 📋 Réponses à fournir dans App Store Connect

### Question 1 : Votre app utilise-t-elle le chiffrement ?

**Réponse : OUI** ✅

L'application utilise le chiffrement pour :
- Les communications HTTPS/TLS avec l'API backend
- Les connexions WebSocket sécurisées (Socket.IO)
- Le stockage sécurisé via Keychain iOS (flutter_secure_storage)
- L'authentification Firebase
- Google Sign-In et Apple Sign-In

---

### Question 2 : Votre app contient-elle l'un des éléments suivants ?

**Algorithmes de chiffrement propriétaires ou non considérés comme standard par les organismes de normalisation internationaux (IEEE, IETF, UIT, etc.)**

**Algorithmes de chiffrement standard à la place ou en complément de l'utilisation du chiffrement employé dans le système d'exploitation d'Apple ou de l'accès à ce chiffrement**

**Réponse : NON** ❌

**Explication :**

L'application **Points Master** utilise **uniquement** le chiffrement standard fourni par iOS :

1. **HTTPS/TLS** (standard IETF) pour toutes les communications réseau
   - Requêtes API via `http` et `dio` packages
   - Connexions Firebase (HTTPS)
   - Socket.IO avec WebSocket sécurisé (WSS)

2. **Keychain iOS** (chiffrement standard Apple) pour le stockage sécurisé
   - Utilisé par `flutter_secure_storage` pour stocker les tokens d'authentification
   - Utilise les APIs natives de sécurité d'iOS

3. **Authentification standard**
   - Firebase Authentication (utilise les standards OAuth/OAuth2)
   - Google Sign-In (utilise les standards OAuth2)
   - Apple Sign-In (utilise les standards Apple)

4. **Aucun algorithme propriétaire**
   - Aucun algorithme de chiffrement personnalisé
   - Aucun algorithme non standard
   - Aucun chiffrement en plus de celui fourni par iOS

---

## 📝 Déclaration dans App Store Connect

Lors de la soumission de votre application, vous devrez :

1. ✅ Cocher "Oui" pour indiquer que l'app utilise le chiffrement
2. ✅ Cocher "Non" pour indiquer qu'il n'y a pas d'algorithmes propriétaires
3. ✅ La clé `ITSAppUsesNonExemptEncryption` avec la valeur `false` dans Info.plist confirme automatiquement cette déclaration

**Résultat :** Aucun document supplémentaire n'est requis. La soumission peut continuer normalement.

---

## 🔍 Vérification technique

### Chiffrement utilisé dans l'app :

| Composant | Type de chiffrement | Standard |
|-----------|---------------------|----------|
| HTTP/HTTPS (API) | TLS 1.2+ | IETF (RFC 5246) |
| Socket.IO | WebSocket Secure (WSS) | IETF (RFC 6455) |
| Keychain Storage | AES-256 (via Keychain) | Standard Apple |
| Firebase Auth | OAuth2/TLS | IETF (RFC 6749) |
| Google Sign-In | OAuth2/TLS | IETF (RFC 6749) |
| Apple Sign-In | OAuth2/TLS | Standard Apple |

**Conclusion :** Tous les algorithmes utilisés sont des standards internationaux ou fournis par Apple.

---

## ⚠️ Important

Si vous ajoutez à l'avenir :
- Un algorithme de chiffrement personnalisé
- Un algorithme non standard
- Un chiffrement en plus de celui fourni par iOS

Vous devrez alors :
1. Changer `ITSAppUsesNonExemptEncryption` à `true` dans Info.plist
2. Fournir les documents d'exportation requis dans App Store Connect
3. Obtenir les autorisations nécessaires selon les réglementations d'exportation

---

## 📚 Références

- [Apple - Export Compliance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
- [Apple - ITSAppUsesNonExemptEncryption](https://developer.apple.com/documentation/bundleresources/information_property_list/itsappusesnonexemptencryption)
- [Bureau of Industry and Security (BIS)](https://www.bis.doc.gov/)

