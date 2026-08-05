local M = {}

local function notify(message, level)
  Snacks.notify(message, { level = level or vim.log.levels.INFO, title = "Workbench Doctor" })
end

function M.pick()
  require("workbench.client").request({ "doctor", "--json" }, function(data, warnings, err)
    if not data or type(data.capabilities) ~= "table" then
      notify(err or "Workbench response is missing doctor capabilities", vim.log.levels.ERROR)
      return
    end
    if err then
      notify(err, vim.log.levels.WARN)
    elseif warnings and #warnings > 0 then
      notify(table.concat(warnings, "\n"), vim.log.levels.WARN)
    end
    vim.ui.select(data.capabilities, {
      prompt = ("Workbench Doctor · %s · %s"):format(data.platform, data.profile),
      format_item = function(capability)
        return ("%-11s %-9s %s"):format(capability.status, capability.scope, capability.name)
      end,
    }, function(capability)
      if not capability then
        return
      end
      local details = { capability.description }
      if capability.version then
        table.insert(details, "version: " .. capability.version)
      end
      if capability.reason then
        table.insert(details, "reason: " .. capability.reason)
      end
      if capability.recovery then
        table.insert(details, "recovery: " .. capability.recovery)
      end
      notify(table.concat(details, "\n"), capability.available and vim.log.levels.INFO or vim.log.levels.WARN)
    end)
  end)
end

return M
