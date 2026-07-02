-- ========================================
-- gitlab.nvim: 사내 GitLab MR 리뷰
-- ========================================
--
-- Octo(GitHub)의 GitLab 버전. MR 목록/리뷰/코멘트/승인/머지와
-- 파이프라인 확인을 Neovim 안에서 처리한다.
--
-- 인증 (secrets는 git에 커밋하지 않음):
--   shell rc에 환경변수로 설정한다:
--     export GITLAB_TOKEN="<personal access token, api scope>"
--     export GITLAB_URL="https://<사내 GitLab 호스트>"
--   프로젝트별로 다르면 프로젝트 루트의 .gitlab.nvim 파일 사용
--   (전역 gitignore에 추가 권장)
--
-- 요구사항: Go >= 1.25.1 (백엔드 빌드), curl
--
-- 사용법:
--   <leader>gmm → MR 선택 후 리뷰 시작
--   리뷰 diff 안에서 기본 키맵(g?와 :h gitlab.nvim.keymaps 참고)으로
--   코멘트/스레드 처리

return {
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    build = function()
      require("gitlab.server").build(true)
    end,
    cmd = "Gitlab",
    opts = {},
    keys = {
      {
        "<leader>gmm",
        function()
          require("gitlab").choose_merge_request()
        end,
        desc = "GitLab: Choose MR",
      },
      {
        "<leader>gmr",
        function()
          require("gitlab").review()
        end,
        desc = "GitLab: Review current MR",
      },
      {
        "<leader>gms",
        function()
          require("gitlab").summary()
        end,
        desc = "GitLab: MR summary",
      },
      {
        "<leader>gmp",
        function()
          require("gitlab").pipeline()
        end,
        desc = "GitLab: Pipeline",
      },
      {
        "<leader>gma",
        function()
          require("gitlab").approve()
        end,
        desc = "GitLab: Approve MR",
      },
      {
        "<leader>gmA",
        function()
          require("gitlab").revoke()
        end,
        desc = "GitLab: Revoke approval",
      },
      {
        "<leader>gmc",
        function()
          require("gitlab").create_mr()
        end,
        desc = "GitLab: Create MR",
      },
    },
  },

  -- which-key 그룹 이름
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gm", group = "gitlab" },
      },
    },
  },
}
