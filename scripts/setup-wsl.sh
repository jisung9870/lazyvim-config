#!/usr/bin/env bash
# ========================================
# LazyVim DevOps 환경 설정 - WSL / Ubuntu Linux
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
require_supported_linux

IS_WSL=false
if grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
  IS_WSL=true
  info "WSL 환경 감지됨"
fi

ARCH="$(detect_arch)"
TMP_DIR="${TMPDIR:-/tmp}"
GOLANG_VERSION="$(read_tool_version golang)"
NODEJS_VERSION="$(read_tool_version nodejs)"
PYTHON_VERSION="$(read_tool_version python)"

APT_PACKAGES=(
  build-essential
  curl
  wget
  git
  unzip
  tar
  gzip
  cmake
  gettext
  software-properties-common
  ca-certificates
  gnupg
  ripgrep
  fd-find
  fzf
  tmux
  shellcheck
)

PYTHON_BUILD_PACKAGES=(
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  libncursesw5-dev
  xz-utils
  tk-dev
  libxml2-dev
  libxmlsec1-dev
  libffi-dev
  liblzma-dev
)

NPM_PACKAGES=(prettier neovim)
GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "mvdan.cc/gofumpt@latest"
  "golang.org/x/tools/cmd/goimports@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
)

check_apt_package() {
  local package=$1

  if dpkg -s "$package" >/dev/null 2>&1; then
    ok "apt: $package 설치됨"
  else
    warn "apt: $package 없음"
  fi
}

install_apt_packages() {
  local package

  run_step "apt package index 업데이트" sudo apt-get update -qq
  run_step "기본 패키지 설치" sudo apt-get install -y -qq "${APT_PACKAGES[@]}"
  run_step "Python 빌드 의존성 설치" sudo apt-get install -y -qq "${PYTHON_BUILD_PACKAGES[@]}"

  if [ "$DRY_RUN" != true ]; then
    for package in "${APT_PACKAGES[@]}" "${PYTHON_BUILD_PACKAGES[@]}"; do
      check_apt_package "$package"
    done
  fi
}

nvim_needs_install() {
  local major
  local minor
  local version

  if ! has_cmd nvim; then
    return 0
  fi

  version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [ -z "$version" ]; then
    return 0
  fi

  IFS=. read -r major minor <<<"$version"
  ((major == 0 && minor < 10))
}

nvim_appimage_asset() {
  case "$ARCH" in
    x86_64)
      echo "nvim.appimage"
      ;;
    aarch64)
      echo "nvim-linux-arm64.appimage"
      ;;
    *)
      error "지원하지 않는 Neovim AppImage 아키텍처입니다: $ARCH"
      ;;
  esac
}

ensure_neovim() {
  local asset
  local target="${TMP_DIR}/nvim-${NVIM_VERSION}.appimage"

  if ! nvim_needs_install; then
    ok "Neovim 확인됨 ($(nvim --version | head -1))"
    return 0
  fi

  if [ "$INSTALL" != true ]; then
    warn "Neovim 0.10+ 없음 (--install 사용 시 설치)"
    return 0
  fi

  asset="$(nvim_appimage_asset)"
  run_step "Neovim ${NVIM_VERSION} AppImage 다운로드 (${ARCH})" curl -Lo "$target" "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${asset}"
  run_step "Neovim AppImage 실행 권한 부여" chmod u+x "$target"
  run_step "Neovim AppImage 설치" sudo mv "$target" /usr/local/bin/nvim
}

ensure_fd_link() {
  if has_cmd fd || ! has_cmd fdfind; then
    return 0
  fi

  if [ "$INSTALL" = true ]; then
    ensure_dir "$HOME/.local/bin"
    run_step "fd 링크 생성" ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  else
    warn "fdfind는 있으나 fd 링크가 없음 (--install 사용 시 생성)"
  fi
}

lazygit_asset_arch() {
  case "$ARCH" in
    x86_64)
      echo "x86_64"
      ;;
    aarch64)
      echo "arm64"
      ;;
    *)
      error "지원하지 않는 lazygit 아키텍처입니다: $ARCH"
      ;;
  esac
}

ensure_lazygit() {
  local asset_arch

  if has_cmd lazygit; then
    ok "lazygit 이미 설치됨"
    return 0
  fi

  if [ "$INSTALL" != true ]; then
    warn "lazygit 없음 (--install 사용 시 설치)"
    return 0
  fi

  asset_arch="$(lazygit_asset_arch)"
  run_step "lazygit 최신 release 설치" bash -c "set -euo pipefail
version=\$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '\"tag_name\": \"v\\K[^\"]*')
curl -fsSLo '$TMP_DIR/lazygit.tar.gz' \"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_\${version}_Linux_${asset_arch}.tar.gz\"
tar -xf '$TMP_DIR/lazygit.tar.gz' -C '$TMP_DIR' lazygit
sudo install '$TMP_DIR/lazygit' /usr/local/bin/lazygit
rm -f '$TMP_DIR/lazygit' '$TMP_DIR/lazygit.tar.gz'"
}

check_runtime_state() {
  check_cmd asdf "asdf" || true
  check_asdf_tool "golang" "$GOLANG_VERSION" || true
  check_asdf_tool "nodejs" "$NODEJS_VERSION" || true
  check_asdf_tool "python" "$PYTHON_VERSION" || true
}

install_runtime_tools() {
  install_asdf_tool "golang" "$GOLANG_VERSION" "wsl"
  install_asdf_tool "nodejs" "$NODEJS_VERSION" "wsl"
  install_asdf_tool "python" "$PYTHON_VERSION" "wsl"
}

ensure_shfmt() {
  if has_cmd shfmt; then
    ok "shfmt 이미 설치됨"
  elif [ "$INSTALL" = true ]; then
    run_step "shfmt 설치" go install mvdan.cc/sh/v3/cmd/shfmt@latest
    run_step "asdf golang reshim" asdf reshim golang
  else
    warn "shfmt 없음 (--install 사용 시 설치)"
  fi
}

stylua_asset_arch() {
  case "$ARCH" in
    x86_64)
      echo "x86_64"
      ;;
    aarch64)
      echo "aarch64"
      ;;
    *)
      error "지원하지 않는 stylua 아키텍처입니다: $ARCH"
      ;;
  esac
}

ensure_stylua() {
  local asset_arch

  if has_cmd stylua; then
    ok "stylua 이미 설치됨"
  elif [ "$INSTALL" = true ]; then
    asset_arch="$(stylua_asset_arch)"
    run_step "stylua 최신 release 설치" bash -c "set -euo pipefail
version=\$(curl -fsSL https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -Po '\"tag_name\": \"\\K[^\"]*')
rm -rf '$TMP_DIR/stylua-bin'
curl -fsSLo '$TMP_DIR/stylua.zip' \"https://github.com/JohnnyMorganz/StyLua/releases/download/\${version}/stylua-linux-${asset_arch}.zip\"
unzip -o '$TMP_DIR/stylua.zip' -d '$TMP_DIR/stylua-bin'
sudo install '$TMP_DIR/stylua-bin/stylua' /usr/local/bin/stylua
rm -rf '$TMP_DIR/stylua.zip' '$TMP_DIR/stylua-bin'"
  else
    warn "stylua 없음 (--install 사용 시 설치)"
  fi
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

install_devops_tools() {
  if has_cmd terraform; then
    ok "Terraform 이미 설치됨"
  else
    # The command substitution must run inside the child shell on the target host.
    # shellcheck disable=SC2016
    run_step "HashiCorp apt repository 추가" bash -c 'set -euo pipefail
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null'
    run_step "Terraform 설치" bash -c 'sudo apt-get update -qq && sudo apt-get install -y -qq terraform'
  fi

  if has_cmd ansible-lint; then
    ok "ansible-lint 이미 설치됨"
  else
    run_step "ansible-lint 설치" asdf exec python -m pip install ansible-lint
    run_step "asdf python reshim" asdf reshim python
  fi
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

ensure_font() {
  local font_dir="$HOME/.local/share/fonts"

  if fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
    ok "JetBrainsMono Nerd Font 이미 설치됨"
  elif [ "$WITH_FONT" = true ]; then
    ensure_dir "$font_dir"
    run_step "JetBrainsMono Nerd Font 최신 release 설치" bash -c "set -euo pipefail
version=\$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -Po '\"tag_name\": \"\\K[^\"]*')
rm -rf '$font_dir/JetBrainsMono'
mkdir -p '$font_dir/JetBrainsMono'
curl -fsSLo '$TMP_DIR/JetBrainsMono.zip' \"https://github.com/ryanoasis/nerd-fonts/releases/download/\${version}/JetBrainsMono.zip\"
unzip -o '$TMP_DIR/JetBrainsMono.zip' -d '$font_dir/JetBrainsMono'
fc-cache -fv '$font_dir' >/dev/null 2>&1
rm -f '$TMP_DIR/JetBrainsMono.zip'"
    if [ "$IS_WSL" = true ]; then
      warn "WSL 사용자: Windows Terminal 설정에서 폰트를 'JetBrainsMono Nerd Font'로 변경해주세요"
    fi
  else
    warn "JetBrainsMono Nerd Font 없음 (--with-font 사용 시 설치)"
  fi
}

check_wsl_im() {
  if [ "$IS_WSL" != true ]; then
    return 0
  fi

  info "WSL 환경 추가 설정 확인..."
  if has_cmd clip.exe; then
    ok "clip.exe 사용 가능 (클립보드 연동 가능)"
  else
    warn "clip.exe를 찾을 수 없습니다. Windows System32 PATH를 확인하세요"
  fi

  if has_cmd im-select.exe; then
    ok "im-select.exe 사용 가능"
  elif [ "$WITH_IM" = true ]; then
    warn "im-select.exe 설치는 Windows 쪽에서 수동으로 진행하세요:"
    warn "  https://github.com/daipeihust/im-select#windows"
  else
    warn "WSL 한/영 자동 전환은 --with-im 사용 시 안내를 표시합니다"
  fi
}

local_lua_template() {
  if [ "$IS_WSL" = true ]; then
    cat <<'LOCALEOF'
-- WSL 전용 로컬 설정
-- 이 파일은 .gitignore에 포함되어 머신별 고유 설정을 넣는 곳입니다.

-- WSL 클립보드 연동
vim.g.clipboard = {
  name = "WslClipboard",
  copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
  paste = {
    ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}
LOCALEOF
  else
    cat <<'LOCALEOF'
-- Linux 전용 로컬 설정
-- 이 파일은 .gitignore에 포함되어 머신별 고유 설정을 넣는 곳입니다.
LOCALEOF
  fi
}

ensure_links_and_local_config() {
  local nvim_config_dir="$HOME/.config/nvim"
  local tmux_config_src="$SCRIPT_DIR/scripts/config/.tmux.conf"
  local tmux_config_dest="$HOME/.tmux.conf"
  local local_lua="$SCRIPT_DIR/lua/config/local.lua"
  local sessionizer_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer/dirs"
  local sessionizer_example="$SCRIPT_DIR/scripts/config/tmux-sessionizer.dirs.example"

  ensure_symlink "$SCRIPT_DIR" "$nvim_config_dir" "nvim 설정"
  ensure_symlink "$tmux_config_src" "$tmux_config_dest" "tmux 설정"
  write_file_if_missing "$local_lua" "local.lua" "$(local_lua_template)"
  write_file_if_missing "$sessionizer_dirs" "tmux-sessionizer dirs" "$(cat "$sessionizer_example")"

  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "$HOME/.local/bin이 PATH에 없습니다. shell rc에 추가합니다."
    append_path_once "$HOME/.bashrc" "$HOME/.local/bin"
    if [ -f "$HOME/.zshrc" ]; then
      append_path_once "$HOME/.zshrc" "$HOME/.local/bin"
    fi
  fi
}

check_links_and_local_config() {
  local nvim_config_dir="$HOME/.config/nvim"
  local tmux_config_src="$SCRIPT_DIR/scripts/config/.tmux.conf"
  local tmux_config_dest="$HOME/.tmux.conf"
  local local_lua="$SCRIPT_DIR/lua/config/local.lua"
  local sessionizer_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer/dirs"

  check_symlink_status "$SCRIPT_DIR" "$nvim_config_dir" "nvim 설정" || true
  check_symlink_status "$tmux_config_src" "$tmux_config_dest" "tmux 설정" || true
  if [ -f "$local_lua" ]; then
    ok "local.lua 존재: $local_lua"
  else
    warn "local.lua 없음 (--link 사용 시 템플릿 생성)"
  fi
  if [ -f "$sessionizer_dirs" ]; then
    ok "tmux-sessionizer dirs 존재: $sessionizer_dirs"
  else
    warn "tmux-sessionizer dirs 없음 (--link 사용 시 예시로 생성)"
  fi
}

if [ "$INSTALL" = true ]; then
  install_apt_packages
else
  for package in "${APT_PACKAGES[@]}" "${PYTHON_BUILD_PACKAGES[@]}"; do
    check_apt_package "$package"
  done
fi

ensure_neovim
ensure_fd_link
ensure_lazygit
check_runtime_state

if [ "$INSTALL" = true ]; then
  install_runtime_tools
  ensure_shfmt
  ensure_stylua
  install_npm_packages
  install_devops_tools
  install_go_tools
else
  ensure_shfmt
  ensure_stylua
  check_cmd npm "npm" || true
  check_cmd go "go" || true
  check_cmd terraform "Terraform" || true
  check_cmd ansible-lint "ansible-lint" || true
fi
ensure_tpm

ensure_font
check_wsl_im

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
echo "  Go $GOLANG_VERSION / Node.js $NODEJS_VERSION / Python $PYTHON_VERSION / Neovim $NVIM_VERSION / Arch $ARCH"
echo ""
echo "asdf 현재 상태:"
asdf current 2>/dev/null || true
echo ""
echo "다음 단계:"
echo "  1. 변경 전 확인: ./scripts/setup.sh --type wsl --install --link --with-font --with-im --with-tmux-plugins --dry-run"
if [ "$IS_WSL" = true ]; then
  echo "  2. Windows Terminal 폰트를 'JetBrainsMono Nerd Font'로 변경"
  echo "  3. 새 터미널 세션을 열어 PATH 갱신"
else
  echo "  2. 터미널 폰트를 'JetBrainsMono Nerd Font'로 변경"
fi
echo "  4. nvim 실행 -> 플러그인 자동 설치 대기"
echo "  5. :checkhealth 로 상태 확인"
echo "  6. ./scripts/setup.sh --type wsl --sync --sync-plugins 로 repo/plugin 버전 동기화"
echo ""
