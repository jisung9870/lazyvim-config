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
--
-- 사용법:
--   1. K8s YAML 파일 열기 → 자동으로 스키마 감지
--   2. <leader>ys → 현재 적용된 스키마 확인/변경
--   3. 상태바에 현재 스키마 표시

return {
  {
    "someone-stole-my-name/yaml-companion.nvim",
    ft = { "yaml", "yaml.ansible", "yaml.ghaction" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
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
            name = "Kubernetes",
            uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0-standalone-strict/all.json",
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
        -- yamlls 설정 (extras.lang.yaml과 병합됨)
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

      -- yamlls에 yaml-companion 설정 적용
      require("lspconfig")["yamlls"].setup(cfg)

      -- Telescope로 스키마 선택
      require("telescope").load_extension("yaml_schema")
    end,
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
