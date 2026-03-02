#!/bin/bash
# ========================================
# LazyVim DevOps 환경 설정 - WSL / Ubuntu Linux
# ========================================
# 사용법: chmod +x scripts/setup-wsl.sh && ./scripts/setup-wsl.sh
#
# 대상: Ubuntu 22.04+ (WSL2) 또는 Ubuntu/Debian Linux
# 도구 버전 관리: asdf 0.18.0+ (asdf set --home 사용)
# 런타임 (Go, Node.js, Python): asdf로 설치/관리
# CLI 도구: apt 또는 바이너리 직접 설치

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# WSL 여부 감지
IS_WSL=false
if grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
  IS_WSL=true
  info "WSL 환경 감지됨"
fi

# ========================================
# asdf로 설치할 런타임 버전 (필요 시 수정)
# ========================================
GOLANG_VERSION="1.23.5"
NODEJS_VERSION="22.13.1"
PYTHON_VERSION="3.13.1"

# ========================================
# 1. 기본 패키지
# ========================================
info "시스템 패키지 업데이트 및 기본 도구 설치..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  build-essential \
  curl \
  wget \
  git \
  unzip \
  tar \
  gzip \
  cmake \
  gettext \
  software-properties-common \
  ca-certificates \
  gnupg
ok "기본 패키지 설치 완료"

# asdf python 빌드 의존성
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
info "Python 빌드 의존성 설치 중..."
sudo apt-get install -y -qq \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev
ok "Python 빌드 의존성 설치 완료"

# ========================================
# 2. asdf 확인
# ========================================
if ! command -v asdf &>/dev/null; then
  error "asdf가 설치되어 있지 않습니다. https://asdf-vm.com/guide/getting-started.html 참고하여 먼저 설치해주세요."
fi
ok "asdf 확인됨"

# ========================================
# 3. Neovim (최신 stable)
# ========================================
if ! command -v nvim &>/dev/null || [[ "$(nvim --version | head -1 | grep -oP '\d+\.\d+')" < "0.10" ]]; then
  info "Neovim 최신 stable 설치 중..."
  if sudo add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq neovim
    ok "Neovim 설치 완료 (PPA)"
  else
    info "PPA 실패, AppImage로 설치 중..."
    NVIM_VERSION="v0.10.3"
    curl -Lo /tmp/nvim.appimage "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage"
    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
    ok "Neovim 설치 완료 (AppImage)"
  fi
else
  ok "Neovim 이미 설치됨 ($(nvim --version | head -1))"
fi

# ========================================
# 4. 핵심 의존성
# ========================================

# ripgrep
if ! command -v rg &>/dev/null; then
  info "ripgrep 설치 중..."
  sudo apt-get install -y -qq ripgrep
  ok "ripgrep 설치 완료"
else
  ok "ripgrep 이미 설치됨"
fi

# fd
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
  info "fd-find 설치 중..."
  sudo apt-get install -y -qq fd-find
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p ~/.local/bin
    ln -sf "$(which fdfind)" ~/.local/bin/fd
  fi
  ok "fd 설치 완료"
else
  ok "fd 이미 설치됨"
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
  info "lazygit 설치 중..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm -f /tmp/lazygit /tmp/lazygit.tar.gz
  ok "lazygit 설치 완료"
else
  ok "lazygit 이미 설치됨"
fi

# fzf
if ! command -v fzf &>/dev/null; then
  info "fzf 설치 중..."
  sudo apt-get install -y -qq fzf || {
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-update-rc
  }
  ok "fzf 설치 완료"
else
  ok "fzf 이미 설치됨"
fi

# tmux
if ! command -v tmux &>/dev/null; then
  info "tmux 설치 중..."
  sudo apt-get install -y -qq tmux
  ok "tmux 설치 완료"
else
  ok "tmux 이미 설치됨"
fi

# ========================================
# 5. asdf 런타임 설치
# ========================================
install_asdf_tool() {
  local plugin=$1
  local version=$2

  # 플러그인 추가
  if ! asdf plugin list 2>/dev/null | grep -q "^${plugin}$"; then
    info "asdf plugin 추가: $plugin"
    asdf plugin add "$plugin"
    ok "asdf plugin 추가 완료: $plugin"
  else
    ok "asdf plugin 이미 있음: $plugin"
  fi

  # 버전 설치
  if asdf list "$plugin" 2>/dev/null | grep -q "$version"; then
    ok "$plugin $version 이미 설치됨"
  else
    info "$plugin $version 설치 중... (시간이 걸릴 수 있습니다)"
    asdf install "$plugin" "$version"
    ok "$plugin $version 설치 완료"
  fi

  # ~/에 버전 설정
  cd "$HOME"
  asdf set --home "$plugin" "$version"
  ok "$plugin $version → ~/.tool-versions 설정 완료"
}

install_asdf_tool "golang" "$GOLANG_VERSION"
install_asdf_tool "nodejs" "$NODEJS_VERSION"
install_asdf_tool "python" "$PYTHON_VERSION"

# ========================================
# 6. 포맷터 / 린터
# ========================================

# shellcheck
if ! command -v shellcheck &>/dev/null; then
  info "shellcheck 설치 중..."
  sudo apt-get install -y -qq shellcheck
  ok "shellcheck 설치 완료"
else
  ok "shellcheck 이미 설치됨"
fi

# shfmt (go install 사용, asdf golang 경유)
if ! command -v shfmt &>/dev/null; then
  info "shfmt 설치 중..."
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
  asdf reshim golang 2>/dev/null || true
  ok "shfmt 설치 완료"
else
  ok "shfmt 이미 설치됨"
fi

# stylua (GitHub release 바이너리)
if ! command -v stylua &>/dev/null; then
  info "stylua 설치 중..."
  STYLUA_VERSION=$(curl -s "https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
  curl -Lo /tmp/stylua.zip "https://github.com/JohnnyMorganz/StyLua/releases/download/${STYLUA_VERSION}/stylua-linux-x86_64.zip"
  unzip -o /tmp/stylua.zip -d /tmp/stylua-bin
  sudo install /tmp/stylua-bin/stylua /usr/local/bin/stylua
  rm -rf /tmp/stylua.zip /tmp/stylua-bin
  ok "stylua 설치 완료"
else
  ok "stylua 이미 설치됨"
fi

# npm 글로벌 패키지 (asdf nodejs shim 경유)
NPM_PACKAGES=(prettier neovim)
for pkg in "${NPM_PACKAGES[@]}"; do
  if npm list -g "$pkg" &>/dev/null 2>&1; then
    ok "npm: $pkg 이미 설치됨"
  else
    info "npm: $pkg 설치 중..."
    npm install -g "$pkg"
    ok "npm: $pkg 설치 완료"
  fi
done
asdf reshim nodejs 2>/dev/null || true

# ========================================
# 7. DevOps 도구
# ========================================

# Terraform
if ! command -v terraform &>/dev/null; then
  info "Terraform 설치 중..."
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -qq
  sudo apt-get install -y -qq terraform
  ok "Terraform 설치 완료"
else
  ok "Terraform 이미 설치됨"
fi

# ansible-lint (asdf python의 pip 사용)
if ! command -v ansible-lint &>/dev/null; then
  info "ansible-lint 설치 중..."
  pip install ansible-lint
  asdf reshim python 2>/dev/null || true
  ok "ansible-lint 설치 완료"
else
  ok "ansible-lint 이미 설치됨"
fi

# Go 개발 도구
GO_TOOLS=(
  "golang.org/x/tools/gopls@latest"
  "mvdan.cc/gofumpt@latest"
  "golang.org/x/tools/cmd/goimports@latest"
  "github.com/go-delve/delve/cmd/dlv@latest"
)

for tool in "${GO_TOOLS[@]}"; do
  tool_name=$(basename "${tool%%@*}")
  if command -v "$tool_name" &>/dev/null; then
    ok "go: $tool_name 이미 설치됨"
  else
    info "go: $tool_name 설치 중..."
    go install "$tool"
    ok "go: $tool_name 설치 완료"
  fi
done
asdf reshim golang 2>/dev/null || true

# ========================================
# 8. tmux TPM
# ========================================
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  info "tmux TPM 설치 중..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM 설치 완료"
else
  ok "TPM 이미 설치됨"
fi

# ========================================
# 9. Nerd Font (JetBrainsMono)
# ========================================
FONT_DIR="$HOME/.local/share/fonts"
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
  info "JetBrainsMono Nerd Font 설치 중..."
  mkdir -p "$FONT_DIR"
  NERD_VERSION=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
  curl -Lo /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VERSION}/JetBrainsMono.zip"
  unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono"
  fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
  rm /tmp/JetBrainsMono.zip
  ok "JetBrainsMono Nerd Font 설치 완료"
  if $IS_WSL; then
    warn "WSL 사용자: Windows Terminal 설정에서 폰트를 'JetBrainsMono Nerd Font'로 변경해주세요"
  fi
else
  ok "JetBrainsMono Nerd Font 이미 설치됨"
fi

# ========================================
# 10. WSL 클립보드 + 한/영 전환 안내
# ========================================
if $IS_WSL; then
  info "WSL 환경 추가 설정 확인..."
  if command -v clip.exe &>/dev/null; then
    ok "clip.exe 사용 가능 (클립보드 연동 가능)"
  else
    warn "clip.exe를 찾을 수 없습니다. Windows System32 PATH를 확인하세요"
  fi
  warn "WSL 한/영 자동 전환을 사용하려면 im-select.exe를 설치하세요:"
  warn "  https://github.com/daipeihust/im-select#windows"
fi

# ========================================
# 11. Neovim 설정 심볼릭 링크
# ========================================
NVIM_CONFIG_DIR="$HOME/.config/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$HOME/.config"

if [ -d "$NVIM_CONFIG_DIR" ] && [ ! -L "$NVIM_CONFIG_DIR" ]; then
  warn "기존 nvim 설정 발견: $NVIM_CONFIG_DIR"
  BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d%H%M%S)"
  info "백업 생성: $BACKUP_DIR"
  mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
  ok "기존 설정 백업 완료"
fi

if [ ! -d "$NVIM_CONFIG_DIR" ] && [ ! -L "$NVIM_CONFIG_DIR" ]; then
  info "설정 디렉토리 심볼릭 링크 생성..."
  ln -s "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"
  ok "심볼릭 링크 생성: $NVIM_CONFIG_DIR -> $SCRIPT_DIR"
elif [ -L "$NVIM_CONFIG_DIR" ]; then
  ok "심볼릭 링크 이미 설정됨"
fi

# ========================================
# 12. local.lua 생성 (없는 경우)
# ========================================
LOCAL_LUA="$SCRIPT_DIR/lua/config/local.lua"
if [ ! -f "$LOCAL_LUA" ]; then
  if $IS_WSL; then
    info "WSL local.lua 템플릿 생성 중..."
    cat > "$LOCAL_LUA" << 'LOCALEOF'
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
    ok "WSL local.lua 생성 완료"
  else
    info "Linux local.lua 템플릿 생성 중..."
    cat > "$LOCAL_LUA" << 'LOCALEOF'
-- Linux 전용 로컬 설정
-- 이 파일은 .gitignore에 포함되어 머신별 고유 설정을 넣는 곳입니다.
LOCALEOF
    ok "Linux local.lua 생성 완료"
  fi
else
  ok "local.lua 이미 존재"
fi

# ========================================
# ~/.local/bin PATH 확인
# ========================================
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  warn "~/.local/bin이 PATH에 없습니다. 추가합니다..."
  if ! grep -q '.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  fi
  if [ -f ~/.zshrc ] && ! grep -q '.local/bin' ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  fi
fi

# ========================================
# 완료
# ========================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  설치 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "asdf 현재 상태:"
asdf current 2>/dev/null || true
echo ""
echo "다음 단계:"
if $IS_WSL; then
  echo "  1. Windows Terminal 폰트를 'JetBrainsMono Nerd Font'로 변경"
  echo "  2. 새 터미널 세션을 열어 PATH 갱신"
else
  echo "  1. 터미널 폰트를 'JetBrainsMono Nerd Font'로 변경"
fi
echo "  3. nvim 실행 → 플러그인 자동 설치 대기"
echo "  4. :checkhealth 로 상태 확인"
echo "  5. :Lazy restore 로 플러그인 버전 동기화"
echo ""
