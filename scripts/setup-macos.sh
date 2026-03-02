#!/bin/bash
# ========================================
# LazyVim DevOps 환경 설정 - macOS
# ========================================
# 사용법: chmod +x scripts/setup-macos.sh && ./scripts/setup-macos.sh
#
# 도구 버전 관리: asdf 0.18.0+ (asdf set --home 사용)
# 런타임 (Go, Node.js, Python): asdf로 설치/관리
# CLI 도구 (shfmt, stylua 등): Homebrew로 설치

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

# ========================================
# asdf로 설치할 런타임 버전 (필요 시 수정)
# ========================================
GOLANG_VERSION="1.23.5"
NODEJS_VERSION="22.13.1"
PYTHON_VERSION="3.13.1"

# ========================================
# 1. Homebrew
# ========================================
if ! command -v brew &>/dev/null; then
  info "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
  ok "Homebrew 설치 완료"
else
  ok "Homebrew 이미 설치됨"
fi

# ========================================
# 2. asdf 확인
# ========================================
if ! command -v asdf &>/dev/null; then
  error "asdf가 설치되어 있지 않습니다. https://asdf-vm.com/guide/getting-started.html 참고하여 먼저 설치해주세요."
fi
ok "asdf 확인됨"

# ========================================
# 3. Neovim + 핵심 의존성 (Homebrew)
# ========================================
info "Neovim 및 핵심 도구 설치 중..."

BREW_PACKAGES=(
  neovim
  ripgrep         # Telescope 검색
  fd              # Telescope 파일 찾기
  lazygit         # Git TUI
  tmux            # 터미널 멀티플렉서
  fzf             # 퍼지 파인더
  tree-sitter     # 구문 분석
  wget
  curl
)

for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg 이미 설치됨"
  else
    info "$pkg 설치 중..."
    brew install "$pkg"
    ok "$pkg 설치 완료"
  fi
done

# ========================================
# 4. 한/영 전환 (macism)
# ========================================
if ! command -v macism &>/dev/null; then
  info "macism 설치 중 (한/영 자동 전환)..."
  brew install macism
  ok "macism 설치 완료"
else
  ok "macism 이미 설치됨"
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
# 6. 포맷터 / 린터 (Homebrew)
# ========================================
info "포맷터 및 린터 설치 중..."

FORMATTER_PACKAGES=(
  shfmt           # Shell 포맷터
  stylua          # Lua 포맷터
  shellcheck      # Shell 린터
)

for pkg in "${FORMATTER_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg 이미 설치됨"
  else
    info "$pkg 설치 중..."
    brew install "$pkg"
    ok "$pkg 설치 완료"
  fi
done

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
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
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
# 8. tmux + TPM
# ========================================
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  info "tmux TPM 설치 중..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM 설치 완료 (tmux 시작 후 prefix + I 로 플러그인 설치)"
else
  ok "TPM 이미 설치됨"
fi

# ========================================
# 9. Nerd Font (JetBrainsMono)
# ========================================
if ! system_profiler SPFontsDataType 2>/dev/null | grep -qi "JetBrainsMono"; then
  info "JetBrainsMono Nerd Font 설치 중..."
  brew install --cask font-jetbrains-mono-nerd-font
  ok "JetBrainsMono Nerd Font 설치 완료"
  warn "터미널 앱에서 폰트를 'JetBrainsMono Nerd Font'로 변경해주세요"
else
  ok "JetBrainsMono Nerd Font 이미 설치됨"
fi

# ========================================
# 10. Neovim 설정 심볼릭 링크
# ========================================
NVIM_CONFIG_DIR="$HOME/.config/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  CURRENT_TARGET=$(readlink "$NVIM_CONFIG_DIR")
  if [ "$CURRENT_TARGET" = "$SCRIPT_DIR" ]; then
    ok "심볼릭 링크 이미 올바르게 설정됨"
  else
    warn "심볼릭 링크가 다른 경로를 가리킴: $CURRENT_TARGET"
    warn "수동으로 확인 후 변경하세요: ln -sf $SCRIPT_DIR $NVIM_CONFIG_DIR"
  fi
fi

# ========================================
# 11. macOS local.lua 생성 (없는 경우)
# ========================================
LOCAL_LUA="$SCRIPT_DIR/lua/config/local.lua"
if [ ! -f "$LOCAL_LUA" ]; then
  info "macOS local.lua 템플릿 생성 중..."
  cat > "$LOCAL_LUA" << 'LOCALEOF'
-- macOS 전용 로컬 설정
-- 이 파일은 .gitignore에 포함되어 머신별 고유 설정을 넣는 곳입니다.

-- 폰트 설정 (GUI Neovim 사용 시)
-- vim.opt.guifont = "JetBrainsMono Nerd Font:h14"
LOCALEOF
  ok "macOS local.lua 생성 완료"
else
  ok "local.lua 이미 존재"
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
echo "  1. 터미널 폰트를 'JetBrainsMono Nerd Font'로 변경"
echo "  2. nvim 실행 → 플러그인 자동 설치 대기"
echo "  3. :checkhealth 로 상태 확인"
echo "  4. :Lazy restore 로 플러그인 버전 동기화"
echo ""
