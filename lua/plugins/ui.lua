-- ========================================
-- UI 플러그인 통합: 상태바 + 들여쓰기 가이드 + 코드 아웃라인
-- ========================================

return {
  -- ==============================
  -- 1. Lualine (상태바)
  -- ==============================
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local icons = require("lazyvim.config").icons

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        theme = "catppuccin",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha" } },
      })

      opts.sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = {
          { "branch", icon = "" },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
          },
        },
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          {
            "filename",
            path = 1,
            symbols = { modified = "●", readonly = "", unnamed = "" },
          },
        },
        lualine_x = {
          -- DAP 디버그 상태
          {
            function()
              return "  " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
            color = { fg = "#f9e2af" },
          },
          -- lazy.nvim 업데이트 알림
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = { fg = "#f5c2e7" },
          },
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 1 } },
        },
        lualine_z = {
          { "location", padding = { left = 1, right = 1 } },
        },
      }

      return opts
    end,
  },

  -- ==============================
  -- 2. Indent Blankline (들여쓰기 가이드)
  -- ==============================
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      whitespace = {
        remove_blankline_trail = true,
      },
      scope = {
        enabled = true,
        char = "│",
        show_start = true,
        show_end = false,
        show_exact_scope = true,
        injected_languages = true,
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
          "NvimTree",
        },
        buftypes = { "terminal", "nofile" },
      },
    },
    config = function(_, opts)
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IblIndent", { fg = "#313244", nocombine = true })
        vim.api.nvim_set_hl(0, "IblScope", { fg = "#585b70", nocombine = true })
      end)
      require("ibl").setup(opts)
    end,
  },

  -- ==============================
  -- 3. Aerial (코드 심볼 아웃라인)
  -- ==============================
  {
    "stevearc/aerial.nvim",
    opts = {
      layout = {
        min_width = 30,
      },
    },
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
    },
  },
}
