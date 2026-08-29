@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo  I-ins - push to GitHub
echo ============================================================
echo Folder: %CD%
echo.

if not exist payload\modules (
  echo [ERROR] Run this file from the I-ins folder, next to "payload".
  pause & exit /b 1
)

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git not found. Install from https://git-scm.com/download/win
  pause & exit /b 1
)
git --version
echo.

if not exist .git (
  echo Creating local repository...
  git init -b main
  if errorlevel 1 git init
)

git add -A
if errorlevel 1 ( echo [ERROR] git add failed & pause & exit /b 1 )

git diff --cached --quiet
if errorlevel 1 (
  git -c user.name="Kuan Madiyarov" -c user.email="kukamadchemical@gmail.com" commit -m "I-ins 1.2.0"
)

git remote remove origin >nul 2>&1
git remote add origin https://github.com/KuanMadiyarov591/I-ins.git
git remote -v
echo.

echo Pushing about 150 MB. A GitHub sign-in window may appear - confirm it.
echo.
git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Push failed.
  echo If the repository already has commits, run:  git push -f -u origin main
  pause & exit /b 1
)

echo.
echo DONE: https://github.com/KuanMadiyarov591/I-ins
pause
