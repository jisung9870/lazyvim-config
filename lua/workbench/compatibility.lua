local M = {}

function M.observe(client, feature, source)
  if vim.fn.executable("wb") ~= 1 then
    return
  end
  vim.system({
    "wb",
    "compatibility",
    "observe",
    "--client",
    client,
    "--feature",
    feature,
    "--source",
    source,
  }, { text = true, stdout = false, stderr = false }, function() end)
end

return M
