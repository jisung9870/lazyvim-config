-- ========================================
-- Octo 키맵 조정 (extras.util.octo 위에 오버라이드)
-- ========================================
--
-- extra 기본 키맵(<leader>gi/gI/gp/gP/gr/gS)이 이 repo의 gitsigns
-- 커스텀 키(<leader>gp preview hunk, gr reset hunk, gS stage buffer)와
-- 충돌하므로 Octo 키를 <leader>go 그룹으로 옮긴다.
--
-- 사용법:
--   <leader>gop → PR 목록 (리뷰할 PR 선택)
--   PR 버퍼 안에서는 <localleader> 그룹으로 코멘트/리뷰/머지
--   요구사항: gh CLI 설치 + `gh auth login`

return {
  {
    "pwntester/octo.nvim",
    keys = {
      -- extra 기본 키 비활성화 (gitsigns 키맵과 충돌)
      { "<leader>gi", false },
      { "<leader>gI", false },
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gS", false },
      -- <leader>go 그룹으로 재배치
      { "<leader>gop", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
      { "<leader>goP", "<cmd>Octo pr search<CR>", desc = "Search PRs (Octo)" },
      { "<leader>goi", "<cmd>Octo issue list<CR>", desc = "List Issues (Octo)" },
      { "<leader>goI", "<cmd>Octo issue search<CR>", desc = "Search Issues (Octo)" },
      { "<leader>gor", "<cmd>Octo repo list<CR>", desc = "List Repos (Octo)" },
      { "<leader>gos", "<cmd>Octo search<CR>", desc = "Search (Octo)" },
    },
  },

  -- which-key 그룹 이름
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>go", group = "octo" },
      },
    },
  },
}
