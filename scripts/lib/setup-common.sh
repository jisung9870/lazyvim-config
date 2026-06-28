#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL=false
LINK=false
WITH_FONT=false
WITH_IM=false
WITH_TMUX_PLUGINS=false
YES=false
DRY_RUN=false

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

usage() {
  cat <<USAGE
Usage: $0 [--install] [--link] [--with-font] [--with-im] [--with-tmux-plugins] [--dry-run] [--yes]

Default mode only checks current machine state. Use flags to make changes.

  --install            Install missing packages, asdf tools, and CLI dependencies.
  --link               Create Neovim/tmux symlinks and local.lua template.
  --with-font          Install JetBrainsMono Nerd Font.
  --with-im            Install/check input-method helper where supported.
  --with-tmux-plugins  Clone TPM and install tmux plugins. Requires --install.
  --dry-run            Print changes that would run without changing files/system.
  --yes                Allow backup/move of existing files during --link.
  -h, --help           Show this help.
USAGE
}

parse_setup_flags() {
  while (($#)); do
    case "$1" in
      --install)
        INSTALL=true
        ;;
      --link)
        LINK=true
        ;;
      --with-font)
        WITH_FONT=true
        ;;
      --with-im)
        WITH_IM=true
        ;;
      --with-tmux-plugins)
        WITH_TMUX_PLUGINS=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --yes)
        YES=true
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        error "알 수 없는 옵션: $1"
        ;;
    esac
    shift
  done

  if [ "$WITH_TMUX_PLUGINS" = true ] && [ "$INSTALL" != true ]; then
    error "--with-tmux-plugins는 --install과 함께 사용하세요."
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

quote_cmd() {
  local quoted=()
  local arg

  for arg in "$@"; do
    quoted+=("$(printf '%q' "$arg")")
  done
  printf '%s' "${quoted[*]}"
}

run_step() {
  local description=$1
  shift

  if [ "$DRY_RUN" = true ]; then
    info "DRY-RUN: $description"
    echo "  $(quote_cmd "$@")"
    return 0
  fi

  info "$description"
  "$@"
  ok "$description 완료"
}

ensure_dir() {
  local dir=$1

  if [ -d "$dir" ]; then
    return 0
  fi
  run_step "디렉터리 생성: $dir" mkdir -p "$dir"
}

append_path_once() {
  local rc_file=$1
  local path_entry=$2

  if [ -f "$rc_file" ] && grep -Fq "$path_entry" "$rc_file"; then
    ok "PATH 이미 설정됨: $rc_file -> $path_entry"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    info "DRY-RUN: PATH 추가: $rc_file -> $path_entry"
    # shellcheck disable=SC2016
    printf '  printf "\\nexport PATH=\\"%s:\\$PATH\\"\\n" >> "%s"\n' "$path_entry" "$rc_file"
    return 0
  fi

  printf "\nexport PATH=\"%s:\$PATH\"\n" "$path_entry" >>"$rc_file"
  ok "PATH 추가: $rc_file -> $path_entry"
}

backup_file_or_dir() {
  local target=$1
  local backup
  backup="${target}.backup.$(date +%Y%m%d%H%M%S)"

  if [ "$YES" != true ]; then
    if [ "$DRY_RUN" = true ]; then
      warn "DRY-RUN: 기존 파일/디렉터리 백업 필요: $target -> $backup (--yes 필요)"
      return 0
    fi
    error "기존 파일/디렉터리 발견: $target (--yes 없이 자동 백업하지 않음)"
  fi

  run_step "백업 생성: $target -> $backup" mv "$target" "$backup"
}

ensure_symlink() {
  local source=$1
  local dest=$2
  local label=${3:-$dest}
  local current_target

  if [ -L "$dest" ]; then
    current_target=$(readlink "$dest")
    if [ "$current_target" = "$source" ]; then
      ok "$label 심볼릭 링크 이미 올바르게 설정됨"
      return 0
    fi
    warn "$label 심볼릭 링크가 다른 경로를 가리킴: $current_target"
    if [ "$YES" != true ]; then
      if [ "$DRY_RUN" = true ]; then
        warn "DRY-RUN: $dest 교체가 필요합니다. 실제 실행 시 --yes를 사용하세요."
        return 0
      fi
      error "$dest 교체가 필요합니다. 계속하려면 --yes를 사용하세요."
    fi
    run_step "기존 심볼릭 링크 제거: $dest" rm "$dest"
  elif [ -e "$dest" ]; then
    warn "기존 $label 발견: $dest"
    backup_file_or_dir "$dest"
    if [ "$DRY_RUN" = true ]; then
      return 0
    fi
  fi

  ensure_dir "$(dirname "$dest")"
  run_step "심볼릭 링크 생성: $dest -> $source" ln -s "$source" "$dest"
}

check_symlink_status() {
  local source=$1
  local dest=$2
  local label=${3:-$dest}
  local current_target

  if [ -L "$dest" ]; then
    current_target=$(readlink "$dest")
    if [ "$current_target" = "$source" ]; then
      ok "$label 심볼릭 링크 정상: $dest -> $source"
      return 0
    fi
    warn "$label 심볼릭 링크 대상 다름: $dest -> $current_target (기대: $source)"
    warn "--link --yes 사용 시 교체합니다."
    return 1
  fi

  if [ -e "$dest" ]; then
    warn "$label 경로가 이미 존재하지만 심볼릭 링크가 아님: $dest"
    warn "--link --yes 사용 시 백업 후 교체합니다."
    return 1
  fi

  warn "$label 심볼릭 링크 없음: $dest (--link 사용 시 생성)"
  return 1
}

write_file_if_missing() {
  local file=$1
  local label=$2
  local content=$3

  if [ -f "$file" ]; then
    ok "$label 이미 존재"
    return 0
  fi

  ensure_dir "$(dirname "$file")"
  if [ "$DRY_RUN" = true ]; then
    info "DRY-RUN: $label 생성: $file"
    return 0
  fi

  printf '%s\n' "$content" >"$file"
  ok "$label 생성 완료: $file"
}

check_cmd() {
  local command_name=$1
  local label=${2:-$command_name}

  if has_cmd "$command_name"; then
    ok "$label 확인됨 ($(command -v "$command_name"))"
    return 0
  fi

  warn "$label 없음"
  return 1
}

read_tool_version() {
  local tool=$1
  local versions_file=${2:-$SCRIPT_DIR/.tool-versions}

  if [ ! -f "$versions_file" ]; then
    error "버전 파일을 찾을 수 없습니다: $versions_file"
  fi

  awk -v tool="$tool" '$1 == tool { print $2; found = 1 } END { exit found ? 0 : 1 }' "$versions_file" ||
    error "$versions_file에 $tool 버전이 없습니다."
}

detect_arch() {
  local machine
  machine=$(uname -m)

  case "$machine" in
    x86_64 | amd64)
      echo "x86_64"
      ;;
    arm64 | aarch64)
      echo "aarch64"
      ;;
    *)
      error "지원하지 않는 CPU 아키텍처입니다: $machine"
      ;;
  esac
}

require_supported_linux() {
  if [ ! -r /etc/os-release ]; then
    error "/etc/os-release를 읽을 수 없어 지원 Linux 배포판인지 확인할 수 없습니다."
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    ubuntu | debian)
      ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*)
          ;;
        *)
          error "지원 대상은 Ubuntu/Debian 계열 Linux입니다. 현재: ${PRETTY_NAME:-unknown}"
          ;;
      esac
      ;;
  esac

  has_cmd apt-get || error "apt-get을 찾을 수 없습니다. Ubuntu/Debian 계열 환경에서 실행하세요."
  has_cmd dpkg || error "dpkg를 찾을 수 없습니다. Ubuntu/Debian 계열 환경에서 실행하세요."
}

asdf_install_hint() {
  local platform=${1:-common}

  case "$platform" in
    macos)
      echo "asdf가 없습니다. macOS: brew install asdf 후 shell rc에 asdf 초기화를 추가하고 새 터미널에서 다시 실행하세요."
      ;;
    wsl | linux)
      echo "asdf가 없습니다. Ubuntu/WSL: 공식 가이드에 따라 asdf를 설치하고 shell rc를 갱신한 뒤 다시 실행하세요."
      ;;
    *)
      echo "asdf가 없습니다. https://asdf-vm.com/guide/getting-started.html 참고하여 먼저 설치하세요."
      ;;
  esac
}

check_asdf_tool() {
  local plugin=$1
  local version=$2

  if ! has_cmd asdf; then
    warn "asdf 없음: $plugin $version 확인 불가"
    return 1
  fi

  if asdf list "$plugin" 2>/dev/null | grep -Fq "$version"; then
    ok "asdf $plugin $version 설치됨"
  else
    warn "asdf $plugin $version 없음"
  fi
}

install_asdf_tool() {
  local plugin=$1
  local version=$2
  local platform=${3:-common}

  if ! has_cmd asdf && [ "$DRY_RUN" != true ]; then
    error "$(asdf_install_hint "$platform")"
  fi

  if [ "$DRY_RUN" = true ]; then
    run_step "asdf plugin 추가 확인/추가: $plugin" asdf plugin add "$plugin"
    run_step "$plugin $version 설치 확인/설치" asdf install "$plugin" "$version"
    run_step "$plugin $version -> ~/.tool-versions 설정" asdf set --home "$plugin" "$version"
    return 0
  fi

  if ! asdf plugin list 2>/dev/null | grep -qx "$plugin"; then
    run_step "asdf plugin 추가: $plugin" asdf plugin add "$plugin"
  else
    ok "asdf plugin 이미 있음: $plugin"
  fi

  if asdf list "$plugin" 2>/dev/null | grep -Fq "$version"; then
    ok "$plugin $version 이미 설치됨"
  else
    run_step "$plugin $version 설치" asdf install "$plugin" "$version"
  fi

  run_step "$plugin $version -> ~/.tool-versions 설정" asdf set --home "$plugin" "$version"
}

check_tpm_status() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ -d "$tpm_dir" ]; then
    ok "TPM 설치됨"
  else
    warn "TPM 없음 (--install --with-tmux-plugins 사용 시 설치)"
  fi
}

print_mode_summary() {
  info "모드: install=$INSTALL link=$LINK with-font=$WITH_FONT with-im=$WITH_IM with-tmux-plugins=$WITH_TMUX_PLUGINS dry-run=$DRY_RUN yes=$YES"
  if [ "$INSTALL" != true ] && [ "$LINK" != true ] && [ "$WITH_FONT" != true ] && [ "$WITH_IM" != true ] && [ "$WITH_TMUX_PLUGINS" != true ]; then
    info "기본 점검 모드입니다. 설치/링크/파일 생성은 수행하지 않습니다."
  fi
}
