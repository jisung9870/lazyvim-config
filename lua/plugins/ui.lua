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

  -- ==============================
  -- 4. Snacks Explorer
  -- ==============================
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local uv = vim.uv or vim.loop

      local function copy_target(path)
        local dir = vim.fs.dirname(path)
        local name = vim.fn.fnamemodify(path, ":t")
        local is_dir = Snacks.util.path_type(path) == "directory"
        local stem = name
        local suffix = ""

        if not is_dir then
          local ext = vim.fn.fnamemodify(name, ":e")
          if ext ~= "" then
            suffix = "." .. ext
            stem = name:sub(1, #name - #suffix)
          end
        end

        local target = dir .. "/" .. stem .. ".copy" .. suffix
        local index = 2
        while uv.fs_stat(target) do
          target = dir .. "/" .. stem .. ".copy" .. index .. suffix
          index = index + 1
        end
        return target
      end

      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = opts.picker.sources.explorer or {}

      local explorer = opts.picker.sources.explorer
      explorer.actions = explorer.actions or {}
      explorer.actions.explorer_duplicate = function(picker)
        local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
        paths = vim.tbl_filter(function(path)
          return path ~= nil
        end, paths)
        if #paths == 0 then
          return
        end

        local Tree = require("snacks.explorer.tree")
        local Actions = require("snacks.explorer.actions")
        local target
        for _, from in ipairs(paths) do
          local to = copy_target(from)
          Snacks.picker.util.copy_path(from, to)
          Tree:refresh(vim.fs.dirname(from))
          target = to
        end
        picker.list:set_selected()
        Actions.update(picker, { target = target })
        Snacks.notify.info("Duplicated " .. #paths .. " file" .. (#paths > 1 and "s" or ""))
      end

      explorer.win = explorer.win or {}
      explorer.win.list = explorer.win.list or {}
      explorer.win.list.keys = explorer.win.list.keys or {}
      explorer.win.list.keys["C"] = "explorer_duplicate"
      explorer.win.list.keys["M"] = "toggle_maximize"
      explorer.win.list.keys["-"] = "edit_split"
      explorer.win.list.keys["|"] = "edit_vsplit"

      return opts
    end,
  },
}
