#!/bin/bash
# Regenerates all stardoc documentation and copies it to doc/.
# Works on both macOS and Linux.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Prefer bazelisk if available, fall back to bazel.
if command -v bazelisk &>/dev/null; then
  BAZEL=bazelisk
else
  BAZEL=bazel
fi

# All stardoc target names and their output filenames (must match qt/BUILD).
targets=(
  "//qt:docs|docs.md"
  "//qt:providers_docs|providers-docs.md"
  "//qt:qt_http_repo_docs|qt_http_repo-docs.md"
  "//qt:qt_local_repo_docs|qt_local_repo-docs.md"
  "//qt:qt_remote_repo_docs|qt_remote_repo-docs.md"
  "//qt:toolchain_docs|toolchain-docs.md"
)

labels=()
for entry in "${targets[@]}"; do
  labels+=("${entry%%|*}")
done

echo "=== Building stardoc targets ==="
$BAZEL build "${labels[@]}"

echo ""
echo "=== Copying generated docs to doc/ ==="
changed=0
for entry in "${targets[@]}"; do
  label="${entry%%|*}"
  filename="${entry##*|}"
  src="bazel-bin/qt/${filename}"
  dst="doc/${filename}"

  if [ ! -f "$src" ]; then
    echo "ERROR: expected output not found: $src"
    exit 1
  fi

  if diff -q "$dst" "$src" >/dev/null 2>&1; then
    echo "  unchanged: $filename"
  else
    cp "$src" "$dst"
    echo "  updated:   $filename"
    changed=$((changed + 1))
  fi
done

echo ""
if [ $changed -eq 0 ]; then
  echo "All docs are up to date."
else
  echo "$changed doc(s) updated. Review with: git diff doc/"
fi
