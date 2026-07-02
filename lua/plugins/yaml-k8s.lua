-- ========================================
-- Schema Companion: Kubernetes 스키마 자동 감지
-- ========================================
--
-- 문제:
--   LazyVim extras의 yamlls는 스키마를 수동으로 지정해야 함
--   Deployment, Service, Ingress 등 리소스 타입마다 다른 스키마
--   파일마다 modeline 주석을 넣는 건 비실용적
--
-- 해결:
--   schema-companion이 파일 내용(apiVersion, kind)을 읽어서
--   자동으로 올바른 Kubernetes 스키마를 적용 (CRD 카탈로그 포함)
--   extras.lang.yaml의 yamlls 설정 위에 LazyVim setup 훅으로 병합
--
-- 참고:
--   유지보수가 중단된 yaml-companion.nvim의 활성 포크
--
-- 사용법:
--   1. K8s YAML 파일 열기 → 자동으로 스키마 감지
--   2. <leader>ys → 현재 적용된 스키마 확인/변경
--   3. 상태바에 현재 스키마 표시
--
-- K8s 스키마 버전:
--   기본값은 아래 k8s_schema_version
--   클러스터 버전이 다르면 lua/config/local.lua에서
--   vim.g.k8s_schema_version = "v1.30.0" 처럼 오버라이드

return {
  {
    "cenk1cenk2/schema-companion.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "yaml", "yaml.ansible", "yaml.ghaction" },
    opts = {},
    keys = {
      {
        "<leader>ys",
        function()
          require("schema-companion").select_schema()
        end,
        desc = "YAML: Select schema",
        ft = { "yaml", "yaml.ansible", "yaml.ghaction" },
      },
    },
  },

  -- ==============================
  -- yamlls를 schema-companion 설정과 병합해서 setup
  -- ==============================
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        yamlls = function(_, opts)
          local k8s_schema_version = vim.g.k8s_schema_version or "v1.33.1"
          local sc = require("schema-companion")

          -- extra의 yamlls opts에 커스텀 설정을 얹은 뒤 companion으로 감쌈
          -- (LazyVim은 nvim 0.11+ 네이티브 vim.lsp.config API 사용)
          local merged = vim.tbl_deep_extend("force", opts, {
            filetypes = { "yaml", "yaml.ansible", "yaml.ghaction" },
            settings = {
              yaml = {
                validate = true,
                hover = true,
                completion = true,
                schemaStore = {
                  enable = true, -- SchemaStore에서 자동으로 스키마 가져오기
                  url = "https://www.schemastore.org/api/json/catalog.json",
                },
                schemas = {
                  -- 파일 패턴 기반 스키마 매핑 (자동 감지 실패 시 폴백)
                  ["https://json.schemastore.org/kustomization.json"] = {
                    "kustomization.yaml",
                    "kustomization.yml",
                  },
                  ["https://json.schemastore.org/chart.json"] = {
                    "Chart.yaml",
                    "Chart.yml",
                  },
                  ["https://json.schemastore.org/github-workflow.json"] = {
                    ".github/workflows/*.yml",
                    ".github/workflows/*.yaml",
                  },
                },
              },
            },
          })

          local cfg = sc.setup_client(
            sc.adapters.yamlls.setup({
              sources = {
                -- K8s 내장/CRD 스키마 자동 감지
                sc.sources.matchers.kubernetes.setup({ version = k8s_schema_version }),
                -- yamlls(SchemaStore 등)가 이미 알고 있는 스키마
                sc.sources.lsp.setup(),
                -- 수동 선택용 자주 쓰는 스키마 목록
                sc.sources.schemas.setup({
                  {
                    name = "Kubernetes " .. k8s_schema_version,
                    uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/"
                      .. k8s_schema_version
                      .. "-standalone-strict/all.json",
                  },
                  {
                    name = "Kustomization",
                    uri = "https://json.schemastore.org/kustomization.json",
                  },
                  {
                    name = "Helm Chart.yaml",
                    uri = "https://json.schemastore.org/chart.json",
                  },
                  {
                    name = "Helm values",
                    uri = "https://json.schemastore.org/helmfile.json",
                  },
                  {
                    name = "GitHub Actions Workflow",
                    uri = "https://json.schemastore.org/github-workflow.json",
                  },
                  {
                    name = "GitHub Actions Action",
                    uri = "https://json.schemastore.org/github-action.json",
                  },
                  {
                    name = "Docker Compose",
                    uri = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
                  },
                }),
              },
            }),
            merged
          )

          vim.lsp.config("yamlls", cfg)
          vim.lsp.enable("yamlls")
          return true -- LazyVim 기본 yamlls setup 건너뜀
        end,
      },
    },
  },

  -- ==============================
  -- 상태바에 현재 YAML 스키마 표시
  -- ==============================
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local name = require("schema-companion").get_current_schemas()
          if name and name ~= "" and name ~= "none" then
            return ("📋 " .. name):sub(1, 64)
          end
          return ""
        end,
        cond = function()
          return vim.tbl_contains({ "yaml", "yaml.ansible", "yaml.ghaction" }, vim.bo.filetype)
            and package.loaded["schema-companion"] ~= nil
        end,
        color = { fg = "#89b4fa" },
      })
    end,
  },
}
