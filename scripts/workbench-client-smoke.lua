local source = debug.getinfo(1, "S").source:gsub("^@", "")
local repo_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source)))
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local client = require("workbench.client")
local data, warnings, decode_error = client._decode({
  code = 0,
  stdout = [[{"schema_version":1,"ok":true,"data":{"projects":[]},"warnings":[],"error":null}]],
  stderr = "",
})
if decode_error or type(data.projects) ~= "table" or type(warnings) ~= "table" then
  error("versioned Workbench envelope was not decoded")
end

local mismatch_data, _, mismatch_error = client._decode({
  code = 0,
  stdout = [[{"schema_version":2,"ok":true,"data":{},"warnings":[],"error":null}]],
  stderr = "",
})
if mismatch_data ~= nil or not mismatch_error:match("schema version mismatch") then
  error("schema mismatch was not rejected")
end

local temp_dir = vim.fn.tempname()
vim.fn.mkdir(temp_dir, "p")
local executable = temp_dir .. "/wb"
vim.fn.writefile({
  "#!/bin/sh",
  [[printf '%s\n' '{"schema_version":1,"ok":true,"data":{"projects":[{"id":"alpha","name":"alpha","path":"/tmp/alpha"}]},"warnings":[],"error":null}']],
}, executable)
vim.fn.setfperm(executable, "rwx------")
local original_path = vim.env.PATH
vim.env.PATH = temp_dir .. ":" .. original_path
local completed = false
client.request({ "projects", "list", "--json" }, function(result, _, err)
  if err or not result or result.projects[1].id ~= "alpha" then
    error(err or "async Workbench request returned wrong data")
  end
  completed = true
end)
if not vim.wait(2000, function()
  return completed
end, 20) then
  error("async Workbench callback timed out")
end
vim.env.PATH = original_path
vim.fn.delete(temp_dir, "rf")

local selected
local warning
Snacks = {
  notify = { warn = function(message)
    warning = message
  end },
  picker = { projects = function(opts)
    selected = opts
  end },
}
package.loaded["workbench.client"] = {
  request = function(_, callback)
    callback({ projects = { { id = "alpha", path = "/tmp/alpha" } } }, {}, nil)
  end,
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if not selected or selected.projects[1] ~= "/tmp/alpha" or warning then
  error("Workbench project picker did not use wb data")
end

selected = nil
package.loaded["workbench.client"] = {
  request = function(_, callback)
    callback(nil, {}, "fixture wb failure")
  end,
}
package.loaded["workbench.binbox"] = {
  projects = function(callback)
    callback(nil, "fixture binbox failure")
  end,
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if not selected or type(selected.dev) ~= "table" or not warning:match("sessionizer fallback") then
  error("legacy sessionizer fallback was not selected")
end

require("workbench").setup()
local commands = vim.api.nvim_get_commands({})
for _, name in ipairs({ "WorkbenchProjects", "WorkbenchAgents", "WorkbenchWorktrees", "WorkbenchDoctor" }) do
  if not commands[name] then
    error(name .. " command was not registered")
  end
end

print("lazyvim workbench client: ok")
