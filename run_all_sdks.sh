#!/bin/bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/examples"
MODULE=MODULE.bazel
TIMEOUT="${TIMEOUT:-60}"
DEFAULT_SDK="qt6_local"

# ---- Platform-portable helpers ----
# macOS: GNU coreutils prefixed with 'g' (brew install coreutils)
# Linux: native date/timeout
if [[ "$(uname)" == "Darwin" ]]; then
  DATE_CMD=gdate
  TIMEOUT_CMD=gtimeout
  SED_INPLACE=(sed -i '')
  for cmd in "$DATE_CMD" "$TIMEOUT_CMD"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "FATAL: '$cmd' not found. Install GNU coreutils: brew install coreutils"
      exit 1
    fi
  done
else
  DATE_CMD=date
  TIMEOUT_CMD=timeout
  SED_INPLACE=(sed -i)
fi

# Prefer bazelisk if available, fall back to bazel.
if command -v bazelisk &>/dev/null; then
  BAZEL=bazelisk
else
  BAZEL=bazel
fi

switch_sdk() {
  "${SED_INPLACE[@]}" "s/qt.active_sdk(name = \"qt\", repo = \"[^\"]*\")/qt.active_sdk(name = \"qt\", repo = \"$1\")/" "$MODULE"
}

# Always restore the default SDK on exit (normal, error, or fail-fast).
restore_sdk() {
  switch_sdk "$DEFAULT_SDK"
}
trap restore_sdk EXIT

millis() {
  $DATE_CMD +%s%3N
}

hello_targets=(
  "//hello_rules/1_moc:cc_binary"
  "//hello_rules/1_moc:qt_cc_binary"
  "//hello_rules/2_rcc:cc_binary"
  "//hello_rules/2_rcc:cc_binary_autogen"
  "//hello_rules/2_rcc:qt_cc_binary"
  "//hello_rules/2_rcc:qt_cc_binary_autogen"
  "//hello_rules/3_uic:cc_binary"
  "//hello_rules/3_uic:qt_cc_binary"
  "//hello_rules/4_qml:cc_binary"
  "//hello_rules/4_qml:cc_binary_runtime_resources"
  "//hello_rules/4_qml:qt_cc_binary"
  "//hello_rules/4_qml:qt_cc_binary_runtime_resources"
  "//hello_rules/5_balsam:cc_binary"
  "//hello_rules/5_balsam:cc_binary_runtime_resources"
  "//hello_rules/5_balsam:qt_cc_binary"
  "//hello_rules/5_balsam:qt_cc_binary_runtime_resources"
  "//hello_rules/6_hello_rules:cc_binary"
  "//hello_rules/6_hello_rules:cc_binary_runtime_resources"
  "//hello_rules/6_hello_rules:qt_cc_binary"
  "//hello_rules/6_hello_rules:qt_cc_binary_runtime_resources"
)

# ==============================================================
# Phase 1: Pre-warm remote repos (no timeout, just build)
# ==============================================================
echo "=== Phase 1: Pre-warming remote repos ==="

echo ""
echo "--- Building qt5_remote (no timeout) ---"
switch_sdk "qt5_remote"
$BAZEL build //hello_rules/... "//qtdeclarative-5.15:examples/quick/animation" "//qtquick3d-5.15:examples/quick3d/hellocube"
if [ $? -ne 0 ]; then
  echo "FATAL: qt5_remote build failed"
  exit 1
fi

echo ""
echo "--- Building qt6_remote (no timeout) ---"
switch_sdk "qt6_remote"
$BAZEL build //hello_rules/... "//qtdeclarative-6.4:examples/quick/animation" "//qtquick3d-6.4:examples/quick3d/hellocube"
if [ $? -ne 0 ]; then
  echo "FATAL: qt6_remote build failed"
  exit 1
fi

echo ""
echo "=== Phase 1 complete. Remote repos pre-warmed. ==="
echo ""

# ==============================================================
# Phase 2: 4-SDK smoke test (fail-fast on rc=124)
# ==============================================================

run_sdk() {
  local sdk="$1"
  shift
  local smoke_targets=("$@")
  switch_sdk "$sdk"

  echo ""
  echo "================================================================"
  echo "=== SDK: $sdk (timeout=${TIMEOUT}s)"
  echo "================================================================"

  local switch_start=$(millis)
  local failed=0
  local passed=0

  for t in "${hello_targets[@]}"; do
    $TIMEOUT_CMD $TIMEOUT $BAZEL run "$t" > /dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      echo "PASS (rc=0): $t"
      passed=$((passed+1))
    elif [ $rc -eq 124 ]; then
      echo "FAIL-FAST (rc=124 timeout): $t [sdk=$sdk]"
      exit 1
    else
      echo "FAIL (rc=$rc): $t"
      failed=$((failed+1))
    fi
  done

  for t in "${smoke_targets[@]}"; do
    $TIMEOUT_CMD $TIMEOUT $BAZEL run "$t" > /dev/null 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
      echo "PASS (rc=0): $t"
      passed=$((passed+1))
    elif [ $rc -eq 124 ]; then
      echo "FAIL-FAST (rc=124 timeout): $t [sdk=$sdk]"
      exit 1
    else
      echo "FAIL (rc=$rc): $t"
      failed=$((failed+1))
    fi
  done

  local switch_end=$(millis)
  local elapsed=$(( (switch_end - switch_start) / 1000 ))

  echo ""
  echo "--- $sdk: $passed passed, $failed failed | Total time: ${elapsed}s ---"

  total_passed=$((total_passed + passed))
  total_failed=$((total_failed + failed))
}

total_start=$(millis)

total_passed=0
total_failed=0

run_sdk "qt6_local" "//qtdeclarative-6.4:examples/quick/animation" "//qtquick3d-6.4:examples/quick3d/hellocube"
run_sdk "qt5_local" "//qtdeclarative-5.15:examples/quick/animation" "//qtquick3d-5.15:examples/quick3d/hellocube"
run_sdk "qt5_remote" "//qtdeclarative-5.15:examples/quick/animation" "//qtquick3d-5.15:examples/quick3d/hellocube"
run_sdk "qt6_remote" "//qtdeclarative-6.4:examples/quick/animation" "//qtquick3d-6.4:examples/quick3d/hellocube"

total_end=$(millis)
total_elapsed=$(( (total_end - total_start) / 1000 ))

echo ""
echo "================================================================"
echo "=== GRAND TOTAL: $total_passed passed, $total_failed failed | ${total_elapsed}s ==="
echo "================================================================"

if [ $total_failed -ne 0 ]; then
  exit 1
fi
