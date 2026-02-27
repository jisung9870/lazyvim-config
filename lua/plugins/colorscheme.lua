-- ========================================
-- Catppuccin Mocha 테마 + 모든 하이라이트 통합
-- (기존 autocmds.lua의 enhance_highlights 통합)
-- ========================================

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = { "bold" },
        keywords = { "italic" },
        strings = {},
        variables = {},
        numbers = {},
        booleans = { "bold" },
        properties = {},
        types = { "bold" },
        operators = {},
      },
      color_overrides = {
        mocha = {
          base = "#1e1e2e",
          mantle = "#181825",
          crust = "#11111b",
        },
      },
      custom_highlights = function(colors)
        return {
          -- 주석 (야간 작업 최적화)
          Comment = { fg = "#9399b2", style = { "italic" } },

          -- 라인 번호
          LineNr = { fg = "#6c7086" },
          CursorLineNr = { fg = "#f5c2e7", style = { "bold" } },

          -- 커서라인
          CursorLine = { bg = "#2a2b3c" },

          -- 검색
          Search = { bg = "#585b70", fg = "#cdd6f4", style = { "bold" } },
          IncSearch = { bg = "#f5c2e7", fg = "#1e1e2e", style = { "bold" } },

          -- 선택 영역
          Visual = { bg = "#45475a", style = { "bold" } },

          -- 분할선 및 테두리
          VertSplit = { fg = "#45475a" },
          FloatBorder = { fg = "#89b4fa", bg = "#1e1e2e" },
          NormalFloat = { bg = "#1e1e2e" },

          -- 상태바
          StatusLine = { bg = "#181825", fg = "#cdd6f4" },

          -- TODO/FIXME 키워드
          Todo = { fg = "#f9e2af", bg = "NONE", style = { "bold", "italic" } },

          -- Git 사인
          GitSignsAdd = { fg = "#a6e3a1" },
          GitSignsChange = { fg = "#f9e2af" },
          GitSignsDelete = { fg = "#f38ba8" },

          -- 진단 메시지
          DiagnosticError = { fg = "#f38ba8" },
          DiagnosticWarn = { fg = "#fab387" },
          DiagnosticInfo = { fg = "#89dceb" },
          DiagnosticHint = { fg = "#94e2d5" },

          -- LSP 참조 강조
          LspReferenceText = { bg = "#313244" },
          LspReferenceRead = { bg = "#313244" },
          LspReferenceWrite = { bg = "#313244" },

          -- Telescope
          TelescopeBorder = { fg = "#89b4fa" },
          TelescopePromptBorder = { fg = "#f5c2e7" },

          -- 들여쓰기 가이드
          IndentBlanklineChar = { fg = "#313244" },
          IndentBlanklineContextChar = { fg = "#585b70" },

          -- DevOps 파일 타입별 강조
          yamlBlockMappingKey = { fg = "#89b4fa", style = { "bold" } },
          terraformBlock = { fg = "#cba6f7" },
          goFunctionCall = { fg = "#89b4fa" },
        }
      end,
      integrations = {
        aerial = true,
        cmp = true,
        dap = true,
        dap_ui = true,
        diffview = true,
        flash = true,
        gitsigns = true,
        indent_blankline = { enabled = true, scope_color = "lavender" },
        mason = true,
        markdown = true,
        mini = { enabled = true, indentscope_color = "" },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        neotest = true,
        noice = true,
        notify = true,
        nvimtree = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
      },
    },
  },

  -- LazyVim 기본 컬러스킴 지정
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
