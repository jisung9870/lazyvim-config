-- ========================================
-- Format on Save 세밀 제어 (conform.nvim)
-- ========================================
--
-- 문제:
--   기본 설정은 모든 파일에 동일하게 포맷팅 적용
--   하지만 YAML은 포맷터가 구조를 깨뜨릴 수 있고,
--   Markdown은 의도적 공백을 제거할 수 있음
--
-- 해결:
--   파일 타입별로 포맷터와 동작 방식을 다르게 설정
--
-- 이미 있는 기능:
--   <Space>cf  → 수동 포맷
--   <Space>uf  → 자동 포맷 전역 토글
--   <Space>uF  → 자동 포맷 버퍼별 토글

return {
  "stevearc/conform.nvim",
  opts = {
    -- ==============================
    -- 파일 타입별 포맷터 지정
    -- ==============================
    formatters_by_ft = {
      -- Go: goimports (import 정리) → gofumpt (엄격 포맷)
      go = { "goimports", "gofumpt" },

      -- Terraform: terraform fmt
      terraform = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },

      -- Shell: shfmt
      sh = { "shfmt" },
      bash = { "shfmt" },

      -- Lua: stylua
      lua = { "stylua" },

      -- JSON: prettier (Kubernetes JSON manifest 등)
      json = { "prettier" },
      jsonc = { "prettier" },

      -- YAML: prettier 사용하되, 주의 필요
      -- 문제가 생기면 아래를 주석 처리하고 수동 포맷(<Space>cf)만 사용
      yaml = { "prettier" },

      -- Markdown: 포맷터 없음 (의도적 공백 보존)
      markdown = {},

      -- HCL (Alloy): 커스텀 포맷터 (alloy.lua에서 이미 설정했다면 중복 주의)
      -- hcl = { "alloy_space" },

      -- 그 외: LSP 포맷터 사용
      ["_"] = { "trim_whitespace" },
    },

    -- ==============================
    -- 저장 시 자동 포맷 설정
    -- ==============================
    format_on_save = function(bufnr)
      -- 포맷 비활성화할 파일 타입
      local disable_filetypes = {
        "markdown",
        "text",
        "gitcommit",
        "gitrebase",
      }

      local filetype = vim.bo[bufnr].filetype
      for _, ft in ipairs(disable_filetypes) do
        if filetype == ft then
          return nil -- 포맷 안 함
        end
      end

      -- 큰 파일은 포맷 건너뛰기 (2000줄 초과)
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      if line_count > 2000 then
        return nil
      end

      return {
        timeout_ms = 3000,
        lsp_format = "fallback", -- conform 포맷터 없으면 LSP 사용
      }
    end,

    -- ==============================
    -- 포맷터별 옵션
    -- ==============================
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2", "-ci" }, -- 들여쓰기 2칸, case indent
      },
      prettier = {
        prepend_args = {
          "--tab-width",
          "2",
          "--no-semi",
          "--single-quote",
        },
      },
    },
  },
}
