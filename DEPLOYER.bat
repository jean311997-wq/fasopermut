@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo ============================================
echo    FasoPermut - Deploiement automatique
echo ============================================
echo.

echo [1/6] Nettoyage des verrous git...
taskkill /F /IM git.exe >nul 2>&1
timeout /t 1 /nobreak >nul
del /F /Q ".git\index.lock" >nul 2>&1
del /F /Q ".git\HEAD.lock" >nul 2>&1
del /F /Q ".git\refs\heads\main.lock" >nul 2>&1
echo     OK.

echo.
echo [2/6] Verification de l'etat...
git status --short

echo.
echo [3/6] Ajout des fichiers modifies...
git add index.html vercel.json supabase.min.js DEPLOYER.bat
if errorlevel 1 (
    echo     ERREUR a l'ajout. Arret.
    pause
    exit /b 1
)
echo     OK.

echo.
echo [4/6] Creation du commit...
git commit -m "Fix inscription: Supabase JS local + fallback CDN + no-cache"
if errorlevel 1 (
    echo     Aucun changement a commiter ou erreur. On continue quand meme.
)

echo.
echo [5/6] Push vers GitHub...
git push origin main
if errorlevel 1 (
    echo.
    echo     ECHEC du push. Verifie ta connexion internet.
    pause
    exit /b 1
)
echo     OK.

echo.
echo [6/6] Termine !
echo.
echo ============================================
echo   Deploiement envoye ! Vercel va publier
echo   la nouvelle version dans ~1 minute.
echo ============================================
echo.
echo Dis a tes collegues de fermer et rouvrir
echo le lien fasopermut.com dans leur navigateur.
echo.
pause
