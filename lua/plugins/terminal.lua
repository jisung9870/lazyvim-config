-- ========================================
-- 터미널 통합: ToggleTerm + tmux 연동
-- 키 충돌 해결: Ctrl+h/j/k/l은 tmux-navigator가 전담
-- ========================================

return {
  -- ==============================
  -- 1. ToggleTerm (터미널 관리)
  -- ==============================
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<C-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        winblend = 0,
      },
    },
    keys = {
      -- 기본 토글
      { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle floating terminal" },

      -- 방향별 터미널
      { "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", desc = "Horizontal terminal" },
      { "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", desc = "Vertical terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },

      -- 터미널 모드에서 ESC로 나가기
      { "<Esc>", [[<C-\><C-n>]], mode = "t", desc = "Exit terminal mode" },

      -- 참고: Ctrl+h/j/k/l 창 이동은 tmux-navigator가 처리
      -- toggleterm에서 별도 매핑 불필요 (충돌 방지)
    },
  },

  -- ==============================
  -- 2. tmux 연동 (Neovim ↔ tmux 패널 이동)
  -- ==============================
  -- Ctrl+h/j/k/l로 Neovim 창과 tmux 패널을 자유롭게 이동
  -- 터미널 모드에서도 동작
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window/pane" },
    },
  },
}
