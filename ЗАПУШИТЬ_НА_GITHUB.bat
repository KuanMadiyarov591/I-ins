@echo off
chcp 65001 >nul
rem Отправляет комплект I-ins в репозиторий https://github.com/KuanMadiyarov591/I-ins
rem Git LFS не нужен: комплект лежит распакованным, самый крупный файл 36 МБ.
setlocal
cd /d "%~dp0"

set REMOTE=https://github.com/KuanMadiyarov591/I-ins.git

if not exist payload\modules (
  echo Запускайте этот файл из папки I-ins, рядом с папкой payload.
  pause & exit /b 1
)
where git >nul 2>&1 || (
  echo Не найден git. Установите: https://git-scm.com/download/win
  pause & exit /b 1
)
git --version

echo Папка: %CD%
echo "%CD%" | find /i "\Temp\" >nul && (
  echo.
  echo Похоже, файл запущен прямо из ZIP-архива.
  echo Сначала распакуйте I-ins.zip в обычную папку, потом запустите этот файл оттуда.
  pause & exit /b 1
)

if not exist .git (
  echo Создание локального репозитория...
  git init -b main 2>nul || git init || (pause & exit /b 1)
  git checkout -b main 2>nul
)

git add -A || (pause & exit /b 1)
git diff --cached --quiet
if errorlevel 1 (
  git -c user.name="Kuan Madiyarov" -c user.email="kukamadchemical@gmail.com" commit -m "I-ins 1.2.0: шесть кабинетов, выбор языковой модели Qwen RAG и GigaChat" || (pause & exit /b 1)
)

git remote remove origin >nul 2>&1
git remote add origin %REMOTE% || (pause & exit /b 1)

echo.
echo Отправка в %REMOTE%
echo Если откроется окно входа GitHub — подтвердите, вы уже вошли в браузере.
echo Загрузка около 150 МБ, это несколько минут.
echo.
git push -u origin main || (
  echo.
  echo Не удалось отправить. Частые причины: не выполнен вход в git,
  echo либо в репозитории уже есть коммиты — тогда выполните: git push -f -u origin main
  pause & exit /b 1
)

echo.
echo Готово. Репозиторий: https://github.com/KuanMadiyarov591/I-ins
echo На Mac:  git clone %REMOTE% ^&^& cd I-ins ^&^& chmod +x I-ins.command ^&^& ./I-ins.command
pause
