-- ========================================
-- YAML Companion: Kubernetes 스키마 자동 감지
-- ========================================
--
-- 문제:
--   LazyVim extras의 yamlls는 스키마를 수동으로 지정해야 함
--   Deployment, Service, Ingress 등 리소스 타입마다 다른 스키마
--   파일마다 modeline 주석을 넣는 건 비실용적
--
-- 해결:
--   yaml-companion이 파일 내용(apiVersion, kind)을 읽어서
--   자동으로 올바른 Kubernetes 스키마를 적용
--   extras.lang.yaml의 yamlls 설정 위에 LazyVim setup 훅으로 병합
--   (직접 lspconfig.setup()을 호출하면 extra 설정과 이중 setup됨)
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
    "someone-stole-my-name/yaml-companion.nvim",
    ft = { "yaml", "yaml.ansible", "yaml.ghaction" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      {
        "<leader>ys",
        function()
          require("telescope").extensions.yaml_schema.yaml_schema()
        end,
        desc = "YAML: Select schema",
        ft = { "yaml", "yaml.ansible", "yaml.ghaction" },
      },
    },
  },

  -- ==============================
  -- yamlls를 yaml-companion 설정과 병합해서 setup
  -- ==============================
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        yamlls = function(_, opts)
          local k8s_schema_version = vim.g.k8s_schema_version or "v1.33.1"

          local cfg = require("yaml-companion").setup({
            -- ==============================
            -- 내장 스키마 매칭 (파일 내용 기반 자동 감지)
            -- ==============================
            builtin_matchers = {
              kubernetes = { enabled = true },
              cloud_init = { enabled = true },
            },

            -- ==============================
            -- 자주 쓰는 스키마 목록 (수동 선택용)
            -- ==============================
            schemas = {
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
            },

            -- ==============================
            -- yamlls 설정 (extras.lang.yaml 설정 위에 병합됨)
            -- ==============================
            lspconfig = {
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
            },
          })

          -- extra의 yamlls opts 위에 yaml-companion 설정을 덮어씀
          -- (LazyVim은 nvim 0.11+ 네이티브 vim.lsp.config API 사용)
          local merged = vim.tbl_deep_extend("force", opts, cfg)

          -- yaml-companion이 nvim 0.11에서 제거된
          -- client.workspace_did_change_configuration을 호출하므로 폴리필
          local companion_on_attach = merged.on_attach
          merged.on_attach = function(client, bufnr)
            if not client.workspace_did_change_configuration then
              client.workspace_did_change_configuration = function(settings)
                return client:notify("workspace/didChangeConfiguration", { settings = settings })
              end
            end
            if companion_on_attach then
              companion_on_attach(client, bufnr)
            end
          end

          vim.lsp.config("yamlls", merged)
          vim.lsp.enable("yamlls")
          require("telescope").load_extension("yaml_schema")
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
          local schema = require("yaml-companion").get_buf_schema(0)
          if schema and schema.result and schema.result[1] then
            local name = schema.result[1].name
            if name ~= "none" then
              return "📋 " .. name
            end
          end
          return ""
        end,
        cond = function()
          return vim.tbl_contains({ "yaml", "yaml.ansible", "yaml.ghaction" }, vim.bo.filetype)
            and package.loaded["yaml-companion"]
        end,
        color = { fg = "#89b4fa" },
      })
    end,
  },
}
