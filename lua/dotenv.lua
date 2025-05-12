---@diagnostic disable: missing-parameter
-- main module file
local dotenv = {}

dotenv.config = {
  event = "VimEnter",
  enable_on_load = false,
  verbose = false,
  file_name = ".env",
}

local function notify(msg, level)
  if (not dotenv.config.verbose) and (level ~= "ERROR" or level ~= "WARN") then
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

local function get_shell_varname(s)
  local bracket_l, varname, bracket_r = string.match(s, '^%$(%{*)([_%a]+[_%w]*)(%}*)$')
  local msg = string.format("bracket_l: '%s', bracket_r: '%s', varname: '%s'", bracket_l, bracket_r, varname)
  notify(msg)
  if ((bracket_l == "" and bracket_r == "") or (bracket_l == "{" and bracket_r == "}"))
      and varname ~= "" then -- bracket matched, continue...
    return varname
  else
    msg = string.format("var '%s' has incorrect format, must be like ${VarName} or $Var_Name.", s)
    notify(msg, "ERROR")
  end
end

local function parse_data(data)
  local out = {}
  local msg = ""
  for line in string.gmatch(data, "[^\r\n]+") do
    local l = vim.trim(line)
    msg = string.format(">>> raw line: '%s'", l)
    notify(msg)
    if not vim.startswith(l, "#") and l ~= "" then
      -- filter-out the comment line nor empty line
      local k, v = string.match(l, '^([%w_]+)%s*=%s*(.*)$')
      msg = string.format(">>> found key: '%s', value: '%s'", k, v)
      notify(msg)
      if v == "" then                      -- set empty string value
        out[k] = ""
      elseif not string.find(v, '%$') then -- common value data, set it normally
        out[k] = v
      else                                 -- try to find whether <v> is a defined varname.
        local varname = get_shell_varname(v)
        if not varname then                -- varname is invalid, return {}
          return {}
        end
        local is_varname_defined = false
        for kk, vv in pairs(out) do
          if varname == kk then -- found the defined varname
            out[k] = vv
            is_varname_defined = true
            break
          end
        end
        if not is_varname_defined then
          msg = string.format("var '%s' is NOT defined before, skip to modify env '%s'", v, k)
          notify(msg, "WARN")
        end
      end
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
  local msg = ""
  if file == nil then
    file = get_env_file()
  end
  local ok, data = pcall(read_file, file)
  if not ok then
    msg = string.format("file '%s' not found.", file)
    notify(msg, "ERROR")
    return
  end
  local env = parse_data(data)
  for k, v in pairs(env) do
    msg = string.format("setenv '%s' to '%s'", k, v)
    notify(msg)
    vim.fn.setenv(k, v)
  end
  msg = string.format("file '%s' loaded.", file)
  notify(msg)
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
