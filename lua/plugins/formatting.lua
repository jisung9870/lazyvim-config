-- ========================================
-- 파일 타입별 포맷터 지정 (conform.nvim)
-- ========================================
--
-- 문제:
--   기본 설정은 모든 파일에 동일하게 포맷팅 적용
--   하지만 YAML은 포맷터가 구조를 깨뜨릴 수 있고,
--   Markdown은 의도적 공백을 제거할 수 있음
--
-- 해결:
--   파일 타입별로 포맷터를 다르게 설정
--
-- 주의:
--   conform의 format_on_save 옵션은 LazyVim이 무시하고 버림
--   (LazyVim 자체 autoformat이 저장 시 포맷을 담당)
--   파일 타입/크기별 자동 포맷 제외는 autocmds.lua에서
--   vim.b.autoformat으로 제어함
--
-- 참고:
--   HCL (Alloy) 포맷터는 lang-devops.lua에서 설정
--   (alloy CLI 유무에 따른 condition 처리 포함)
--   포맷 timeout은 LazyVim 기본값(default_format_opts.timeout_ms = 3000) 사용
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

      -- 그 외: LSP 포맷터 사용
      ["_"] = { "trim_whitespace" },
    },

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
