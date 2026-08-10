local M = {}

function M.setup()
  if M._configured then
    return
  end
  M._configured = true
  for name, module in pairs({
    BinboxProjects = "projects",
    WorkbenchProjects = "projects",
    WorkbenchAgents = "agents",
    WorkbenchWorktrees = "worktrees",
    WorkbenchDoctor = "doctor",
  }) do
    local module_name = module
    vim.api.nvim_create_user_command(name, function()
      require("workbench." .. module_name).pick()
    end, { desc = name:gsub("Workbench", "Workbench ") })
  end
end

return M
