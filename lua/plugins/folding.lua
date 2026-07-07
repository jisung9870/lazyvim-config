-- ========================================
-- nvim-ufo: 향상된 코드 폴딩
-- ========================================
--
-- LazyVim 기본은 foldmethod=indent, foldlevel=99 (거의 안 접힘).
-- ufo는 treesitter/indent 기반으로 접기 좋은 범위를 계산하고
-- 접힌 줄 미리보기(peek)를 제공한다.
--
-- 대형 K8s/YAML manifest, Terraform, Go 파일에서 특히 유용.
--
-- 사용법:
--   zR → 모든 fold 열기
--   zM → 모든 fold 닫기
--   za → 커서 위치 fold 토글 (vim 기본)
--   zK → 접힌 내용 미리보기 (닫지 않고 확인)

return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "LazyFile",
    init = function()
      -- LazyVim이 foldlevel=99는 이미 설정 → 나머지 보강
      vim.o.foldcolumn = "1"
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      -- LSP capability 배선 없이 견고하게 동작하는 조합
      -- (LSP provider는 사용하지 않음)
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    },
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
      {
        "zK",
        function()
          local winid = require("ufo").peekFoldedLinesUnderCursor()
          if not winid then
            -- fold가 없으면 일반 hover로 폴백
            vim.lsp.buf.hover()
          end
        end,
        desc = "Peek fold / Hover",
      },
    },
  },
}
