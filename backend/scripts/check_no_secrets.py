from __future__ import annotations

import re
import subprocess
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
    ignored_paths = _git_ignored_paths(root)
    failures: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file() or any(part in SKIP_PARTS for part in path.parts):
            continue
        rel = path.relative_to(root)
        if rel in ignored_paths:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                failures.append(str(rel))
    if failures:
        print("Potential secrets found:\n" + "\n".join(failures), file=sys.stderr)
        return 1
    print("Secret scan passed")
    return 0


def _git_ignored_paths(root: Path) -> set[Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "--others", "--ignored", "--exclude-standard"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()
    ignored: set[Path] = set()
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        ignored.add(Path(line))
    return ignored


if __name__ == "__main__":
    raise SystemExit(main())
