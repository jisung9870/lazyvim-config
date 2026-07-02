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
│   ├── gitlab.lua      # gitlab.nvim (사내 GitLab MR 리뷰)
│   ├── kubectl.lua     # kubectl.nvim (클러스터 뷰/로그/exec)
│   ├── octo.lua        # Octo 키맵 조정 (extras.util.octo)
│   ├── lang-devops.lua # Nginx, Alloy, Ansible LSP
│   ├── lang-go.lua     # Go 개발 환경 (gopls, neotest, DAP)
│   ├── linting.lua     # nvim-lint DevOps 린터 설정
│   ├── terminal.lua    # ToggleTerm + tmux 연동
│   ├── ui.lua          # Lualine, Indent Blankline, Aerial
│   └── yaml-k8s.lua    # Schema Companion (K8s 스키마 자동 감지)
```

## 멀티 머신 동기화

```bash
# MacBook
cd ~/.config/nvim && ./scripts/setup.sh --sync --sync-plugins

# WSL
cd ~/.config/nvim && ./scripts/setup.sh --type wsl --sync --sync-plugins
```

`--sync`는 dirty worktree에서 중단하고 `git pull --ff-only`만 사용합니다. `--sync-plugins`는 `:Lazy restore`를 headless로 실행합니다.

tmux 설정도 이 repo에서 관리합니다. `~/.tmux.conf`는 `scripts/config/.tmux.conf`로의
symlink라서 pull 후 내용이 바로 반영되며, 실행 중인 서버에는 `prefix r`로 리로드합니다.
자세한 규칙은 `:help nvim-terminal-tmux` 참고.

## 운영 가이드

작업 규칙은 루트 문서와 Neovim help로 나눠 관리합니다.

- `AGENTS.md`: Codex/agent 공통 작업 규칙, 검증, commit 규칙
- `CLAUDE.md`: Claude Code entrypoint (`AGENTS.md` import)
- `:help lazyvim-cheatsheet`: 자주 쓰는 키맵 치트시트
- `:help nvim-maintenance`: help 문서, lockfile, commit, 검증 관리 방식
- `:help nvim-git-workflow`: GitUI/GitGraph/Diffview/Gitsigns 사용 흐름
- `:help nvim-devops-workflow`: YAML, Terraform, Ansible 등 DevOps 작업 흐름
- `:help nvim-python-go`: Python/Go 개발 흐름
- `:help nvim-terminal-tmux`: 터미널/tmux 연동과 tmux 설정 관리
- `:help nvim-troubleshooting`: 문제 해결 순서

문서 목록은 Neovim 안에서 `:HelpDocs` 또는 `<leader>h?`로 열 수 있습니다.

help 문서를 추가하거나 수정한 뒤에는 tag를 갱신합니다.

```bash
nvim --headless "+helptags doc" "+h nvim-maintenance" +qa
```

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

# 설정 symlink, lua/config/local.lua 템플릿, tmux-sessionizer dirs 생성
./scripts/setup.sh --link

# tmux TPM clone/plugin 설치 (설치 후 tmux-plugins.lock 재생성)
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
golang 1.25.11
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

push/PR 시 GitHub Actions `Checks` 워크플로가 동일 검증을 실행합니다:
shell lint(shellcheck/shfmt), `stylua --check lua/`, help tag 빌드와 `doc/tags` 최신 여부,
`./scripts/test-setup.sh`.

## Extras (lazyvim.json)

`:LazyExtras`로 관리. 주요 활성화 항목:
- `lang.go`, `lang.yaml`, `lang.json`, `lang.terraform`, `lang.ansible`
- `dap.core`, `coding.mini-comment`, `coding.mini-surround`
- `ai.copilot`, `util.octo` (GitHub PR 리뷰, gh CLI 필요)

## 필요 도구

| 도구 | macOS | WSL/Linux | 용도 |
|------|-------|-----------|------|
| macism | `brew install macism` | 불필요 | 한/영 전환 |
| gh | `brew install gh` | `apt install gh` | Octo GitHub PR/issue |
| kubectl | 환경별 설치 | 동일 | kubectl.nvim 클러스터 뷰 |
| GITLAB_TOKEN/URL | shell rc에 export | 동일 | gitlab.nvim MR 리뷰 (secrets 커밋 금지) |
| alloy | Grafana 공식 설치 | 동일 | Alloy 포맷/검증 |
| go | `asdf install golang` | 동일 | Go 개발 |
| ansible-lint | `pip install ansible-lint` | 동일 | Ansible 린트 |
| yamllint | Mason 또는 `pip install yamllint` | 동일 | YAML 린트 |
| actionlint | Mason 또는 `brew install actionlint` | GitHub release | GitHub Actions 린트 |
| tflint | Mason 또는 `brew install tflint` | GitHub release | Terraform 린트 |
| hadolint | Mason 또는 `brew install hadolint` | GitHub release | Dockerfile 린트 |
| prettier | `npm i -g prettier` | 동일 | YAML/JSON 포맷 |
| shfmt | `brew install shfmt` | `apt install shfmt` | Shell 포맷 |
| stylua | `brew install stylua` | cargo/GitHub release | Lua 포맷 |
