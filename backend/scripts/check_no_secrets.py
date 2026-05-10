from __future__ import annotations

import re
import sys
from pathlib import Path

SECRET_PATTERNS = [
    re.compile(r"nvapi-[A-Za-z0-9_-]{20,}"),
]

SKIP_PARTS = {
    ".git",
    "node_modules",
    ".next",
    ".pytest_cache",
    "__pycache__",
    "sua-loi-provider",
    "source-github-provider",
    "deploy",
}


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    failures: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file() or any(part in SKIP_PARTS for part in path.parts):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                failures.append(str(path.relative_to(root)))
    if failures:
        print("Potential secrets found:\n" + "\n".join(failures), file=sys.stderr)
        return 1
    print("Secret scan passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
