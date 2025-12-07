@echo off
echo ========================================
echo Google Sign In - Certificats Fingerprint
echo ========================================
echo.

echo === DEBUG FINGERPRINTS ===
echo.
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo ========================================
echo.

echo === RELEASE FINGERPRINTS ===
echo.
if exist "app\release.keystore" (
    echo Entrez le mot de passe du keystore de release:
    keytool -list -v -keystore "app\release.keystore" -alias release
) else (
    echo [ATTENTION] Release keystore non trouve!
    echo.
    echo Pour creer un keystore de release, executez:
    echo keytool -genkey -v -keystore app\release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
    echo.
)

echo.
echo ========================================
echo Copiez les valeurs SHA1 et SHA256 ci-dessus
echo et ajoutez-les dans Firebase Console
echo ========================================
pause

