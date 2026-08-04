local source = debug.getinfo(1, "S").source:gsub("^@", "")
local repo_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source)))
local sessionizer = dofile(repo_root .. "/lua/config/sessionizer.lua")
local path = arg[1]

if not path or path == "" then
  io.stderr:write("usage: nvim --headless -u NONE -l scripts/sessionizer-projects.lua <dirs-file>\n")
  vim.cmd("cquit 2")
  return
end

for _, project in ipairs(sessionizer.projects(path)) do
  io.write(project .. "\n")
end
