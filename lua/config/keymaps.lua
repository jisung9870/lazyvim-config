-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--

local map = vim.keymap.set

-- ========================================
-- Insert 모드
-- ========================================

map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- ========================================
-- 버퍼 이동 (여러 파일 작업 시 필수)
-- ========================================
-- deployment.yaml → service.yaml → ingress.yaml 사이를 H, L로 이동
-- 참고: LazyVim 기본 <S-h>/<S-l>과 동일 (vim 기본 H/L 화면이동을 덮어씀)

map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- ========================================
-- 들여쓰기 (Visual 모드에서 선택 유지)
-- ========================================
-- 기본 > < 는 들여쓰기 후 선택이 해제됨
-- YAML 블록 들여쓰기를 반복해서 조정할 때 필수

map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- ========================================
-- 검색 결과 화면 중앙 유지
-- ========================================

map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- ========================================
-- 라인 합치기 (커서 위치 유지)
-- ========================================

map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- ========================================
-- 전체 선택
-- ========================================

map("n", "<leader>a", "ggVG", { desc = "Select all" })

-- ========================================
-- 비주얼 모드에서 붙여넣기 시 레지스터 유지
-- ========================================
-- 선택 영역을 교체할 때 원본이 레지스터에서 사라지지 않음

map("v", "p", '"_dP', { desc = "Paste without overwriting register" })

-- ========================================
-- Help 문서 목록
-- ========================================

local help_docs = {
  { label = "Keymap cheatsheet", tag = "lazyvim-cheatsheet" },
  { label = "Maintenance guide", tag = "nvim-maintenance" },
  { label = "Git workflow", tag = "nvim-git-workflow" },
  { label = "DevOps workflow", tag = "nvim-devops-workflow" },
  { label = "Python and Go workflow", tag = "nvim-python-go" },
  { label = "Terminal and tmux workflow", tag = "nvim-terminal-tmux" },
  { label = "Troubleshooting", tag = "nvim-troubleshooting" },
}

local function open_help_docs()
  local doc_dir = vim.fn.stdpath("config") .. "/doc"
  if vim.fn.isdirectory(doc_dir) == 1 then
    vim.cmd("silent! helptags " .. vim.fn.fnameescape(doc_dir))
  end

  vim.ui.select(help_docs, {
    prompt = "Open help document",
    format_item = function(item)
      return item.label .. " (:" .. "help " .. item.tag .. ")"
    end,
  }, function(item)
    if item then
      vim.cmd("help " .. item.tag)
    end
  end)
end

vim.api.nvim_create_user_command("HelpDocs", open_help_docs, {
  desc = "Open local Neovim help document list",
})

map("n", "<leader>h?", open_help_docs, { desc = "Help docs" })

-- 현재 파일을 Typora로 열기 (md 파일일 때만, macOS 전용)
map("n", "<leader>mt", function()
  if vim.fn.has("mac") == 0 then
    vim.notify("Typora keymap is macOS only", vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand("%:p")
  local ft = vim.bo.filetype
  if ft == "markdown" then
    vim.fn.jobstart({ "open", "-a", "Typora", file }, { detach = true })
    vim.notify("Opened in Typora: " .. file, vim.log.levels.INFO)
  else
    vim.notify("Not a markdown file", vim.log.levels.WARN)
  end
end, { desc = "Open in Typora" })

-- 현재 프로젝트에 .venv 생성
map("n", "<leader>cV", function()
  local cwd = vim.fn.getcwd()
  vim.fn.jobstart({ "python", "-m", "venv", cwd .. "/.venv" }, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("venv created at " .. cwd .. "/.venv", vim.log.levels.INFO)
        vim.cmd("VenvSelectCached")
      else
        vim.notify("Failed to create venv", vim.log.levels.ERROR)
      end
    end,
  })
end, { desc = "Create .venv in cwd" })
