-- ========================================
-- 에디터 기능: 한/영 전환 + Telescope 커스터마이징
-- ========================================

return {
  -- ==============================
  -- 1. 한/영 자동 전환 (macism 사용)
  -- ==============================
  -- Normal 모드 진입 시 자동으로 영문(ABC)으로 전환
  -- 설치: brew install macism
  {
    "keaising/im-select.nvim",
    event = "InsertEnter",
    opts = {
      default_im_select = "com.apple.keylayout.ABC",
      default_command = "macism",
    },
  },

  -- ==============================
  -- 2. Telescope 커스터마이징
  -- ==============================
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
          width = 0.87,
          height = 0.80,
        },
        sorting_strategy = "ascending",
        winblend = 0,
        -- DevOps 작업 시 불필요한 파일 제외
        file_ignore_patterns = {
          "%.git/",
          "node_modules/",
          "%.terraform/",
          "%.terragrunt%-cache/",
          "vendor/",
          "__pycache__/",
          "%.pyc",
        },
      },
    },
    keys = {
      -- 플러그인 파일 탐색
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
    },
  },
}
