return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp", -- ★ 최신 버전 (regexp 브랜치 권장)
    dependencies = {
      "neovim/nvim-lspconfig",
      { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    -- ft 제거! 대신 키나 명령어로 lazy-load
    cmd = "VenvSelect",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
          cached_venv_automatic_activation = true,
          activate_venv_in_terminal = true,
          set_environment_variables = true,
          -- ★ venv 선택 시 열려있는 터미널에도 activate 전송
          on_venv_activate_callback = function()
            local venv = vim.env.VIRTUAL_ENV
            if not venv or venv == "" then
              return
            end
            local activate = venv .. "/bin/activate"
            if vim.fn.filereadable(activate) ~= 1 then
              return
            end

            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
                local chan = vim.b[buf].terminal_job_id
                if chan then
                  vim.api.nvim_chan_send(chan, "source " .. activate .. "\r")
                end
              end
            end
          end,
        },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },
}
