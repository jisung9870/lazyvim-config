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
      -- ESC는 이 toggleterm 버퍼에서만 terminal mode를 빠져나온다.
      -- gitui, Claude Code, bb tm 팝업 같은 다른 터미널에는 영향 없음
      -- (그쪽에서는 ESC가 앱으로 그대로 전달되어야 함)
      on_open = function(term)
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
          buffer = term.bufnr,
          desc = "Exit terminal mode",
        })
      end,
      float_opts = {
        border = "curved",
        -- 함수로 설정하여 창 크기 변경 시에도 올바른 비율 유지
        width = function()
          return math.floor(vim.o.columns * 0.8)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.8)
        end,
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
      {
        "<leader>tp",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          Terminal:new({
            cmd = "bb tm",
            direction = "float",
            close_on_exit = true,
            hidden = true,
            -- 전역 on_open(ESC 매핑)을 덮어써서 ESC가 내부 fzf로 전달되게 함
            on_open = function() end,
          }):toggle()
        end,
        desc = "Tmux project sessionizer",
      },

      -- 참고: ESC로 terminal mode 종료는 위 on_open에서 버퍼 로컬로 설정
      -- (전역 매핑은 gitui/Claude Code 등 다른 터미널을 방해하므로 제거)
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
