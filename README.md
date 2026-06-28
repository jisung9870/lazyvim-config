# LazyVim Config

DevOps 엔지니어를 위한 LazyVim 설정. MacBook (macOS)과 Windows (WSL) 공용.

## 구조

```
lua/
├── config/
│   ├── lazy.lua        # lazy.nvim 부트스트랩
│   ├── options.lua     # 에디터 옵션 + local.lua 로드
│   ├── keymaps.lua     # 커스텀 키맵
│   ├── autocmds.lua    # 파일 타입 감지 (Alloy, Nginx, Ansible)
│   └── local.lua       # 머신별 설정 (git 미추적)
├── plugins/
│   ├── colorscheme.lua # Catppuccin Mocha
│   ├── editor.lua      # 한/영 전환 (macOS), Telescope
│   ├── formatting.lua  # conform.nvim 포맷터 설정
│   ├── git.lua         # Diffview + Gitsigns
│   ├── lang-devops.lua # Nginx, Alloy, Ansible LSP
│   ├── lang-go.lua     # Go 개발 환경 (gopls, neotest, DAP)
│   ├── terminal.lua    # ToggleTerm + tmux 연동
│   ├── ui.lua          # Lualine, Indent Blankline, Aerial
│   └── yaml-k8s.lua    # YAML Companion (K8s 스키마 자동 감지)
```

## 멀티 머신 동기화

```bash
# MacBook
cd ~/.config/nvim && ./scripts/setup.sh --sync --sync-plugins

# WSL
cd ~/.config/nvim && ./scripts/setup.sh --type wsl --sync --sync-plugins
```

`--sync`는 dirty worktree에서 중단하고 `git pull --ff-only`만 사용합니다. `--sync-plugins`는 `:Lazy restore`를 headless로 실행합니다.

### 머신별 로컬 설정

`lua/config/local.lua`는 `.gitignore`에 추가되어 각 머신 고유 설정 가능:

```lua
-- macOS 예시: local.lua
vim.opt.guifont = "JetBrainsMono Nerd Font:h14"

-- WSL 예시: local.lua
vim.g.clipboard = {
  name = "WslClipboard",
  copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
  paste = {
    ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
}
```

## 초기 설정

기본 실행은 점검만 수행합니다. 실제 설치, symlink 생성, 폰트 설치, TPM 플러그인 설치는 플래그를 명시해야 합니다.

```bash
# 자동 감지: macOS는 macOS 스크립트, WSL은 WSL 스크립트로 위임
./scripts/setup.sh

# 자동 감지가 어려운 환경에서는 명시
./scripts/setup.sh --type macos
./scripts/setup.sh --type wsl

# 변경 전 실행 예정 작업 확인
./scripts/setup.sh --install --link --with-font --with-im --with-tmux-plugins --dry-run

# 설치까지 수행
./scripts/setup.sh --install

# 설정 symlink와 lua/config/local.lua 템플릿 생성
./scripts/setup.sh --link

# tmux TPM clone/plugin 설치는 명시 플래그 필요
./scripts/setup.sh --install --with-tmux-plugins

# repo와 Lazy plugin lockfile 동기화
./scripts/setup.sh --sync --sync-plugins

# 기존 TPM이 있을 때 tmux plugin도 동기화
./scripts/setup.sh --sync-plugins --with-tmux-plugins

# 전체 bootstrap 예시
./scripts/setup.sh --install --link --with-font --with-im --with-tmux-plugins --yes

# 고급 사용: 플랫폼별 스크립트를 직접 실행할 수도 있음
./scripts/setup-macos.sh --install --dry-run
./scripts/setup-wsl.sh --install --dry-run
```

기존 `~/.config/nvim` 또는 `~/.tmux.conf`가 일반 파일/디렉터리이면 `--link --yes`일 때만 백업 후 교체합니다.

### asdf와 버전

Go/Node.js/Python은 asdf로 관리하며, repo 루트의 `.tool-versions`를 기준으로 설치합니다.

```bash
golang 1.23.5
nodejs 24.15.0
python 3.13.1
```

setup 스크립트는 asdf 자체를 자동 설치하지 않습니다.

- macOS: `brew install asdf` 후 shell rc에 asdf 초기화를 추가하고 새 터미널에서 실행
- WSL/Linux: asdf 공식 가이드에 따라 설치 후 shell rc를 갱신하고 새 터미널에서 실행

Neovim AppImage 버전은 `scripts/lib/setup-versions.sh`의 `NVIM_VERSION`에서 관리합니다.

### 검증

```bash
./scripts/test-setup.sh
```

`scripts/test-setup.sh`는 bash 문법, ShellCheck, shfmt, help 출력, dry-run, symlink helper 단위 테스트, `nvim --headless '+qa'`를 확인합니다. 로컬에 `shellcheck`, `shfmt`, `nvim`이 없으면 해당 항목은 경고 후 건너뜁니다.

## Extras (lazyvim.json)

`:LazyExtras`로 관리. 주요 활성화 항목:
- `lang.go`, `lang.yaml`, `lang.json`, `lang.terraform`, `lang.ansible`
- `dap.core`, `coding.mini-comment`, `coding.mini-surround`
- `ai.copilot`

## 필요 도구

| 도구 | macOS | WSL/Linux | 용도 |
|------|-------|-----------|------|
| macism | `brew install macism` | 불필요 | 한/영 전환 |
| alloy | Grafana 공식 설치 | 동일 | Alloy 포맷/검증 |
| go | `asdf install golang` | 동일 | Go 개발 |
| ansible-lint | `pip install ansible-lint` | 동일 | Ansible 린트 |
| prettier | `npm i -g prettier` | 동일 | YAML/JSON 포맷 |
| shfmt | `brew install shfmt` | `apt install shfmt` | Shell 포맷 |
| stylua | `brew install stylua` | cargo/GitHub release | Lua 포맷 |
