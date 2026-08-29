#!/bin/bash
# Отправляет комплект I-ins в репозиторий на GitHub.
# Git LFS не нужен: комплект лежит распакованным, самый крупный файл 36 МБ.
set -u

REMOTE="${1:-https://github.com/KuanMadiyarov591/I-ins.git}"
cd "$(dirname "$0")"

[[ -d payload/modules ]] || { echo "Запускайте из папки I-ins, рядом с папкой payload."; exit 1; }
command -v git >/dev/null || { echo "Нужен git: xcode-select --install"; exit 1; }

[[ -d .git ]] || git init -b main 2>/dev/null || { git init && git checkout -b main; }
git add -A
git diff --cached --quiet || git commit -m "I-ins 1.2.0: шесть кабинетов, выбор языковой модели Qwen RAG и GigaChat"

git remote remove origin >/dev/null 2>&1 || true
git remote add origin "$REMOTE"

echo
echo "Отправка в $REMOTE — около 150 МБ, несколько минут."
git push -u origin main || {
  echo
  echo "Не удалось отправить. Если в репозитории уже есть коммиты, выполните:"
  echo "  git push -f -u origin main"
  exit 1
}

echo
echo "Готово: ${REMOTE%.git}"
