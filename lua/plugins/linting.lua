-- ========================================
-- DevOps linting (nvim-lint)
-- ========================================

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}

      opts.linters_by_ft.yaml = vim.list_extend(opts.linters_by_ft.yaml or {}, { "yamllint" })
      opts.linters_by_ft["yaml.ansible"] = vim.list_extend(opts.linters_by_ft["yaml.ansible"] or {}, { "yamllint" })
      opts.linters_by_ft["yaml.ghaction"] = vim.list_extend(opts.linters_by_ft["yaml.ghaction"] or {}, { "actionlint" })
      opts.linters_by_ft.terraform = vim.list_extend(opts.linters_by_ft.terraform or {}, { "tflint" })
      opts.linters_by_ft.tf = vim.list_extend(opts.linters_by_ft.tf or {}, { "tflint" })
      opts.linters_by_ft["terraform-vars"] = vim.list_extend(opts.linters_by_ft["terraform-vars"] or {}, { "tflint" })
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "yamllint",
        "actionlint",
        "tflint",
        "hadolint",
      })
    end,
  },
}
