#!/usr/bin/env bash
# ========================================
# LazyVim DevOps 환경 설정 - 통합 dispatcher
# ========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_TYPE=""
HELP_REQUESTED=false
ARGS=()

usage() {
  cat <<USAGE
Usage: $0 [--type macos|wsl] [setup options...]

Detect the current platform and delegate to the matching setup script.

  --type macos|wsl      Override platform auto-detection.
  -h, --help            Show this dispatcher help.

Common setup options are passed through unchanged:
  --install --link --sync --sync-plugins --with-font --with-im
  --with-tmux-plugins --dry-run --yes

Examples:
  $0 --install --dry-run
  $0 --type wsl --sync
USAGE
}

detect_setup_type() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      return 0
      ;;
    Linux)
      if grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
        echo "wsl"
        return 0
      fi
      ;;
  esac

  return 1
}

while (($#)); do
  case "$1" in
    --type)
      if [ $# -lt 2 ]; then
        echo "[ERROR] --type 값이 필요합니다: macos 또는 wsl" >&2
        exit 1
      fi
      SETUP_TYPE=$2
      shift 2
      ;;
    --type=*)
      SETUP_TYPE=${1#--type=}
      shift
      ;;
    -h | --help)
      HELP_REQUESTED=true
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [ "$HELP_REQUESTED" = true ] && [ -z "$SETUP_TYPE" ]; then
  usage
  exit 0
fi

if [ "$HELP_REQUESTED" = true ]; then
  ARGS+=(--help)
fi

if [ -z "$SETUP_TYPE" ]; then
  if ! SETUP_TYPE="$(detect_setup_type)"; then
    echo "[ERROR] 지원 플랫폼을 자동 감지할 수 없습니다." >&2
    echo "        macOS 또는 WSL만 자동 지원합니다. 일반 Linux는 --type wsl을 명시하세요." >&2
    usage >&2
    exit 1
  fi
fi

case "$SETUP_TYPE" in
  macos)
    exec "$SCRIPT_DIR/scripts/setup-macos.sh" "${ARGS[@]}"
    ;;
  wsl)
    exec "$SCRIPT_DIR/scripts/setup-wsl.sh" "${ARGS[@]}"
    ;;
  *)
    echo "[ERROR] 알 수 없는 --type 값: $SETUP_TYPE (macos 또는 wsl)" >&2
    exit 1
    ;;
esac
