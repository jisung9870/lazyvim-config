local M = {}

local function notify(message, level)
  Snacks.notify(message, { level = level or vim.log.levels.INFO, title = "Workbench" })
end

function M.pick()
  require("workbench.client").request({ "projects", "list", "--json" }, function(data, _, err)
    if err then
      notify(err, vim.log.levels.ERROR)
      return
    end
    local projects = data and data.projects
    if type(projects) ~= "table" then
      notify("Workbench response is missing data.projects", vim.log.levels.ERROR)
      return
    end
    vim.ui.select(projects, {
      prompt = "Workbench project",
      format_item = function(project)
        return ("%s  %s"):format(project.name, project.path)
      end,
    }, function(project)
      if not project then
        return
      end
      require("workbench.client").request({ "worktrees", "list", project.id, "--json" }, function(result, _, list_err)
        if list_err then
          notify(list_err, vim.log.levels.ERROR)
          return
        end
        local items = result and result.worktrees
        if type(items) ~= "table" then
          notify("Workbench response is missing data.worktrees", vim.log.levels.ERROR)
          return
        end
        if #items == 0 then
          notify(("No linked worktrees for %s"):format(project.id))
          return
        end
        vim.ui.select(items, {
          prompt = ("Worktrees · %s"):format(project.name),
          format_item = function(item)
            return ("%-24s %s%s"):format(item.branch or item.id, item.dirty and "dirty · " or "", item.path)
          end,
        }, function(item)
          if item then
            Snacks.picker.files({ cwd = item.path })
          end
        end)
      end)
    end)
  end)
end

return M
