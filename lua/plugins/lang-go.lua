-- ========================================
-- Go 개발 환경 (extras.lang.go 위에 커스텀 오버라이드)
-- 기본 도구는 lazy.lua의 extras.lang.go가 자동 설치:
--   gopls, gofumpt, goimports, gomodifytags, impl, delve
-- ========================================

return {
  -- ==============================
  -- 1. gopls 상세 설정 오버라이드
  -- ==============================
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules", "-.trash" },

              -- 코드 렌즈
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },

              -- 인레이 힌트
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },

              -- 정적 분석
              analyses = {
                fieldalignment = true,
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
            },
          },
        },
      },
    },
  },

  -- ==============================
  -- 2. Neotest 커스터마이징
  -- ==============================
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          args = { "-v" },
          recursive_run = true,
          experimental = {
            test_table = true,
          },
        },
      },
    },
  },

  -- ==============================
  -- 3. DAP (delve) — extras가 기본 설정 제공
  -- 커스텀 설정이 필요할 때만 아래 opts 수정
  -- ==============================
  {
    "leoluz/nvim-dap-go",
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        swap = {
          enable = true,
          swap_next = {
            ["<leader>cx"] = { query = "@parameter.inner", desc = "Swap with next parameter" },
          },
          swap_previous = {
            ["<leader>cX"] = { query = "@parameter.inner", desc = "Swap with prev parameter" },
          },
        },
      },
    },
  },
}
