-- ========================================
-- Git 고급 통합: Diffview
-- LazyVim 기본 gitsigns에 추가
-- ========================================

return {
  -- ==============================
  -- 0. GitGraph (VSCode Git Graph 스타일 커밋 그래프)
  -- ==============================
  -- :lua require("gitgraph").draw({}, { all = true, max_count = 5000 })
  -- 커밋에서 Enter → 해당 커밋 Diffview
  -- Visual 선택 후 Enter → 선택 범위 Diffview
  {
    "isakbm/gitgraph.nvim",
    dependencies = { "sindrets/diffview.nvim" },
    keys = {
      {
        "<leader>gG",
        function()
          require("gitgraph").draw({}, { all = true, max_count = 5000 })
        end,
        desc = "GitGraph: Commit graph",
      },
    },
    opts = {
      git_cmd = "git",
      symbols = {
        merge_commit = "M",
        commit = "*",
      },
      format = {
        timestamp = "%Y-%m-%d %H:%M",
        fields = { "hash", "timestamp", "author", "branch_name", "tag" },
      },
      hooks = {
        on_select_commit = function(commit)
          vim.cmd("DiffviewOpen " .. commit.hash .. "^!")
        end,
        on_select_range_commit = function(from, to)
          vim.cmd("DiffviewOpen " .. from.hash .. "~1.." .. to.hash)
        end,
      },
    },
  },

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

  -- ==============================
  -- 3. git-conflict (인라인 merge 충돌 해결)
  -- ==============================
  -- diffview merge tool과 별개로, 충돌 마커가 있는 버퍼에서
  -- 직접 ours/theirs/both/none을 고른다.
  -- 기본 매핑(co/ct/cb/c0)은 vim change 연산자(ct=change-till 등)를
  -- 가리므로 끄고, 안전한 커스텀 키를 쓴다.
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "LazyFile", -- 충돌 마커 자동 하이라이트를 위해 파일 열 때 로드
    opts = {
      default_mappings = false,
      disable_diagnostics = false,
    },
    keys = {
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev conflict" },
      { "<leader>gxo", "<cmd>GitConflictChooseOurs<cr>", desc = "Conflict: choose ours" },
      { "<leader>gxt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Conflict: choose theirs" },
      { "<leader>gxb", "<cmd>GitConflictChooseBoth<cr>", desc = "Conflict: choose both" },
      { "<leader>gx0", "<cmd>GitConflictChooseNone<cr>", desc = "Conflict: choose none" },
      { "<leader>gxl", "<cmd>GitConflictListQf<cr>", desc = "Conflict: list in quickfix" },
    },
  },

  -- which-key 그룹 이름
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gx", group = "conflict" },
      },
    },
  },
}
