local M = {}

local function notify(message, level)
  Snacks.notify(message, { level = level or vim.log.levels.INFO, title = "Workbench" })
end

local function run_action(task, action)
  if action == "Details" then
    notify(
      ("%s · %s\nproject: %s\nbackend: %s\nstate: %s\ncwd: %s"):format(
        task.id,
        task.agent_kind,
        task.project_id,
        task.backend,
        task.state,
        task.cwd
      )
    )
    return
  end
  if action == "Stop" then
    vim.ui.select({ "Cancel", "Stop" }, { prompt = ("Stop registered task %s?"):format(task.id) }, function(choice)
      if choice == "Stop" then
        require("workbench.client").command({ "agents", "stop", task.id }, function(_, _, err)
          if err then
            notify(err, vim.log.levels.ERROR)
          else
            notify(("Stopped %s"):format(task.id))
          end
        end)
      end
    end)
    return
  end
  if action == "Jump" then
    require("workbench.client").command({ "agents", "jump", task.id }, function(_, _, err)
      if err then
        notify(err, vim.log.levels.ERROR)
      end
    end)
  end
end

function M.pick()
  require("workbench.client").request({ "agents", "list", "--json" }, function(data, _, err)
    if err then
      notify(err, vim.log.levels.ERROR)
      return
    end
    local tasks = data and data.agents
    if type(tasks) ~= "table" then
      notify("Workbench response is missing data.agents", vim.log.levels.ERROR)
      return
    end
    vim.ui.select(tasks, {
      prompt = "Workbench Agents",
      format_item = function(task)
        return ("%-8s %-10s %-16s %s"):format(task.state, task.agent_kind, task.project_id, task.id)
      end,
    }, function(task)
      if not task then
        return
      end
      local actions = { "Details" }
      if task.state == "running" or task.state == "waiting" or task.state == "idle" or task.state == "starting" then
        table.insert(actions, "Jump")
        table.insert(actions, "Stop")
      end
      vim.ui.select(actions, { prompt = task.id }, function(action)
        if action then
          run_action(task, action)
        end
      end)
    end)
  end)
end

return M
