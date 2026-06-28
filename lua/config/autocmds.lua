-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- ========================================
-- Grafana Alloy 파일 지원
-- ========================================

-- .alloy → hcl filetype + 들여쓰기 2칸
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.alloy",
  callback = function()
    vim.bo.filetype = "hcl"
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- 저장 시 alloy validate 실행 (alloy CLI가 설치된 경우에만)
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.alloy",
  callback = function()
    if vim.fn.executable("alloy") ~= 1 then
      return
    end
    local file = vim.fn.expand("%:p")
    local result = vim.fn.system("alloy validate " .. vim.fn.shellescape(file))
    if vim.v.shell_error ~= 0 then
      vim.notify("Alloy validation failed:\n" .. result, vim.log.levels.ERROR)
    end
  end,
})

-- ========================================
-- Nginx 파일 감지
-- ========================================

vim.filetype.add({
  pattern = {
    [".*nginx.*%.conf"] = "nginx",
    [".*/nginx/.*"] = "nginx",
    [".*/conf.d/.*"] = "nginx",
  },
})

-- ========================================
-- Ansible 파일 자동 감지
-- ========================================

-- 경로 기반 감지
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*/playbooks/*.yml",
    "*/playbooks/*.yaml",
    "*/roles/*/tasks/*.yml",
    "*/roles/*/handlers/*.yml",
    "*/group_vars/*",
    "*/host_vars/*",
  },
  callback = function()
    vim.bo.filetype = "yaml.ansible"
  end,
})

-- 파일 내용 기반 감지
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.yml", "*.yaml" },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
    local content = table.concat(lines, "\n")
    if content:match("hosts:") or content:match("tasks:") or content:match("ansible_") or content:match("become:") then
      vim.bo.filetype = "yaml.ansible"
    end
  end,
})

-- ========================================
-- Cursorline 자동 토글 (Insert 모드에서 비활성화)
-- ========================================

local cursorline_group = vim.api.nvim_create_augroup("CursorLineControl", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
  group = cursorline_group,
  callback = function()
    vim.opt.cursorline = false
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = cursorline_group,
  callback = function()
    vim.opt.cursorline = true
  end,
})

-- 커서가 멈추면 자동으로 diagnostic float 띄우기
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = "always", -- 어떤 LSP에서 온 메시지인지 표시
      scope = "cursor", -- 커서 위치의 진단만
    })
  end,
})
