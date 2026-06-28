#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

FILES=(
  scripts/setup-macos.sh
  scripts/setup-wsl.sh
  scripts/lib/setup-common.sh
  scripts/lib/setup-versions.sh
  scripts/test-setup.sh
)

info() { printf '[INFO] %s\n' "$1"; }
ok() { printf '[OK] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }

info "bash 문법 검사"
bash -n "${FILES[@]}"
ok "bash -n 통과"

if command -v shellcheck >/dev/null 2>&1; then
  info "shellcheck"
  shellcheck "${FILES[@]}"
  ok "shellcheck 통과"
else
  warn "shellcheck 없음: 건너뜀"
fi

if command -v shfmt >/dev/null 2>&1; then
  info "shfmt diff 검사"
  shfmt -d -i 2 -ci "${FILES[@]}"
  ok "shfmt 통과"
else
  warn "shfmt 없음: 건너뜀"
fi

info "help 출력 검사"
./scripts/setup-macos.sh --help >/dev/null
ok "macOS help 출력 통과"

info "macOS dry-run 검사"
./scripts/setup-macos.sh --install --link --with-font --with-im --with-tmux-plugins --dry-run >/dev/null
ok "macOS dry-run 통과"

info "symlink helper 단위 테스트"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/src" "$tmp_dir/parent"
ln -s "$tmp_dir/src" "$tmp_dir/parent/ok-link"

SCRIPT_DIR="$SCRIPT_DIR" bash -c '
  set -euo pipefail
  source "$SCRIPT_DIR/scripts/lib/setup-common.sh"
  check_symlink_status "$1" "$2" "test link" >/dev/null
' bash "$tmp_dir/src" "$tmp_dir/parent/ok-link"

if SCRIPT_DIR="$SCRIPT_DIR" bash -c '
  set -euo pipefail
  source "$SCRIPT_DIR/scripts/lib/setup-common.sh"
  check_symlink_status "$1" "$2" "test missing" >/dev/null 2>&1
' bash "$tmp_dir/src" "$tmp_dir/parent/missing-link"; then
  echo "missing symlink test unexpectedly succeeded" >&2
  exit 1
fi

mkdir -p "$tmp_dir/existing-dir"
if SCRIPT_DIR="$SCRIPT_DIR" bash -c '
  set -euo pipefail
  source "$SCRIPT_DIR/scripts/lib/setup-common.sh"
  YES=false
  ensure_symlink "$1" "$2" "existing dir" >/dev/null 2>&1
' bash "$tmp_dir/src" "$tmp_dir/existing-dir"; then
  echo "existing directory replacement unexpectedly succeeded without --yes" >&2
  exit 1
fi
ok "symlink helper 단위 테스트 통과"

if command -v nvim >/dev/null 2>&1; then
  info "nvim headless 검사"
  XDG_STATE_HOME="$tmp_dir/state" XDG_CACHE_HOME="$tmp_dir/cache" nvim --headless '+qa'
  ok "nvim headless 통과"
else
  warn "nvim 없음: headless 검사 건너뜀"
fi
