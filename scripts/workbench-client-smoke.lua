local source = debug.getinfo(1, "S").source:gsub("^@", "")
local repo_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(source)))
package.path = repo_root .. "/lua/?.lua;" .. repo_root .. "/lua/?/init.lua;" .. package.path

local done = false
local paths
local request_error
require("workbench.binbox").projects(function(result, err)
  paths = result
  request_error = err
  done = true
end)

if not vim.wait(7000, function()
  return done
end, 25) then
  error("workbench client callback timed out")
end
if request_error then
  error(request_error)
end
if type(paths) ~= "table" or #paths ~= 3 then
  error(("expected 3 project paths, got %s"):format(type(paths) == "table" and #paths or type(paths)))
end

local fallback_opts
package.loaded["workbench.binbox"] = {
  projects = function(callback)
    callback(nil, "fixture API failure")
  end,
}
Snacks = {
  notify = { warn = function() end },
  picker = {
    projects = function(opts)
      fallback_opts = opts
    end,
  },
}
package.loaded["workbench.projects"] = nil
require("workbench.projects").pick()
if type(fallback_opts) ~= "table" or type(fallback_opts.dev) ~= "table" then
  error("legacy sessionizer fallback was not selected")
end
print("lazyvim workbench client: ok")
