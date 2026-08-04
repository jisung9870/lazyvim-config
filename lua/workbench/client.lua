local M = {}

local schema_version = 1
local timeout_ms = 5000

local function decode(result)
  local ok, payload = pcall(vim.json.decode, result.stdout or "")
  if not ok or type(payload) ~= "table" then
    local detail = vim.trim(result.stderr or "")
    if result.code ~= 0 and detail ~= "" then
      return nil, nil, detail
    end
    return nil, nil, "wb returned invalid JSON"
  end
  if payload.schema_version ~= schema_version then
    return nil,
      nil,
      ("schema version mismatch (client=%d, wb=%s); update Workbench and LazyVim together"):format(
        schema_version,
        tostring(payload.schema_version)
      )
  end
  local warnings = type(payload.warnings) == "table" and payload.warnings or {}
  if payload.ok ~= true then
    local message = payload.error and payload.error.message or ("wb exited with code %d"):format(result.code)
    return payload.data, warnings, message
  end
  if result.code ~= 0 then
    return payload.data, warnings, ("wb exited with code %d"):format(result.code)
  end
  return payload.data, warnings, nil
end

local function run(args, json, callback, opts)
  opts = opts or {}
  if vim.fn.executable("wb") ~= 1 then
    callback(nil, nil, "wb executable not found")
    return
  end

  local completed = false
  local timer = assert(vim.uv.new_timer())
  local process
  local command = { "wb" }
  vim.list_extend(command, args)

  local function finish(result, timed_out)
    if completed then
      return
    end
    completed = true
    timer:stop()
    timer:close()
    vim.schedule(function()
      if timed_out then
        callback(nil, nil, ("wb request timed out after %dms"):format(opts.timeout_ms or timeout_ms))
        return
      end
      if json then
        local data, warnings, err = decode(result)
        callback(data, warnings, err)
        return
      end
      if result.code ~= 0 then
        local detail = vim.trim(result.stderr or "")
        callback(nil, nil, detail ~= "" and detail or ("wb exited with code %d"):format(result.code))
        return
      end
      callback(result.stdout or "", {}, nil)
    end)
  end

  process = vim.system(command, { text = true }, function(result)
    finish(result, false)
  end)
  timer:start(opts.timeout_ms or timeout_ms, 0, function()
    process:kill(15)
    finish({ code = 124, stdout = "", stderr = "" }, true)
  end)
end

function M.request(args, callback, opts)
  run(args, true, callback, opts)
end

function M.command(args, callback, opts)
  run(args, false, callback, opts)
end

M._decode = decode

return M
