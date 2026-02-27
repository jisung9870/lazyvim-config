-- ========================================
-- Git 고급 통합: Diffview
-- LazyVim 기본 gitsigns에 추가
-- ========================================

return {
  -- ==============================
  -- 1. Diffview (Git diff/log 뷰어)
  -- ==============================
  -- :DiffviewOpen      → 현재 변경사항을 diff 뷰로 열기
  -- :DiffviewOpen HEAD~2 → 최근 2커밋과 비교
  -- :DiffviewFileHistory → 현재 파일 Git 히스토리
  -- :DiffviewFileHistory % → 현재 파일만
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: Open" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: Branch history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview: Close" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_horizontal" },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 35 },
      },
    },
  },

  -- ==============================
  -- 2. Gitsigns 커스터마이징 (LazyVim 기본 확장)
  -- ==============================
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false, -- <leader>gb 토글로 사용 권장
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
    },
    keys = {
      { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle git blame" },
      { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview hunk" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset hunk" },
      { "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Reset buffer" },
      { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage hunk" },
      { "<leader>gS", "<cmd>Gitsigns stage_buffer<cr>", desc = "Stage buffer" },
      { "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "Undo stage hunk" },
    },
  },
}
