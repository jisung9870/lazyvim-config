local M = {}

local function sessionizer_picker(reason)
  Snacks.notify.warn(("bb project API unavailable; using sessionizer fallback: %s"):format(reason))
  Snacks.picker.projects({ dev = require("config.sessionizer").dev_roots() })
end

function M.list(callback)
  require("binbox.client").projects(function(paths, err)
    callback(paths, {}, err)
  end)
end

function M.pick()
  M.list(function(paths, _, err)
    if not paths then
      sessionizer_picker(err or "unknown error")
      return
    end
    Snacks.picker.projects({ projects = paths, dev = {}, recent = false })
  end)
end

return M
