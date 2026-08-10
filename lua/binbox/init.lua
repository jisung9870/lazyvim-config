local M = {}

function M.setup()
  if M._configured then
    return
  end
  M._configured = true
  vim.api.nvim_create_user_command("BinboxProjects", function()
    require("binbox.projects").pick()
  end, { desc = "Binbox Projects" })
end

return M
