<div align="center">
      <h1> <img src="https://i.postimg.cc/HkJsD67j/dotenv.png" width="80px"><br/>dotenv.nvim</h1>
     </div>
<p align="center"> 
      <a href="https://twitter.com/intent/user?screen_name=ellisonleao" target="_blank"><img alt="Twitter Follow" src="https://img.shields.io/twitter/follow/ellisonleao?style=for-the-badge" style="vertical-align:center" ></a>
      <a href="#"><img alt="Made with Lua" src="https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua" style="vertical-align:center" /></a>
</p>

A minimalist .env support for Neovim (WIP)

# Prerequisites

Neovim 0.7.0+

# Feature

Load and set (or clear) the env variables from the available `env` file.
+ Default env file is `.env`.
+ Support to unset env variable by empty assigned, e.g.:
``` env
http_proxy=
https_proxy=$http_proxy
```
+ Support to set env by varname, like `${VarName}` or `$VAR_NAME`, e.g.:
``` env
http_proxy=http://127.0.0.1:12345
https_proxy=$http_proxy
```
+ Support to set env by the defined varname, which may be defined by system or envfile load.

# Installing

## `packer`

```lua
use { "zcchen/dotenv.nvim" }
```

## `lazy.nvim`
```lua
return {
    {
        "zcchen/dotenv.nvim"
        opts = {
            enable_on_load = true, -- will load your .env file upon loading a buffer
            verbose = false, -- show some verbose notification like what env variable is set
            file_name = 'myenvfile.env' -- will override the default file name '.env'
        }
    },
}
```

# Basic Usage

```lua
require('dotenv').setup()
```

# Configuration

Additional settings are:

```lua
require('dotenv').setup({
  enable_on_load = true, -- will load your .env file upon loading a buffer
  verbose = false, -- show error notification if .env file is not found and if .env is loaded
  file_name = 'myenvfile.env' -- will override the default file name '.env'
})
```

# Usage

## Loading .env

If you prefer to not load the .env file upon opening a file, you can use the user command:

```
:Dotenv
```

Optionally use a file as param, if the file is not in the current directory

```
:Dotenv PATH
```

## Inspecting an env (must load env first)

```
:DotenvGet ENV
```

## Set proxy for some nvim plugins

For `lazy.nvim` or `mason.nvim`, additional settings for `lazy.nvim` are:
```lua
config = function(_, opts)
    local dotenv = require("dotenv")
    dotenv.setup(opts)
    local proxy_file_set = vim.fn.expand(<proxy-set-file>)
        -- change <proxy-set-file> to your env file to set `https_proxy` variable
    local proxy_file_cls = vim.fn.expand(<proxy-cls-file)
        -- change <proxy-cls-file> to your env file to clear the `https_proxy` variable
    local bufwin_filetypes = {
        "mason", "lazy"
    }
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
            local is_matched = false
            local curr_ft = vim.bo.filetype 
            for _, v in ipairs(bufwin_filetypes) do
                local v_expand = v .. ".*"
                if string.match(curr_ft, v_expand) then
                    is_matched = true
                    break
                end
            end
            if is_matched then
                dotenv.load(proxy_file_set)
            else
                dotenv.load(proxy_file_cls)
            end
        end,
    })
end
```

