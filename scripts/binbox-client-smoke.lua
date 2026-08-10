local source = debug.getinfo(1, "S").source:gsub("^@", "")
local repo_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source)))
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local client = require("binbox.client")
local paths, decode_error = client._project_paths({
  schema_version = 1,
  ok = true,
  data = { projects = { { id = "alpha", path = "/tmp/alpha" } } },
})
if decode_error or not paths or paths[1] ~= "/tmp/alpha" then
  error(decode_error or "versioned binbox envelope was not decoded")
end

local mismatch_paths, mismatch_error = client._project_paths({
  schema_version = 2,
  ok = true,
  data = { projects = {} },
})
if mismatch_paths ~= nil or not mismatch_error:match("schema version mismatch") then
  error("schema mismatch was not rejected")
end

local selected
local warning
Snacks = {
  notify = {
    warn = function(message)
      warning = message
    end,
  },
  picker = {
    projects = function(opts)
      selected = opts
    end,
  },
}

package.loaded["binbox.client"] = {
  projects = function(callback)
    callback({ "/tmp/binbox" }, nil)
  end,
}
package.loaded["binbox.projects"] = nil
require("binbox.projects").pick()
if not selected or selected.projects[1] ~= "/tmp/binbox" or warning then
  error("project picker did not use binbox data")
end

selected = nil
warning = nil
package.loaded["binbox.client"] = {
  projects = function(callback)
    callback(nil, "fixture binbox failure")
  end,
}
package.loaded["binbox.projects"] = nil
require("binbox.projects").pick()
if not selected or type(selected.dev) ~= "table" or not warning:match("sessionizer fallback") then
  error("legacy sessionizer fallback was not selected")
end

require("binbox").setup()
local commands = vim.api.nvim_get_commands({})
if not commands.BinboxProjects then
  error("BinboxProjects command was not registered")
end
for _, retired in ipairs({ "WorkbenchProjects", "WorkbenchAgents", "WorkbenchWorktrees", "WorkbenchDoctor" }) do
  if commands[retired] then
    error(retired .. " command must be retired")
  end
end

print("lazyvim binbox client: ok")
