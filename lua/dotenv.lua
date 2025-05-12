---@diagnostic disable: missing-parameter
-- main module file
local uv = vim.loop

local dotenv = {}

dotenv.config = {
  event = "VimEnter",
  enable_on_load = false,
  verbose = false,
  file_name = ".env",
}

local function notify(msg, level)
  if not dotenv.config.verbose then
    return
  end

  if level == nil then
    level = "INFO"
  end

  vim.notify(msg, vim.log.levels[level])
end

local function read_file(path)
  local fd = assert(vim.uv.fs_open(path, "r", tonumber('666', 8)))
  local stat = assert(vim.uv.fs_fstat(fd))
  local data = assert(vim.uv.fs_read(fd, stat.size, 0))
  assert(vim.uv.fs_close(fd))
  return data
end

local function parse_data(data)
  local out = {}
  local notify_msg = ""
  for line in string.gmatch(data, "[^\r\n]+") do
    local l = vim.trim(line)
    notify_msg = string.format(">>> raw line: <%s>", l)
    notify(notify_msg)
    if not vim.startswith(l, "#") and l ~= "" then
      -- filter-out the comment line nor empty line
      local k, v = string.match(l, '^([%w_]+)%s*=%s*(.*)$')
      notify_msg = string.format(">>> found key: <%s>, value: <%s>", k, v)
      notify(notify_msg)
      out[k] = v
    end
  end
  return out
end

local function get_env_file()
  local files = vim.fs.find(dotenv.config.file_name, { upward = true, type = "file" })
  if #files == 0 then
    return
  end
  return files[1]
end

local function load(file)
  if file == nil then
    file = get_env_file()
  end

  local ok, data = pcall(read_file, file)
  if not ok then
    notify(".env file not found", "ERROR")
    return
  end

  local env = parse_data(data)
  for k, v in pairs(env) do
    vim.fn.setenv(k, v)
  end
  notify(".env file loaded")
end

dotenv.setup = function(args)
  dotenv.config = vim.tbl_extend("force", dotenv.config, args or {})

  vim.api.nvim_create_user_command("Dotenv", function(opts)
    dotenv.command(opts)
  end, { nargs = "?", complete = "file" })
  vim.api.nvim_create_user_command("DotenvGet", function(opts)
    dotenv.get(opts.fargs)
  end, { nargs = 1 })

  if dotenv.config.enable_on_load then
    local group = vim.api.nvim_create_augroup("Dotenv", { clear = true })
    vim.api.nvim_create_autocmd(dotenv.config.event, { group = group, pattern = "*", callback = dotenv.autocmd })
  end
end

dotenv.get = function(arg)
  local var = string.upper(arg[1])
  if vim.env[var] == nil then
    print(var .. ": not found")
    return
  end
  print(vim.env[var])
end

dotenv.autocmd = function()
  load()
end

dotenv.command = function(opts)
  local args

  if opts ~= nil then
    if #opts.fargs > 0 then
      args = opts.fargs[1]
    end
  end

  load(args)
end

return dotenv
