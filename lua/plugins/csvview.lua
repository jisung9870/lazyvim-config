return {
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = {
      parser = {
        --- 주석 줄로 처리할 prefix (선택)
        comments = { "#", "//" },
      },
      view = {
        --- "highlight" | "border" | "shrink"
        display_mode = "border",
        --- 첫 줄을 헤더로 표시
        header_lnum = 1,
        --- 구분자도 표시 (false면 더 표 같아 보임)
        sticky_header = {
          enabled = true,
          separator = "─",
        },
      },
      keymaps = {
        -- 다음/이전 필드(컬럼)로 이동
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_field_start = { "L", mode = { "n", "v" } },
        jump_prev_field_start = { "H", mode = { "n", "v" } },

        -- 다음/이전 행(같은 컬럼 유지)으로 이동
        jump_next_row = { "J", mode = { "n", "v" } },
        jump_prev_row = { "K", mode = { "n", "v" } },

        -- 필드를 텍스트 객체로 선택
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
      },
    },
    keys = {
      { "<leader>tc", "<cmd>CsvViewToggle<cr>", desc = "Toggle CSV View" },
    },
  },
}
