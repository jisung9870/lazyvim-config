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
local observation_file = temp_dir .. "/observation.args"
vim.fn.writefile({
  "#!/bin/sh",
  [[if [ "$1" = compatibility ]; then]],
  [[  printf '%s\n' "$@" > "$WB_OBSERVATION_FILE"]],
  [[  exit 9]],
  [[fi]],
  [[printf '%s\n' '{"schema_version":1,"ok":true,"data":{"projects":[{"id":"alpha","name":"alpha","path":"/tmp/alpha"}]},"warnings":[],"error":null}']],
}, executable)
vim.fn.setfperm(executable, "rwx------")
local original_path = vim.env.PATH
vim.env.PATH = temp_dir .. ":" .. original_path
vim.env.WB_OBSERVATION_FILE = observation_file
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
require("workbench.compatibility").observe("nvim", "projects", "workbench")
if not vim.wait(2000, function()
  return vim.uv.fs_stat(observation_file) ~= nil
end, 20) then
  error("compatibility observation timed out")
end
local observation_args = vim.fn.readfile(observation_file)
if
  table.concat(observation_args, " ") ~= "compatibility observe --client nvim --feature projects --source workbench"
then
  error("compatibility observation arguments changed")
end
vim.env.PATH = original_path
vim.env.WB_OBSERVATION_FILE = nil
vim.fn.delete(temp_dir, "rf")

local selected
local warning
local observed = {}
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
package.loaded["workbench.compatibility"] = {
  observe = function(client_name, feature, source_name)
    table.insert(observed, table.concat({ client_name, feature, source_name }, "/"))
  end,
}
package.loaded["workbench.client"] = {
  request = function(_, callback)
    callback({ projects = { { id = "alpha", path = "/tmp/alpha" } } }, {}, nil)
  end,
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if
  not selected
  or selected.projects[1] ~= "/tmp/alpha"
  or warning
  or observed[#observed] ~= "nvim/projects/workbench"
then
  error("Workbench project picker did not use wb data")
end

selected = nil
warning = nil
package.loaded["workbench.client"] = {
  request = function(_, callback)
    callback(nil, {}, "fixture wb failure")
  end,
}
package.loaded["workbench.binbox"] = {
  projects = function(callback)
    callback({ "/tmp/binbox" }, nil)
  end,
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if not selected or selected.projects[1] ~= "/tmp/binbox" or observed[#observed] ~= "nvim/projects/binbox" then
  error("binbox project fallback was not observed")
end

selected = nil
warning = nil
package.loaded["workbench.binbox"] = {
  projects = function(callback)
    callback(nil, "fixture binbox failure")
  end,
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if
  not selected
  or type(selected.dev) ~= "table"
  or not warning:match("sessionizer fallback")
  or observed[#observed] ~= "nvim/projects/sessionizer"
then
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
