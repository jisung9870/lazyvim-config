-- ========================================
-- Go 개발 환경 (extras.lang.go 위에 커스텀 오버라이드)
-- 기본 도구는 lazy.lua의 extras.lang.go가 자동 설치:
--   gopls, gofumpt, goimports, gomodifytags, impl, delve
-- ========================================
--
-- 참고: gopls의 gofumpt/staticcheck/codelenses/hints/analyses와
-- inlay_hints, neotest(neotest-golang), nvim-dap-go는 모두
-- extras.lang.go가 이미 기본 제공하므로 여기서 재정의하지 않는다.
-- (제거된 fieldalignment analyzer 등 중복/무효 설정 정리)

return {
  -- ==============================
  -- 1. gopls: repo 고유 디렉터리 필터만 오버라이드
  -- ==============================
  -- extra 기본 directoryFilters에 .trash를 추가 (그 외는 extra 기본값 유지)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              directoryFilters = {
                "-.git",
                "-.vscode",
                "-.vscode-test",
                "-.idea",
                "-node_modules",
                "-.trash",
              },
            },
          },
        },
      },
    },
  },

  -- ==============================
  -- 2. parameter swap 텍스트 객체
  -- ==============================
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
