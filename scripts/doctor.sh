#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
failures=0
warnings=0
strict=false

usage() {
  cat <<'USAGE'
Usage: ./scripts/doctor.sh [--strict]

Check installed tools, declared runtime versions, deployment links, and
Neovim startup without installing or modifying configuration.

  --strict  Treat optional dependency warnings as failures.
  -h, --help
USAGE
}

while (($#)); do
  case "$1" in
    --strict) strict=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

section() { printf '\n%b== %s ==%b\n' "$BLUE" "$1" "$NC"; }
pass() { printf '  %b✓%b %s\n' "$GREEN" "$NC" "$1"; }
fail() {
  printf '  %b✗%b %s\n' "$RED" "$NC" "$1"
  failures=$((failures + 1))
}
warn() {
  printf '  %b!%b %s\n' "$YELLOW" "$NC" "$1"
  warnings=$((warnings + 1))
}

check_required_cmd() {
  local command_name=$1 label=${2:-$1}
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$label: $(command -v "$command_name")"
  else
    fail "$label 없음"
  fi
}

check_optional_cmd() {
  local command_name=$1 label=${2:-$1}
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$label: $(command -v "$command_name")"
  else
    warn "$label 없음"
  fi
}

check_asdf_tool() {
  local tool=$1 expected current
  expected=$(awk -v tool="$tool" '$1 == tool { print $2; exit }' "$SCRIPT_DIR/.tool-versions")
  if [ -z "$expected" ]; then
    fail ".tool-versions에 $tool version이 없음"
    return
  fi
  if ! command -v asdf >/dev/null 2>&1; then
    fail "$tool $expected 확인 불가: asdf 없음"
    return
  fi
  current=$(asdf current "$tool" 2>/dev/null | awk -v tool="$tool" '$1 == tool { print $2; exit }')
  if [ "$current" = "$expected" ]; then
    pass "$tool $current"
  elif [ -z "$current" ]; then
    fail "$tool $expected 미설치 또는 활성화되지 않음"
  else
    fail "$tool version 불일치: current=$current expected=$expected"
  fi
}

section "Core commands"
for command_name in git nvim rg fd lazygit fzf tmux gh curl; do check_required_cmd "$command_name"; done

if command -v nvim >/dev/null 2>&1; then
  nvim_version=$(NVIM_LOG_FILE=/dev/null nvim --version 2>/dev/null | awk 'NR == 1 { sub(/^NVIM v/, ""); print $1 }')
  nvim_minor=$(printf '%s\n' "$nvim_version" | awk -F. '{ print ($1 == 0 ? $2 : 999) }')
  if [ -n "$nvim_version" ] && [ "${nvim_minor:-0}" -ge 10 ] 2>/dev/null; then
    pass "Neovim version $nvim_version (minimum 0.10)"
  else
    fail "Neovim 0.10+ 필요: current=${nvim_version:-unknown}"
  fi
fi

section "asdf runtimes"
check_required_cmd asdf
for tool in golang nodejs python; do check_asdf_tool "$tool"; done
for command_name in go node npm python; do check_required_cmd "$command_name"; done

section "Editor and DevOps tools"
for command_name in prettier stylua shfmt shellcheck gopls gofumpt goimports dlv terraform ansible-lint; do
  check_required_cmd "$command_name"
done

section "Deployment"
nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
expected_config=$(cd "$SCRIPT_DIR" && pwd -P)
if [ -L "$nvim_config" ] && [ -e "$nvim_config" ]; then
  actual_config=$(cd "$nvim_config" && pwd -P)
  if [ "$actual_config" = "$expected_config" ]; then
    pass "$nvim_config -> $expected_config"
  else
    fail "$nvim_config 대상 불일치: actual=$actual_config expected=$expected_config"
  fi
elif [ -e "$nvim_config" ]; then
  fail "$nvim_config가 symlink가 아님"
else
  fail "$nvim_config 없음"
fi

if [ -f "$SCRIPT_DIR/lazy-lock.json" ]; then pass "lazy-lock.json 존재"; else fail "lazy-lock.json 없음"; fi

section "Optional integrations"
check_optional_cmd tree-sitter
case "$(uname -s)" in
  Darwin) check_optional_cmd macism "macism (input method)" ;;
  Linux)
    if grep -qEi '(microsoft|wsl)' /proc/version 2>/dev/null; then
      check_optional_cmd clip.exe "clip.exe (WSL clipboard)"
      check_optional_cmd im-select.exe "im-select.exe (input method)"
    fi
    ;;
esac
if [ -d "$HOME/.tmux/plugins/tpm" ]; then pass "TPM 설치됨"; else warn "TPM 없음"; fi

section "Neovim startup"
if command -v nvim >/dev/null 2>&1 && [ -e "$nvim_config/init.lua" ]; then
  startup_log=$(mktemp "${TMPDIR:-/tmp}/nvim-doctor.XXXXXX")
  startup_dir=$(dirname "$startup_log")
  if (cd "$startup_dir" && NVIM_LOG_FILE="${startup_log}.nvim" nvim --clean --headless -i NONE '+set shadafile=NONE' '+qa') >"$startup_log" 2>&1; then
    pass "headless startup 성공"
  else
    fail "headless startup 실패"
    sed 's/^/      /' "$startup_log"
  fi
  rm -f "$startup_log" "${startup_log}.nvim" "$startup_dir/nvim.log"
else
  fail "headless startup 확인 불가"
fi

printf '\n'
if [ "$strict" = true ] && [ "$warnings" -gt 0 ]; then failures=$((failures + warnings)); fi
if [ "$failures" -eq 0 ]; then
  printf '%b환경 정상%b (warnings=%d)\n' "$GREEN" "$NC" "$warnings"
  exit 0
fi
printf '%b점검 필요%b (failures=%d, warnings=%d)\n' "$RED" "$NC" "$failures" "$warnings"
printf '복구: ./scripts/setup.sh --install --link [--with-font] [--with-im] [--with-tmux-plugins]\n'
printf '상세 plugin/provider 진단: nvim에서 :checkhealth\n'
exit 1
