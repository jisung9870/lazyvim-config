#!/usr/bin/env bash
# ========================================
# LazyVim DevOps 환경 설정 - macOS
# ========================================
# 기본 실행은 점검만 수행합니다. 설치/링크/파일 생성은 플래그로 명시하세요.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/setup-common.sh
source "$SCRIPT_DIR/scripts/lib/setup-common.sh"
# shellcheck source=scripts/lib/setup-versions.sh
source "$SCRIPT_DIR/scripts/lib/setup-versions.sh"
parse_setup_flags "$@"
print_mode_summary
sync_repository
sync_plugins

GOLANG_VERSION="$(read_tool_version golang)"
NODEJS_VERSION="$(read_tool_version nodejs)"
PYTHON_VERSION="$(read_tool_version python)"

BREW_PACKAGES=(
  neovim
  ripgrep
  fd
  lazygit
  tmux
  fzf
  tree-sitter
  wget
  curl
)

FORMATTER_PACKAGES=(
  shfmt
  stylua
  shellcheck
)

NPM_PACKAGES=(prettier neovim)
GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "mvdan.cc/gofumpt@latest"
  "golang.org/x/tools/cmd/goimports@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
)

brew_has_package() {
  brew list "$1" >/dev/null 2>&1
}

install_brew_package() {
  local package=$1

  if brew_has_package "$package"; then
    ok "brew: $package 이미 설치됨"
  else
    run_step "brew: $package 설치" brew install "$package"
  fi
}

check_brew_package() {
  local package=$1

  if has_cmd brew && brew_has_package "$package"; then
    ok "brew: $package 설치됨"
  else
    warn "brew: $package 없음"
  fi
}

ensure_homebrew() {
  if has_cmd brew; then
    ok "Homebrew 확인됨"
    return 0
  fi

  if [ "$INSTALL" != true ]; then
    warn "Homebrew 없음"
    return 1
  fi

  run_step "Homebrew 설치" /bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
  if [ "$DRY_RUN" = true ]; then
    return 0
  fi

  if [[ $(uname -m) == "arm64" ]]; then
    local brew_shellenv
    brew_shellenv="eval \"\$(/opt/homebrew/bin/brew shellenv)\""
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! grep -Fq "$brew_shellenv" "$HOME/.zprofile" 2>/dev/null; then
      printf '%s\n' "$brew_shellenv" >>"$HOME/.zprofile"
    fi
  fi
}

check_runtime_state() {
  check_cmd asdf "asdf" || true
  check_asdf_tool "golang" "$GOLANG_VERSION" || true
  check_asdf_tool "nodejs" "$NODEJS_VERSION" || true
  check_asdf_tool "python" "$PYTHON_VERSION" || true
}

install_runtime_tools() {
  install_asdf_tool "golang" "$GOLANG_VERSION" "macos"
  install_asdf_tool "nodejs" "$NODEJS_VERSION" "macos"
  install_asdf_tool "python" "$PYTHON_VERSION" "macos"
}

install_npm_packages() {
  local package

  for package in "${NPM_PACKAGES[@]}"; do
    if npm list -g "$package" >/dev/null 2>&1; then
      ok "npm: $package 이미 설치됨"
    else
      run_step "npm: $package 전역 설치" npm install -g "$package"
    fi
  done
  run_step "asdf nodejs reshim" asdf reshim nodejs
}

install_go_tools() {
  local tool
  local tool_name

  for tool in "${GO_TOOLS[@]}"; do
    tool_name=$(basename "${tool%%@*}")
    if has_cmd "$tool_name"; then
      ok "go: $tool_name 이미 설치됨"
    else
      run_step "go: $tool_name 설치" go install "$tool"
    fi
  done
  run_step "asdf golang reshim" asdf reshim golang
}

install_devops_tools() {
  if has_cmd terraform; then
    ok "Terraform 이미 설치됨"
  else
    run_step "HashiCorp brew tap 추가" brew tap hashicorp/tap
    run_step "Terraform 설치" brew install hashicorp/tap/terraform
  fi

  if has_cmd ansible-lint; then
    ok "ansible-lint 이미 설치됨"
  else
    run_step "ansible-lint 설치" asdf exec python -m pip install ansible-lint
    run_step "asdf python reshim" asdf reshim python
  fi
}

ensure_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ "$WITH_TMUX_PLUGINS" != true ]; then
    check_tpm_status
    return 0
  fi

  if [ "$INSTALL" != true ]; then
    check_tpm_status
    return 0
  fi

  if [ -d "$tpm_dir" ]; then
    ok "TPM 이미 설치됨"
  else
    ensure_dir "$(dirname "$tpm_dir")"
    run_step "tmux TPM clone" git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  if [ "$DRY_RUN" = true ] || [ -x "$tpm_dir/bin/install_plugins" ]; then
    run_step "tmux 플러그인 설치 (TPM)" "$tpm_dir/bin/install_plugins"
  fi
}

ensure_macism() {
  if has_cmd macism; then
    ok "macism 이미 설치됨"
  elif [ "$WITH_IM" = true ]; then
    run_step "macism 설치 (한/영 자동 전환)" brew install macism
  else
    warn "macism 없음 (--with-im 사용 시 설치)"
  fi
}

ensure_font() {
  if has_cmd brew && brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    ok "JetBrainsMono Nerd Font cask 설치됨"
  elif system_profiler SPFontsDataType 2>/dev/null | grep -qi "JetBrainsMono"; then
    ok "JetBrainsMono Nerd Font 확인됨"
  elif [ "$WITH_FONT" = true ]; then
    run_step "JetBrainsMono Nerd Font 설치" brew install --cask font-jetbrains-mono-nerd-font
    warn "터미널 앱에서 폰트를 'JetBrainsMono Nerd Font'로 변경해주세요"
  else
    warn "JetBrainsMono Nerd Font 없음 (--with-font 사용 시 설치)"
  fi
}

local_lua_template() {
  cat <<'LOCALEOF'
-- macOS 전용 로컬 설정
-- 이 파일은 .gitignore에 포함되어 머신별 고유 설정을 넣는 곳입니다.

-- 폰트 설정 (GUI Neovim 사용 시)
-- vim.opt.guifont = "JetBrainsMono Nerd Font:h14"
LOCALEOF
}

ensure_links_and_local_config() {
  local nvim_config_dir="$HOME/.config/nvim"
  local tmux_config_src="$SCRIPT_DIR/scripts/config/.tmux.conf"
  local tmux_config_dest="$HOME/.tmux.conf"
  local local_lua="$SCRIPT_DIR/lua/config/local.lua"

  ensure_symlink "$SCRIPT_DIR" "$nvim_config_dir" "nvim 설정"
  ensure_symlink "$tmux_config_src" "$tmux_config_dest" "tmux 설정"
  write_file_if_missing "$local_lua" "macOS local.lua" "$(local_lua_template)"
}

check_links_and_local_config() {
  local nvim_config_dir="$HOME/.config/nvim"
  local tmux_config_src="$SCRIPT_DIR/scripts/config/.tmux.conf"
  local tmux_config_dest="$HOME/.tmux.conf"
  local local_lua="$SCRIPT_DIR/lua/config/local.lua"

  check_symlink_status "$SCRIPT_DIR" "$nvim_config_dir" "nvim 설정" || true
  check_symlink_status "$tmux_config_src" "$tmux_config_dest" "tmux 설정" || true
  if [ -f "$local_lua" ]; then
    ok "local.lua 존재: $local_lua"
  else
    warn "local.lua 없음 (--link 사용 시 템플릿 생성)"
  fi
}

ensure_homebrew || true

if [ "$INSTALL" = true ] && [ "$DRY_RUN" != true ] && ! has_cmd brew; then
  error "Homebrew 설치 후 brew 명령을 찾을 수 없습니다. 새 터미널에서 다시 실행하세요."
fi

for package in "${BREW_PACKAGES[@]}" "${FORMATTER_PACKAGES[@]}"; do
  if [ "$INSTALL" = true ]; then
    install_brew_package "$package"
  else
    check_brew_package "$package"
  fi
done

check_runtime_state
if [ "$INSTALL" = true ]; then
  install_runtime_tools
  install_npm_packages
  install_devops_tools
  install_go_tools
fi
ensure_tpm

ensure_macism
ensure_font

if [ "$LINK" = true ]; then
  ensure_links_and_local_config
else
  check_links_and_local_config
fi

echo ""
echo -e "${GREEN}========================================${NC}"
if [ "$INSTALL" = true ] || [ "$LINK" = true ] || [ "$SYNC" = true ] || [ "$SYNC_PLUGINS" = true ] || [ "$WITH_FONT" = true ] || [ "$WITH_IM" = true ] || [ "$WITH_TMUX_PLUGINS" = true ]; then
  echo -e "${GREEN}  설정 완료${NC}"
else
  echo -e "${GREEN}  점검 완료${NC}"
fi
echo -e "${GREEN}========================================${NC}"
echo ""
echo "버전 기준:"
echo "  Go $GOLANG_VERSION / Node.js $NODEJS_VERSION / Python $PYTHON_VERSION / Neovim $NVIM_VERSION"
echo ""
echo "asdf 현재 상태:"
asdf current 2>/dev/null || true
echo ""
echo "다음 단계:"
echo "  1. 변경 전 확인: ./scripts/setup.sh --install --link --with-font --with-im --with-tmux-plugins --dry-run"
echo "  2. 필요한 변경은 --install --link --with-font --with-im --with-tmux-plugins 중 선택해 재실행"
echo "  3. nvim 실행 -> 플러그인 자동 설치 대기"
echo "  4. :checkhealth 로 상태 확인"
echo "  5. ./scripts/setup.sh --sync --sync-plugins 로 repo/plugin 버전 동기화"
echo ""
