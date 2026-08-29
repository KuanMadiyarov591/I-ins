"""Пересборка runtime/payload.zip и его манифеста из распакованного дерева payload.

Использование:
    python3 tools/make_payload.py <папка-с-modules> [--out runtime/payload.zip]

Скрипт нужен только если вы меняете исходники модулей. Для обычной сборки
и запуска I-ins он не требуется — готовый payload.zip уже лежит в runtime/.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import unicodedata
import zipfile
from pathlib import Path

VERSION = "1.2.0-macos"
MODULES = ("client", "agent", "admin", "underwriter", "legal", "actuary")
EXCLUDE_NAMES = {".DS_Store", "payload_manifest.json", "__pycache__"}
EXCLUDE_SUFFIXES = ("-wal", "-shm", ".pyc", ".pyo")


def nfc(value: str) -> str:
    return unicodedata.normalize("NFC", value)


def iter_files(root: Path):
    for path in sorted(root.rglob("*"), key=lambda p: nfc(p.as_posix())):
        if not path.is_file() or path.is_symlink():
            continue
        parts = path.relative_to(root).parts
        if any(part in EXCLUDE_NAMES for part in parts):
            continue
        if path.name.endswith(EXCLUDE_SUFFIXES):
            continue
        yield path


def sha256_file(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


def main() -> int:
    parser = argparse.ArgumentParser(description="Собрать payload.zip для I-ins macOS")
    parser.add_argument("source", type=Path, help="папка, внутри которой лежит modules/")
    parser.add_argument("--out", type=Path, default=Path("runtime/payload.zip"))
    args = parser.parse_args()

    source = args.source.resolve()
    if not (source / "modules").is_dir():
        raise SystemExit(f"В {source} нет папки modules/")
    for module in MODULES:
        if not (source / "modules" / module / f"iins_{module}_app" / "main.py").is_file():
            raise SystemExit(f"Не найден модуль {module}")

    files = list(iter_files(source))
    entries = []
    total = 0
    seen: set[str] = set()
    for path in files:
        relative = nfc(path.relative_to(source).as_posix())
        # macOS не различает регистр и нормализует Unicode — ловим коллизии заранее.
        key = "/".join(unicodedata.normalize("NFD", part).casefold() for part in relative.split("/"))
        if key in seen:
            raise SystemExit(f"Коллизия имени для macOS: {relative}")
        seen.add(key)
        for part in relative.split("/"):
            longest = max(len(part.encode("utf-8")), len(unicodedata.normalize("NFD", part).encode("utf-8")))
            if longest > 255:
                raise SystemExit(f"Имя длиннее 255 байт: {relative}")
        digest, size = sha256_file(path)
        entries.append({"path": relative, "bytes": size, "sha256": digest})
        total += size

    manifest = {
        "product": "I-ins",
        "version": VERSION,
        "python": ">=3.11,<3.14",
        "modules": list(MODULES),
        "file_count": len(entries),
        "uncompressed_bytes": total,
        "files": entries,
    }

    out = args.out.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path, entry in zip(files, entries):
            archive.write(path, entry["path"])
        archive.writestr("payload_manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))

    digest, size = sha256_file(out)
    (out.parent / (out.name + ".sha256")).write_text(f"{digest}  {out.name}\n", encoding="utf-8")
    print(f"OK: {out}")
    print(f"  файлов: {len(entries)}, распакованный объём: {total / 1048576:.1f} МБ")
    print(f"  архив:  {size / 1048576:.1f} МБ, sha256={digest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
