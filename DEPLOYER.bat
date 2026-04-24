@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo ============================================
echo    FasoPermut - Deploiement automatique
echo ============================================
echo.

echo [1/7] Fermeture des processus qui bloquent git...
taskkill /F /IM git.exe        >nul 2>&1
taskkill /F /IM git-remote-https.exe >nul 2>&1
taskkill /F /IM ssh.exe        >nul 2>&1
taskkill /F /IM TortoiseGit.exe >nul 2>&1
taskkill /F /IM TGitCache.exe  >nul 2>&1
timeout /t 1 /nobreak >nul
echo     OK.

echo.
echo [2/7] Suppression forcee des fichiers verrou (.lock)...
powershell -NoProfile -Command "Get-ChildItem -Path '.git' -Recurse -Filter '*.lock' -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item $_.FullName -Force -ErrorAction Stop; Write-Host '    Supprime: '$_.FullName } catch { Write-Host '    ATTENTION: impossible de supprimer '$_.FullName -ForegroundColor Yellow } }"
if exist ".git\index.lock" (
    echo.
    echo     !!! index.lock existe toujours !!!
    echo     Essai en mode administrateur...
    powershell -NoProfile -Command "Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue"
)
if exist ".git\index.lock" (
    echo.
    echo     !!! ECHEC : index.lock reste bloque
    echo     Ferme VS Code + GitHub Desktop + tout ce qui touche au dossier
    echo     puis relance ce script.
    pause
    exit /b 1
)
echo     OK, verrous nettoyes.

echo.
echo [3/7] Verification de l'etat...
git status --short

echo.
echo [4/7] Ajout des fichiers modifies...
git add index.html vercel.json supabase.min.js DEPLOYER.bat
if errorlevel 1 (
    echo     ERREUR a l'ajout. Arret.
    pause
    exit /b 1
)
echo     OK.

echo.
echo [5/7] Creation du commit...
git commit -m "Fix inscription: Supabase JS local + fallback CDN + no-cache"
if errorlevel 1 (
    echo     Aucun changement a commiter ou erreur. On continue quand meme.
)

echo.
echo [6/7] Push vers GitHub...
git push origin main
if errorlevel 1 (
    echo.
    echo     ECHEC du push. Verifie ta connexion internet.
    pause
    exit /b 1
)
echo     OK.

echo.
echo [7/7] Termine !
echo.
echo ============================================
echo   Deploiement envoye ! Vercel va publier
echo   la nouvelle version dans ~1 minute.
echo ============================================
echo.
echo Ouvre fasopermut.com avec Ctrl+Shift+R pour
echo voir la nouvelle version.
echo.
pause
