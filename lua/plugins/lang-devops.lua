-- ========================================
-- DevOps 언어 지원 통합
-- extras로 처리되는 것: YAML, JSON, Terraform, Ansible, Go
-- 여기서는 extras가 없는 도구만 직접 설정
-- ========================================

return {
  -- ==============================
  -- 1. Nginx (treesitter 구문 강조)
  -- ==============================
  -- filetype 감지는 autocmds.lua에서 처리
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "nginx",
        "hcl", -- Alloy/Terraform
        "dockerfile",
        "bash",
      })
    end,
  },

  -- ==============================
  -- 2. Grafana Alloy 포맷터
  -- ==============================
  -- .alloy 파일의 filetype 감지 + 유효성 검사는 autocmds.lua에서 처리
  -- 여기서는 conform.nvim에 alloy 포맷터만 등록
  -- alloy CLI가 없는 머신에서는 condition으로 자동 비활성화
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        hcl = { "alloy_space" },
      },
      formatters = {
        alloy_space = {
          command = "sh",
          args = { "-c", "alloy fmt - | expand -t 2" },
          stdin = true,
          condition = function()
            return vim.fn.executable("alloy") == 1
          end,
        },
      },
    },
  },

  -- ==============================
  -- 3. Ansible LSP 오버라이드 (extras 위에 커스텀 설정)
  -- ==============================
  -- extras.lang.ansible이 기본 설정 제공
  -- FQCN 사용, ansible-lint 경로 등 커스텀이 필요하면 아래 수정
  -- 파일 감지 autocmd는 autocmds.lua에서 처리 (경로 + 내용 기반)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ansiblels = {
          filetypes = { "yaml.ansible", "ansible" },
          settings = {
            ansible = {
              ansible = {
                path = "ansible",
                useFullyQualifiedCollectionNames = true,
              },
              executionEnvironment = { enabled = false },
              python = { interpreterPath = "python3" },
              validation = {
                enabled = true,
                lint = {
                  enabled = true,
                  path = "ansible-lint",
                },
              },
            },
          },
        },
      },
    },
  },
}
