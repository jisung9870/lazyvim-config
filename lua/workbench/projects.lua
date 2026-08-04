local M = {}

local function legacy_picker(reason)
  Snacks.notify.warn(("Workbench project API unavailable; using sessionizer fallback: %s"):format(reason))
  Snacks.picker.projects({ dev = require("config.sessionizer").dev_roots() })
end

function M.pick()
  require("workbench.binbox").projects(function(paths, err)
    if not paths then
      legacy_picker(err or "unknown error")
      return
    end
    Snacks.picker.projects({ projects = paths, dev = {}, recent = false })
  end)
end

return M
