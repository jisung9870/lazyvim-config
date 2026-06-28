#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$SCRIPT_DIR"
cd "$SCRIPT_DIR"
tmp_sync_dir=""
tmp_dir=""

cleanup() {
  if [ -n "$tmp_sync_dir" ]; then
    rm -rf "$tmp_sync_dir"
  fi
  if [ -n "$tmp_dir" ]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

FILES=(
  scripts/setup.sh
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
./scripts/setup.sh --help >/dev/null
ok "통합 setup help 출력 통과"

./scripts/setup-macos.sh --help >/dev/null
ok "macOS help 출력 통과"

./scripts/setup.sh --type macos --help >/dev/null
ok "통합 setup macOS help 위임 통과"

./scripts/setup.sh --type wsl --help >/dev/null
ok "통합 setup WSL help 위임 통과"

info "macOS dry-run 검사"
./scripts/setup.sh --type macos --install --link --with-font --with-im --with-tmux-plugins --dry-run >/dev/null
ok "통합 setup macOS dry-run 위임 통과"

./scripts/setup-macos.sh --install --link --with-font --with-im --with-tmux-plugins --dry-run >/dev/null
ok "macOS dry-run 통과"

info "sync dry-run 검사"
tmp_sync_dir="$(mktemp -d)"
git -C "$tmp_sync_dir" init -q
git -C "$tmp_sync_dir" config user.email setup-test@example.invalid
git -C "$tmp_sync_dir" config user.name "Setup Test"
printf 'test\n' >"$tmp_sync_dir/file"
git -C "$tmp_sync_dir" add file
git -C "$tmp_sync_dir" commit -q -m init
git -C "$tmp_sync_dir" clone -q --bare . "$tmp_sync_dir/origin.git"
git -C "$tmp_sync_dir" remote add origin "$tmp_sync_dir/origin.git"
git -C "$tmp_sync_dir" fetch -q origin
sync_branch="$(git -C "$tmp_sync_dir" branch --show-current)"
git -C "$tmp_sync_dir" branch --set-upstream-to="origin/$sync_branch" >/dev/null
REPO_DIR="$REPO_DIR" SCRIPT_DIR="$tmp_sync_dir" bash -c '
  set -euo pipefail
  source "$REPO_DIR/scripts/lib/setup-common.sh"
  parse_setup_flags --sync --dry-run
  sync_repository >/dev/null
'
printf 'dirty\n' >>"$tmp_sync_dir/file"
REPO_DIR="$REPO_DIR" SCRIPT_DIR="$tmp_sync_dir" bash -c '
  set -euo pipefail
  source "$REPO_DIR/scripts/lib/setup-common.sh"
  parse_setup_flags --sync --dry-run
  sync_repository >/dev/null
'
ok "sync dry-run 검사 통과"

info "symlink helper 단위 테스트"
tmp_dir="$(mktemp -d)"
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
