local M = {}

local schema_version = 1
local timeout_ms = 5000

local function project_paths(payload)
  if type(payload) ~= "table" then
    return nil, "invalid JSON payload"
  end
  if payload.schema_version ~= schema_version then
    return nil,
      ("schema version mismatch (client=%d, binbox=%s); update binbox and LazyVim together"):format(
        schema_version,
        tostring(payload.schema_version)
      )
  end
  if payload.ok ~= true then
    local message = payload.error and payload.error.message or "binbox request failed"
    return nil, message
  end
  local projects = payload.data and payload.data.projects
  if type(projects) ~= "table" then
    return nil, "binbox response is missing data.projects"
  end

  local paths = {}
  for _, project in ipairs(projects) do
    if type(project) ~= "table" or type(project.path) ~= "string" then
      return nil, "binbox project item is missing path"
    end
    table.insert(paths, vim.fs.normalize(project.path))
  end
  return paths
end

function M.projects(callback)
  if vim.fn.executable("bb") ~= 1 then
    callback(nil, "bb executable not found")
    return
  end

  local completed = false
  local timer = assert(vim.uv.new_timer())
  local process

  local function finish(result, timed_out)
    if completed then
      return
    end
    completed = true
    timer:stop()
    timer:close()
    vim.schedule(function()
      if timed_out then
        callback(nil, ("bb project request timed out after %dms"):format(timeout_ms))
        return
      end
      if result.code ~= 0 then
        local detail = vim.trim(result.stderr or "")
        callback(nil, detail ~= "" and detail or ("bb exited with code %d"):format(result.code))
        return
      end
      local ok, payload = pcall(vim.json.decode, result.stdout or "")
      if not ok then
        callback(nil, "bb returned invalid JSON")
        return
      end
      local paths, err = project_paths(payload)
      callback(paths, err)
    end)
  end

  process = vim.system({ "bb", "tm", "projects", "--json" }, { text = true }, function(result)
    finish(result, false)
  end)
  timer:start(timeout_ms, 0, function()
    process:kill(15)
    finish({ code = 124, stdout = "", stderr = "" }, true)
  end)
end

M._project_paths = project_paths

return M
