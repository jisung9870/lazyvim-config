local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- ==============================
    -- LazyVim Extras (언어 지원)
    -- ==============================
    -- Go: gopls + gofumpt + goimports + gomodifytags + impl + delve 자동 설치
    { import = "lazyvim.plugins.extras.lang.go" },
    -- YAML: yamlls + Kubernetes/Docker Compose 스키마 자동 검증
    { import = "lazyvim.plugins.extras.lang.yaml" },
    -- JSON: jsonls + SchemaStore 연동
    { import = "lazyvim.plugins.extras.lang.json" },
    -- Terraform: terraform-ls + tflint
    { import = "lazyvim.plugins.extras.lang.terraform" },
    -- Ansible: ansiblels + ansible-lint (LazyVim 11.x+)
    { import = "lazyvim.plugins.extras.lang.ansible" },
    -- DAP 코어 (디버거 UI)
    { import = "lazyvim.plugins.extras.dap.core" },

    -- 커스텀 플러그인
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
