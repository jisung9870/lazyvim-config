-- ========================================
-- 에디터 기능: 한/영 전환 + Telescope 커스터마이징
-- ========================================

local function tmux_sessionizer_dirs()
  return require("config.sessionizer").dev_roots()
end

return {
  -- ==============================
  -- 1. 한/영 자동 전환 (macOS 전용, macism 사용)
  -- ==============================
  -- Normal 모드 진입 시 자동으로 영문(ABC)으로 전환
  -- 설치: brew install macism
  -- WSL/Linux에서는 자동으로 비활성화됨
  {
    "keaising/im-select.nvim",
    event = "InsertEnter",
    opts = function()
      if vim.fn.has("mac") == 1 then
        return {
          default_im_select = "com.apple.keylayout.ABC",
          default_command = "macism",
        }
      elseif vim.fn.has("wsl") == 1 then
        return {
          default_im_select = "1033",
          default_command = "im-select.exe",
        }
      else
        return {
          default_im_select = "",
          default_command = "",
        }
      end
    end,
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
        "<leader>fP",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
    },
  },

  -- ==============================
  -- 3. Snacks Project Picker
  -- ==============================
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.projects = opts.picker.sources.projects or {}
      opts.picker.sources.projects.dev = tmux_sessionizer_dirs()

      -- DevOps 작업 시 불필요한 디렉터리를 파일/grep picker에서 제외
      -- (기본 picker가 snacks이므로 telescope file_ignore_patterns 대신 여기서 처리)
      -- fd는 -E, rg는 -g '!<pat>' 로 변환됨
      local devops_exclude = {
        "node_modules",
        ".terraform",
        ".terragrunt-cache",
        "vendor",
        "__pycache__",
        "*.pyc",
      }
      for _, source in ipairs({ "files", "grep" }) do
        opts.picker.sources[source] = opts.picker.sources[source] or {}
        opts.picker.sources[source].exclude = vim.list_extend(opts.picker.sources[source].exclude or {}, devops_exclude)
      end

      return opts
    end,
    keys = {
      {
        "<leader>fp",
        function()
          require("workbench.projects").pick()
        end,
        desc = "Projects",
      },
    },
  },
}
