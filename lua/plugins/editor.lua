-- ========================================
-- 에디터 기능: 한/영 전환 + Telescope 커스터마이징
-- ========================================

local function tmux_sessionizer_dirs()
  local config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
  local config_file = config_home .. "/tmux-sessionizer/dirs"
  local dirs = {}
  if vim.fn.filereadable(config_file) == 1 then
    for _, line in ipairs(vim.fn.readfile(config_file)) do
      line = vim.trim(line)
      if line ~= "" and not line:match("^#") then
        line = vim.fn.expand(line)
        if vim.fn.isdirectory(line) == 1 then
          table.insert(dirs, vim.fs.normalize(line))
        end
      end
    end
  end

  -- dirs 파일이 없으면 관례적 위치로 폴백 (존재하는 디렉토리만)
  if #dirs == 0 then
    for _, fallback in ipairs({ "~/home/projects", "~/home/work" }) do
      fallback = vim.fn.expand(fallback)
      if vim.fn.isdirectory(fallback) == 1 then
        table.insert(dirs, vim.fs.normalize(fallback))
      end
    end
  end

  return dirs
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
      return opts
    end,
    keys = {
      {
        "<leader>fp",
        function()
          Snacks.picker.projects({ dev = tmux_sessionizer_dirs() })
        end,
        desc = "Projects",
      },
    },
  },
}
