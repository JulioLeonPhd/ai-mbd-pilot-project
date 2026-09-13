"""Create a local SemVer release commit and annotated Git tag.

Run from the repository root with ``uv run python scripts/release.py``.
Nothing is pushed; review and push the commit and tag separately.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION_PATTERN = re.compile(r'(?m)^(version = ")([0-9]+\.[0-9]+\.[0-9]+)(")$')


def run(*args: str) -> str:
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(f"{' '.join(args)} failed:\n{result.stderr or result.stdout}")
    return result.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="show the next version without changing files")
    args = parser.parse_args()

    if run("git", "rev-parse", "--show-toplevel") != str(ROOT):
        raise RuntimeError("Run this script in its own Git repository")
    bumped_version = run("uv", "run", "--frozen", "git-changelog", "--bumped-version")
    version = bumped_version.removeprefix("v")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise RuntimeError(f"Expected a stable SemVer release, got {version!r}")
    tag = f"v{version}"
    if run("git", "tag", "--list", tag):
        raise RuntimeError(f"Tag {tag} already exists; no unreleased version was found")

    changelog = ROOT / "CHANGELOG.md"
    existing_entry = re.search(rf"(?m)^## \[{re.escape(tag)}\]", changelog.read_text())
    if args.dry_run:
        print(f"Would release {tag}; changelog entry {'exists' if existing_entry else 'will be generated'}")
        return 0

    if run("git", "status", "--porcelain"):
        raise RuntimeError("Commit or stash all changes before releasing")

    if not existing_entry:
        run("uv", "run", "--frozen", "git-changelog")

    project = ROOT / "pyproject.toml"
    original = project.read_text()
    updated, count = VERSION_PATTERN.subn(rf"\g<1>{version}\g<3>", original, count=1)
    if count != 1:
        raise RuntimeError("Could not locate the project version in pyproject.toml")
    if updated != original:
        project.write_text(updated)
        run("uv", "lock")

    run("git", "add", "--", "CHANGELOG.md", "pyproject.toml", "uv.lock")
    if run("git", "diff", "--cached", "--name-only"):
        run("git", "commit", "-m", f"Changed: prepare release {version}")
    run("git", "tag", "-a", tag, "-m", f"Release {tag}")
    if run("git", "rev-parse", f"{tag}^{{commit}}") != run("git", "rev-parse", "HEAD"):
        raise RuntimeError("Release tag does not point to HEAD")
    print(f"Released {tag} locally at {run('git', 'rev-parse', '--short', 'HEAD')}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as error:
        print(f"release: {error}", file=sys.stderr)
        sys.exit(1)
