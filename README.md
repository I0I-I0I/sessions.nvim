# sessions.nvim

A simple plugin for managing sessions in Neovim.

https://github.com/user-attachments/assets/069c4d03-4140-4e02-8678-20eef0cbc923

## Features

- Create and load sessions
- Delete sessions
- Rename sessions
- List sessions (with telescope.nvim)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
local M = { "i0i-i0i/sessions.nvim" }

--- OPTIONAL (only for SessionsList) ---
M.dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim"
}
--- OPTIONAL (only for SessionsList) ---

M.opts = {
    path = "path/to/sessions_folder", -- default = "~/sessions"
    attach_after_enter = true, -- if false just change cwd
    promt_title = "Your title"
}

M.keys = {
    { "<leader>ss", "<cmd>SessionSave<cr>", desc = "Save session" },
    { "<leader>sc", "<cmd>SessionCreate<cr>", desc = "Create session" },
    { "<leader>sa", "<cmd>SessionAttach<cr>", desc = "Attach session" },
    { "<leader>sl", "<cmd>SessionsList<cr>", desc = "List sessions" }, -- only if you have telescope.nvim
}

return M
```

## Default commands

Create new session for current path:

```lua
vim.api.nvim_create_user_command("SessionCreate", function()
    sessions.create_session()
end, {})
```

Show sessions list in telescope:

```lua
vim.api.nvim_create_user_command("SessionsList", function()
    sessions.open_list()
end, {})
```

This creates a session but doesn't give it a name, you can use SessionAttach or SessionCreate to specify a name.
Session is linked to the current directory:

```lua
vim.api.nvim_create_user_command("SessionSave", function()
    sessions.save_session()
end, {})
```

Find session (in opts.path) for current path and attach, if not found print error:

```lua
vim.api.nvim_create_user_command("SessionAttach", function(input)
    if input.args and #input.args > 0 then
        local args = input.args
        local ok = commands.attach_session({ name = args })
        if not ok then
            print("Session doesn't exist: " .. args)
        end
    else
        local ok = commands.attach_session()
        if not ok then
            print("Cann't found session here")
        end
    end
end, { nargs = '?' })
```

## Add your own functionality

Auto save session on exit and auto attach session on enter (you need to delete M.opts and use only M.config):

```lua
M.lazy = false -- REQUIRED

M.config = function()
    local builtins = require("sessions").setup(opts)

    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.schedule(function()
                builtins.attach()
            end)
        end
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            builtins.save()
        end
    })
end
```

Or you can move between previous session with <leader><C-^>:

```lua
M.config = function()
    ---@class Session
    ---@field name string
    ---@field path string

    ---@type Session
    local prev = { name = "", path = "" }

    local builtins = require("sessions").setup()

    ---@param new_session Session
    local goto_prev = function(new_session)
        prev = builtins.get_current()
        if new_session.path ~= "" and prev.path ~= new_session.path then
            builtins.attach({ path = new_session.path })
        end
    end

    vim.keymap.set("n", "<leader><C-^>", function()
        builtins.save()
        goto_prev(prev)
    end)

    vim.api.nvim_create_user_command("CustomSessionAttach", function(input)
        prev = builtins.get_current()
        vim.cmd("SessionAttach " .. input.args)
    end, { nargs  = "?"})
end

M.keys {
    -- ...
    { "<leader>sa", "<cmd>CustomSessionAttach<cr>", desc = "Attach session" }
}
```

## Telescope maps

```lua
{
    ["n"] = {
        ["dd"] = delete_session,
        ["rr"] = rename_session,
        ["<CR>"] = attach_session,
    },
    ["i"] = {
        ["<C-d>"] = delete_session,
        ["<C-r>"] = rename_session,
        ["<CR>"] = attach_session,
    }
}
```

## TODOs

1. Make this better
