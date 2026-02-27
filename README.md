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
cd ~/.config/nvim && git pull && nvim  # :Lazy restore

# WSL
cd ~/.config/nvim && git pull && nvim  # :Lazy restore
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
