-- Enable Neovim Lua bytecode caching for 30-50% faster startup
if vim.loader then
  vim.loader.enable()
end

-- Ensure ~/.local/bin and ~/go/bin are in PATH across all operating systems (Linux, macOS, Windows)
local is_win = vim.fn.has("win32") == 1
local path_sep = is_win and ";" or ":"
local extra_paths = {
  vim.fn.expand("~/.local/bin"),
  vim.fn.expand("~/go/bin"),
  vim.fn.expand("~/.cargo/bin"),
  vim.fn.expand("~/AppData/Roaming/npm"),
  vim.fn.expand("~/scoop/shims"),
}
for _, p in ipairs(extra_paths) do
  if vim.fn.isdirectory(p) == 1 and not string.find(vim.env.PATH, p, 1, true) then
    vim.env.PATH = p .. path_sep .. vim.env.PATH
  end
end


-- =========================================================================
-- 1. BOOTSTRAP PLUGIN MANAGER (lazy.nvim)
-- =========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " " -- Sets the leader key to Space

-- =========================================================================
-- 2. PLUGINS CONFIGURATION
-- =========================================================================
require("lazy").setup({
  
  -- High Contrast Theme (TokyoNight OLED)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        terminal_colors = true,
        on_colors = function(colors)
          colors.bg = "#000000"
          colors.bg_dark = "#000000"
          colors.bg_float = "#000000"
          colors.bg_sidebar = "#000000"
          colors.bg_statusline = "#000000"
        end,
        on_highlights = function(hl, c)
          hl["@function"] = { fg = c.blue, bold = true }
          hl["@function.call"] = { fg = c.blue, bold = true }
          hl["@lsp.type.function"] = { fg = c.blue, bold = true }
          
          hl["@method"] = { fg = c.cyan, italic = true }
          hl["@method.call"] = { fg = c.cyan, italic = true }
          hl["@function.method"] = { fg = c.cyan, italic = true }
          hl["@lsp.type.method"] = { fg = c.cyan, italic = true }

          hl["@variable"] = { fg = c.fg }
          hl["@lsp.type.variable"] = { fg = c.fg }
          hl["@property"] = { fg = c.teal }
          hl["@lsp.type.property"] = { fg = c.teal }

          hl["@module"] = { fg = c.orange }
          hl["@namespace"] = { fg = c.orange }
          hl["@lsp.type.namespace"] = { fg = c.orange }
          hl["@type"] = { fg = c.magenta }
          hl["@lsp.type.type"] = { fg = c.magenta }
          hl["@type.builtin"] = { fg = c.magenta, italic = true }

          hl["@variable.parameter"] = { fg = c.yellow }
          hl["@lsp.type.parameter"] = { fg = c.yellow }

          hl["@constant"] = { fg = c.orange, bold = true }
          hl["@constant.builtin"] = { fg = c.orange, italic = true }
          hl["@boolean"] = { fg = c.orange }

          hl["@constructor"] = { fg = c.magenta, bold = true }
          hl["@function.method.call"] = { fg = c.cyan, italic = true }

          hl["@operator"] = { fg = c.blue5 }
          hl["@string.escape"] = { fg = c.magenta }
          hl["@variable.member"] = { fg = c.teal }
        end,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = { bold = true },
          variables = {},
          sidebars = "dark", 
          floats = "dark",
        },
      })
      vim.cmd[[colorscheme tokyonight]]
    end,
  },

  -- Custom Heads-Up Display Dashboard
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      local logo = {
          [[    _  __                  _                ]],
          [[   / |/ /__  ___ _  __ __  (_) __ _         ]],
          [[  /    / -_)/ _ \ |/ // / / / /  ' \        ]],
          [[ /_/|_/\__/ \___/___/ \_,_//_/ /_/_/_/      ]],
          [[                                            ]],
          [[            Welcome, AniruddhRaam.          ]],
      }

      dashboard.section.header.val = {}
      for _ = 1, #logo do table.insert(dashboard.section.header.val, "") end

      local info_section = {
          type = "text",
          val = { "" },
          opts = { position = "center", hl = "Keyword" }
      }

      -- Custom function to bypass find_files and jump straight into NvimTree
      _G.Open_Project_In_Tree = function()
        local status_ok, telescope = pcall(require, "telescope")
        if not status_ok then return end
        telescope.extensions.projects.projects({
          attach_mappings = function(prompt_bufnr, map)
            local action_state = require("telescope.actions.state")
            local actions = require("telescope.actions")
            local open_tree = function()
              local selection = action_state.get_selected_entry()
              if not selection then return end
              actions.close(prompt_bufnr)
              local dir = selection.value
              if dir then
                _G._project_root = dir
                vim.cmd("cd " .. vim.fn.fnameescape(dir))
                vim.cmd("NvimTreeOpen " .. vim.fn.fnameescape(dir))
                local scratch_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_set_current_buf(scratch_buf)
              end
            end
            map("i", "<CR>", open_tree)
            map("n", "<CR>", open_tree)
            return true
          end
        })
      end

      -- Added the "e" shortcut below
      dashboard.section.buttons.val = {
          dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
          dashboard.button("d", "󰉖  Browse Dirs", ":Telescope file_browser<CR>"),
          dashboard.button("e", "󰙅  Open Project in Tree", "<cmd>lua _G.Open_Project_In_Tree()<CR>"),
          dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
          dashboard.button("p", "󰏋  Active Projects (Restore Tabs)", ":AutoSession search<CR>"),
          dashboard.button("q", "󰅙  Quit NVIM", ":qa<CR>"),
      }

      dashboard.config.layout = {
          { type = "padding", val = function() return math.floor(vim.o.lines * 0.25) end },
          dashboard.section.header,
          { type = "padding", val = 2 },
          info_section,
          { type = "padding", val = function() return math.floor(vim.o.lines * 0.25) end },
          dashboard.section.buttons,
          { type = "padding", val = 1 },
      }

      alpha.setup(dashboard.opts)

      -- Error handling for dashboard: silence accidental keystrokes that would cause "E21: Cannot make changes, 'modifiable' is off"
      local function setup_alpha_key_handler(bufnr)
        bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
        local preserve_keys = {
          ["j"] = true, ["k"] = true, ["h"] = true, ["l"] = true,
          ["<Up>"] = true, ["<Down>"] = true, ["<Left>"] = true, ["<Right>"] = true,
          ["<CR>"] = true, ["<Tab>"] = true, ["<S-Tab>"] = true,
          ["<Esc>"] = true, [":"] = true, [" "] = true,
        }

        -- Preserve button shortcuts configured in dashboard
        for _, button in ipairs(dashboard.section.buttons.val or {}) do
          if button.opts and button.opts.shortcut then
            local sc = button.opts.shortcut:match("%s*(%S+)%s*")
            if sc then preserve_keys[sc] = true end
          end
        end

        if vim.g.mapleader then
          preserve_keys[vim.g.mapleader] = true
        end

        local keys_to_nop = {
          "i", "I", "a", "A", "o", "O", "s", "S", "c", "C", "r", "R", "u", "U",
          "x", "X", "d", "D", "p", "P", "y", "Y", "~", "J", "g", "G", "v", "V",
          "<C-v>", "<C-a>", "<C-x>", "<C-r>", "<BS>", "<Del>", "<Insert>",
          "<", ">", "=", ".",
        }
        for b = 32, 126 do
          table.insert(keys_to_nop, string.char(b))
        end

        for _, k in ipairs(keys_to_nop) do
          if not preserve_keys[k] then
            pcall(vim.keymap.set, { "n", "v" }, k, "<Nop>", { buffer = bufnr, silent = true, nowait = true })
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "alpha",
        callback = function(args)
          setup_alpha_key_handler(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
              setup_alpha_key_handler(vim.api.nvim_get_current_buf())
              vim.b.miniindentscope_disable = true
              for i = 1, #logo do dashboard.section.header.val[i] = "" end
              local row, col, pause_ticks = 1, 1, 0
              local info_typed, info_col = false, 1
              
              local function get_datetime() return os.date("%A, %d-%m-%Y  |  %H:%M:%S") end
              
              local function draw_frame()
                  if vim.bo.filetype ~= "alpha" then return end
                  local needs_redraw = false
                  
                  if pause_ticks > 0 then
                      pause_ticks = pause_ticks - 1
                      if pause_ticks == 0 then
                          for i = 1, #logo do dashboard.section.header.val[i] = "" end
                          row, col, needs_redraw = 1, 1, true
                      end
                  else
                      if row <= #logo then
                          local target_line = logo[row]
                          col = col + 2
                          if col > #target_line then col = #target_line end
                          dashboard.section.header.val[row] = target_line:sub(1, col)
                          needs_redraw = true
                          if col >= #target_line then
                              row, col = row + 1, 1
                              if row > #logo then pause_ticks = 75 end
                          end
                      end
                  end

                  local current_info = get_datetime()
                  if not info_typed then
                      info_col = info_col + 1
                      if info_col >= #current_info then
                          info_col, info_typed = #current_info, true
                      end
                      info_section.val[1] = current_info:sub(1, info_col)
                      needs_redraw = true
                  else
                      if info_section.val[1] ~= current_info then
                          info_section.val[1] = current_info
                          needs_redraw = true
                      end
                  end
                  
                  if needs_redraw then pcall(vim.cmd.AlphaRedraw) end
                  vim.defer_fn(draw_frame, 15)
              end
              draw_frame()
          end,
      })
    end
  },

  -- Automated Session Management (Restores tabs automatically)
  {
    "rmagatti/auto-session",
    config = function()
      local function clean_unnamed_buffers()
        -- 1. Wipe unlisted/unnamed empty scratch buffers
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(bufnr) then
            local name = vim.api.nvim_buf_get_name(bufnr)
            local bt = vim.bo[bufnr].buftype
            local ft = vim.bo[bufnr].filetype
            local modified = vim.bo[bufnr].modified
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            local is_empty = (line_count <= 1 and (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "") == "")
            if (name == "" or ft == "alpha") and is_empty and not modified and (bt == "" or bt == "nofile") then
              pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
          end
        end

        -- 2. Close any orphaned blank window splits
        local file_wins = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative == "" then
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype
              local name = vim.api.nvim_buf_get_name(buf)
              if ft ~= "NvimTree" and ft ~= "aerial" and ft ~= "toggleterm" and ft ~= "trouble" and ft ~= "alpha" and name ~= "" then
                table.insert(file_wins, win)
              end
            end
          end
        end

        if #file_wins > 0 then
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
              local cfg = vim.api.nvim_win_get_config(win)
              if cfg.relative == "" then
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[buf].filetype
                local name = vim.api.nvim_buf_get_name(buf)
                if ft == "" and name == "" and not vim.bo[buf].modified then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end
          end
        end
      end

      require("auto-session").setup({
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
        auto_restore_enabled = true, 
        auto_save_enabled = true,
        bypass_save_filetypes = { "alpha" },
        pre_save_cmds = { 
          "NvimTreeClose", 
          "AerialClose", 
          function() pcall(vim.cmd, "Trouble close") end,
          clean_unnamed_buffers,
          -- Reset cwd to the explicitly tracked project root before saving.
          function()
            if _G._project_root and vim.fn.isdirectory(_G._project_root) == 1 then
              vim.cmd("cd " .. vim.fn.fnameescape(_G._project_root))
            end
          end,
        },
        pre_restore_cmds = {
          clean_unnamed_buffers,
        },
        post_restore_cmds = {
          clean_unnamed_buffers,
          -- Open NvimTree rooted at the (now-correct) project cwd
          function()
            vim.cmd("NvimTreeOpen " .. vim.fn.fnameescape(vim.fn.getcwd()))
          end,
          clean_unnamed_buffers,
        },
      })
    end,
  },

  -- Project Root Detection & Management
  {
    "coffebar/project.nvim",
    config = function()
      require("project_nvim").setup({
        manual_mode = true, -- Don't auto-change cwd; we track it explicitly
        detection_methods = { "pattern" },
        patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "go.mod" },
      })
    end
  },

  -- Lightning Fast Navigation (Flash)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { search = { enabled = true } } },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Code Outline Sidebar (Aerial)
  {
    "stevearc/aerial.nvim",
    lazy = false,
    dependencies = {
       "nvim-treesitter/nvim-treesitter",
       "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("aerial").setup({
        -- Try LSP first, fall back to treesitter (covers markdown, etc.)
        backends = { "lsp", "treesitter" },
        layout = {
          max_width = { 40, 0.2 },
          min_width = 25,
          default_direction = "right",
          placement = "edge",
          preserve_equality = true,
        },
        open_automatic = function(bufnr)
          if _G._aerial_user_closed then return false end
          local ft = vim.bo[bufnr].filetype
          if ft == "" or ft == "aerial" or ft == "NvimTree" or ft == "alpha" or ft == "toggleterm" or ft == "trouble" then
            return false
          end
          return true
        end,
        on_first_symbols = function(bufnr)
          if _G._aerial_user_closed then return end
          local curr_buf = vim.api.nvim_get_current_buf()
          if bufnr == curr_buf then
            local ft = vim.bo[bufnr].filetype
            if ft ~= "" and ft ~= "aerial" and ft ~= "NvimTree" and ft ~= "alpha" and ft ~= "toggleterm" and ft ~= "trouble" then
              local aerial = require("aerial")
              if not aerial.is_open({ bufnr = bufnr }) then
                pcall(aerial.open, { bufnr = bufnr, focus = false })
              end
            end
          end
        end,
        filter_kind = {
          _ = {
            "Class", "Constructor", "Enum", "Function", "Interface",
            "Module", "Method", "Struct", "Variable", "Constant",
            "Field", "Property", "TypeParameter",
          },
          markdown = false,
          help = false,
          tex = false,
          latex = false,
          plaintex = false,
        },
        icons = {
          Class = "󰠱 ", Function = "󰊕 ", Method = "󰆧 ",
          Struct = "󰙅 ", Interface = " ", Module = "󰏗 ",
          Variable = "󰀫 ", Constant = "󰏿 ", Field = "󰜢 ",
          Property = "󰖷 ", TypeParameter = "󰗴 ",
          String = "󰅳 ", File = "󰈙 ", Package = "󰏖 ",
          Namespace = "󰌗 ", Array = "󰅪 ", Object = "󰅩 ",
          Key = "󰌋 ", Number = "󰎠 ", Boolean = "󰨙 ",
        },
        show_guides = true,
        guides = {
          mid_item = "├─ ",
          last_item = "└─ ",
          nested_top = "│  ",
          whitespace = "   ",
        },
        -- Highlight & auto-scroll to the current symbol as the cursor moves
        highlight_on_hover = true,
        autojump = true,
        close_on_select = false,
        -- Auto-close when entering a buffer with no symbol support
        close_automatic_events = { "unsupported" },
        -- Keymaps inside the aerial window
        keymaps = {
          ["<CR>"] = "actions.tree_toggle",  -- Enter collapses/expands nodes
          ["o"] = "actions.jump",             -- 'o' to jump to symbol
        },
      })
    end
  },

  -- Ultimate Searching & Fuzzy Finding (Telescope)
  {
    "nvim-telescope/telescope.nvim",
    branch = "master", -- Force master branch to fix 'Invalid buffer id' crash
    dependencies = { 
        "nvim-lua/plenary.nvim", 
        "nvim-tree/nvim-web-devicons",
        "nvim-telescope/telescope-file-browser.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" }
    },
    config = function()
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Universal function to open a highlighted item's directory in NvimTree
      local open_in_tree = function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end
        actions.close(prompt_bufnr)
        local dir = selection.path or selection.value or selection.cwd or vim.fn.getcwd()
        if vim.fn.isdirectory(dir) == 0 then
          dir = vim.fn.fnamemodify(dir, ":h")
        end
        vim.cmd("cd " .. vim.fn.fnameescape(dir))
        vim.cmd("NvimTreeOpen " .. vim.fn.fnameescape(dir))
      end

      -- File Size Cap to prevent previewer crashes on giant/minified files
      local previewers = require("telescope.previewers")
      local new_maker = function(filepath, bufnr, opts)
        opts = opts or {}
        filepath = vim.fn.expand(filepath)
        
        vim.uv.fs_stat(filepath, function(_, stat)
          if not stat then return end
          
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then return end
            
            if stat.size > 100000 then -- 100KB Limit
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "FILE TOO LARGE TO PREVIEW" })
            else
              previewers.buffer_previewer_maker(filepath, bufnr, opts)
            end
          end)
        end)
      end

      require("telescope").setup({
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case"
          },
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          buffer_previewer_maker = new_maker,
          file_ignore_patterns = { ".git/", "node_modules/", "__pycache__/", ".venv/", "target/" },
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          mappings = {
            i = {
              ["<C-e>"] = open_in_tree, -- Press Ctrl+e in any telescope window to jump to the tree
              ["<Esc>"] = actions.close,
            },
            n = {
              ["<C-e>"] = open_in_tree,
              ["<Esc>"] = actions.close,
            }
          }
        },
        pickers = {
          find_files = {
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix" }
          }
        },
        extensions = {
          file_browser = { theme = "ivy", hijack_netrw = true },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        }
      })
      require("telescope").load_extension("projects")
      require("telescope").load_extension("file_browser") 
      pcall(require("telescope").load_extension, "fzf")
    end,
  },

  -- Persistent File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local is_win = vim.fn.has("win32") == 1

      --- Asynchronously delete a single file or directory in the background
      ---@param target_path string Path to delete
      ---@param on_done? fun(success: boolean) Callback on completion
      local function async_delete_single(target_path, on_done)
        if not target_path or target_path == "" then return end
        local is_dir = vim.fn.isdirectory(target_path) == 1
        local cmd = {}

        if is_win then
          local win_path = target_path:gsub("/", "\\")
          if is_dir then
            cmd = { "cmd.exe", "/c", "rmdir", "/s", "/q", win_path }
          else
            cmd = { "cmd.exe", "/c", "del", "/f", "/q", win_path }
          end
        else
          cmd = { "rm", "-rf", target_path }
        end

        local name = vim.fn.fnamemodify(target_path, ":t")
        if name == "" then name = target_path end

        vim.notify(string.format("Deleting '%s' in background...", name), vim.log.levels.INFO, { title = "Async Delete" })

        vim.system(cmd, {}, function(obj)
          vim.schedule(function()
            if obj.code == 0 then
              vim.notify(string.format("Successfully deleted '%s'", name), vim.log.levels.INFO, { title = "Async Delete" })
              -- Clean up any open buffers matching the deleted path
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                  local buf_name = vim.api.nvim_buf_get_name(buf)
                  if buf_name ~= "" and (buf_name == target_path or (is_win and buf_name:lower() == target_path:lower())) then
                    pcall(vim.api.nvim_buf_delete, buf, { force = true })
                  end
                end
              end
            else
              local err = (obj.stderr and obj.stderr ~= "") and obj.stderr or ("Exit code " .. tostring(obj.code))
              vim.notify(string.format("Failed to delete '%s': %s", name, vim.trim(err)), vim.log.levels.ERROR, { title = "Async Delete" })
            end
            if on_done then on_done(obj.code == 0) end
          end)
        end)
      end

      --- Asynchronously delete multiple paths in parallel
      ---@param paths string[] List of paths to delete
      ---@param on_done? fun(all_success: boolean) Callback on completion
      local function async_delete_multiple(paths, on_done)
        if not paths or #paths == 0 then return end
        local total = #paths
        local completed = 0
        local has_error = false

        for _, p in ipairs(paths) do
          async_delete_single(p, function(success)
            completed = completed + 1
            if not success then has_error = true end
            if completed == total and on_done then
              on_done(not has_error)
            end
          end)
        end
      end

      -- Expose globally for use anywhere in Neovim
      _G.Async_Delete_Path = async_delete_single
      _G.Async_Delete_Paths = async_delete_multiple

      --- Custom delete action for NvimTree (replaces blocking synchronous deletion on 'd' and 'D')
      local function nvim_tree_async_remove(node)
        local api = require("nvim-tree.api")
        local marks = api.marks.list()
        local targets = {}

        if #marks > 0 then
          for _, m in ipairs(marks) do
            if m.absolute_path then
              table.insert(targets, m.absolute_path)
            end
          end
        else
          local target_node = node or api.tree.get_node_under_cursor()
          if target_node and target_node.absolute_path then
            table.insert(targets, target_node.absolute_path)
          end
        end

        if #targets == 0 then
          vim.notify("No file or folder selected for deletion", vim.log.levels.WARN, { title = "NvimTree" })
          return
        end

        local prompt_msg
        if #targets == 1 then
          local name = vim.fn.fnamemodify(targets[1], ":t")
          local is_dir = vim.fn.isdirectory(targets[1]) == 1
          prompt_msg = string.format("Delete %s '%s' in background? [y/N]: ", is_dir and "folder" or "file", name)
        else
          prompt_msg = string.format("Delete %d marked items in background? [y/N]: ", #targets)
        end

        vim.ui.input({ prompt = prompt_msg }, function(choice)
          if choice and (choice:lower() == "y" or choice:lower() == "yes") then
            async_delete_multiple(targets, function()
              if #marks > 0 then
                api.marks.clear()
              end
              api.tree.reload()
            end)
          end
        end)
      end

      require("nvim-tree").setup({
        sync_root_with_cwd = true, -- Follow cwd changes so tree matches project root
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "q", "<cmd>wincmd p<CR>", { buffer = bufnr, noremap = true, silent = true, desc = "Return to code" })

          -- Override blocking deletion keys ('d' and 'D') with async background execution
          vim.keymap.set("n", "d", nvim_tree_async_remove, { buffer = bufnr, noremap = true, silent = true, desc = "Async Delete (Background)" })
          vim.keymap.set("n", "D", nvim_tree_async_remove, { buffer = bufnr, noremap = true, silent = true, desc = "Async Delete (Background)" })
        end,
        view = { width = 35, side = "left" },
        filesystem_watchers = {
          enable = true,
          debounce_delay = 150,
          ignore_dirs = {
            "node_modules",
            "target",
            "%.git",
            "%.venv",
            "build",
            "dist",
            "__pycache__",
          },
          max_events = 0, -- Set to 0 (unlimited) to prevent disabling watcher during directory deletions on Windows; matches Linux default
        },
        renderer = {
          indent_markers = {
            enable = true,
            inline_arrows = true,
            icons = {
              corner = "└",
              edge = "│",
              item = "├",
              bottom = "─",
              none = " ",
            },
          },
          highlight_git = true,
          highlight_opened_files = "all",
          highlight_diagnostics = true,
          icons = {
            show = {
              git = false, -- Disabled per request
            },
          },
        },
        filters = { dotfiles = false, git_ignored = false },
      })
    end,
  },

  -- Visual Tabs
  { 
    "akinsho/bufferline.nvim", 
    version = "*", 
    dependencies = "nvim-tree/nvim-web-devicons", 
    config = function() 
      require("bufferline").setup({
        options = {
          offsets = {
            { filetype = "NvimTree", text = "File Explorer", highlight = "Directory", separator = true },
            { filetype = "aerial", text = "Code Structure", highlight = "Directory", separator = true }
          }
        }
      }) 
    end 
  },

  -- Syntax Highlighting (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })
      require("nvim-treesitter").install({
        "javascript", "typescript", "tsx", "jsdoc",
        "c", "cpp", "python", "html",
        "css", "lua", "markdown", "rust", "toml",
        "go", "gomod", "gowork", "gosum", "gotmpl",
        "java", "latex", "bibtex",
      })

      -- The new nvim-treesitter (main branch) only installs parsers;
      -- it does NOT enable highlighting automatically.
      -- We must explicitly start treesitter highlighting for each buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ok = pcall(vim.treesitter.start, args.buf)
          if ok then
            -- Disable legacy regex syntax highlighting when treesitter is active
            vim.bo[args.buf].syntax = ""
          end
        end,
      })
    end,
  },

  -- Formatting & Intelligent Error Handling
  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")
      local conform_ns = vim.api.nvim_create_namespace("conform_formatter_errors")

      --- Parse conform / formatter error messages into structured items
      ---@param err_str string Raw error string or conform log chunk
      ---@param default_bufnr? integer Current buffer number if available
      ---@return string formatter_name
      ---@return table[] parsed_errors
      local function parse_formatter_error(err_str, default_bufnr)
        local errors = {}
        local formatter_name = "formatter"

        local fmt_match = err_str:match("Formatter '([^']+)'")
        if fmt_match then
          formatter_name = fmt_match
        end

        local default_buf_name = (default_bufnr and vim.api.nvim_buf_is_valid(default_bufnr))
            and vim.api.nvim_buf_get_name(default_bufnr) or ""

        local lines = vim.split(err_str, "\r?\n", { trimempty = true })

        for _, raw_line in ipairs(lines) do
          local line = vim.trim(raw_line)
          -- Strip log timestamp and level prefix: e.g. "2026-08-17 08:27:03[ERROR] "
          line = line:gsub("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%[[%w_]+%]%s*", "")
          -- Strip Formatter '<name>' error: prefix
          local stripped_fmt, rest = line:match("^Formatter '([^']+)'%s*error:%s*(.*)")
          if stripped_fmt then
            formatter_name = stripped_fmt
            line = rest
          else
            local timeout_fmt = line:match("^Formatter '([^']+)'%s*timeout")
            if timeout_fmt then
              formatter_name = timeout_fmt
              line = "Formatter timed out"
            end
          end

          if line ~= "" then
            local parsed = nil

            -- Pattern 1: Ruff / Python "error: Failed to parse <filename>:<line>:<col>: <msg>"
            local ruff_file, ruff_l, ruff_c, ruff_msg = line:match("error:%s*Failed to parse%s+([^:]+):(%d+):(%d+):%s*(.+)")
            if ruff_file then
              parsed = {
                file = ruff_file,
                lnum = tonumber(ruff_l),
                col = tonumber(ruff_c),
                msg = ruff_msg,
              }
            end

            -- Pattern 2: Standard input with path prefix or <standard input>:
            -- e.g. "C:\...\<standard input>:11:8: expected ')', found ':='"
            if not parsed then
              local stdin_prefix, l, c, msg = line:match("^(.-)[<\\]?standard input>?:(%d+):(%d+):%s*(.+)")
              if stdin_prefix and l and c and msg then
                parsed = {
                  file = default_buf_name ~= "" and default_buf_name or (stdin_prefix ~= "" and stdin_prefix or "<standard input>"),
                  lnum = tonumber(l),
                  col = tonumber(c),
                  msg = msg,
                }
              end
            end

            -- Pattern 3: Windows drive letter paths like "C:\path\to\file.go:11:8: msg" or "C:/path/file.py:11:8: msg"
            if not parsed then
              local drive, rest_f, l, c, msg = line:match("^([a-zA-Z]):[\\/](.-):(%d+):(%d+):%s*(.+)")
              if drive and rest_f and l and c and msg then
                parsed = {
                  file = drive .. ":\\" .. rest_f,
                  lnum = tonumber(l),
                  col = tonumber(c),
                  msg = msg,
                }
              end
            end

            -- Pattern 4: Generic "<file>:<line>:<col>: <msg>"
            if not parsed then
              local f, l, c, msg = line:match("^([^:]+):(%d+):(%d+):%s*(.+)")
              if f and l and c and msg and not f:match("^[a-zA-Z]$") then
                parsed = {
                  file = f,
                  lnum = tonumber(l),
                  col = tonumber(c),
                  msg = msg,
                }
              end
            end

            -- Pattern 5: Prettier SyntaxError: "[error] <file>: SyntaxError: <msg> (<line>:<col>)"
            if not parsed then
              local pf, pmsg, pl, pc = line:match("%[?error%]?%s*([^:]+):%s*(.-)%s*%((%d+):(%d+)%)")
              if pf and pl and pc then
                parsed = {
                  file = pf,
                  lnum = tonumber(pl),
                  col = tonumber(pc),
                  msg = pmsg,
                }
              end
            end

            -- Pattern 6: Python traceback "File "<stdin>", line 10" or "File "foo.py", line 10"
            if not parsed then
              local py_f, py_l = line:match('File "([^"]+)", line (%d+)')
              if py_f and py_l then
                parsed = {
                  file = py_f,
                  lnum = tonumber(py_l),
                  col = 1,
                  msg = line,
                }
              end
            end

            -- Pattern 7: Line without column "<file>:<line>: <msg>"
            if not parsed then
              local f, l, msg = line:match("^([^:]+):(%d+):%s*(.+)")
              if f and l and msg and not f:match("^[a-zA-Z]$") then
                parsed = {
                  file = f,
                  lnum = tonumber(l),
                  col = 1,
                  msg = msg,
                }
              end
            end

            -- Fallback if line has error content
            local l_low = line:lower()
            if not parsed and (l_low:find("error") or l_low:find("fail") or l_low:find("timeout") or l_low:find("timed out") or l_low:find("syntax") or l_low:find("warn")) then
              parsed = {
                file = default_buf_name ~= "" and default_buf_name or "Conform",
                lnum = 1,
                col = 1,
                msg = line,
              }
            end

            if parsed then
              if parsed.file:find("<standard input>") or parsed.file:find("stdin") or parsed.file == "" then
                parsed.file = default_buf_name ~= "" and default_buf_name or parsed.file
              elseif default_buf_name ~= "" and (parsed.file == default_buf_name or default_buf_name:find(parsed.file, 1, true)) then
                parsed.file = default_buf_name
              end
              parsed.formatter = formatter_name
              table.insert(errors, parsed)
            end
          end
        end

        return formatter_name, errors
      end

      --- Clear buffer diagnostics from conform
      local function clear_conform_errors(bufnr)
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          vim.diagnostic.reset(conform_ns, bufnr)
        end
      end

      --- Dispatch conform errors to diagnostics, quickfix list, and notification
      local function handle_conform_errors(err_str, bufnr)
        if not err_str or err_str == "" then return end
        if err_str == "No formatters available for buffer" or err_str:find("No formatters available") or err_str:find("buffer was deleted") then
          return
        end
        local formatter, parsed_errors = parse_formatter_error(err_str, bufnr)

        if #parsed_errors == 0 then
          vim.notify(err_str, vim.log.levels.ERROR, { title = "Conform: " .. formatter })
          return
        end

        local qf_items = {}
        local diagnostics = {}
        local notif_lines = {}

        for _, item in ipairs(parsed_errors) do
          if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            local total_lines = vim.api.nvim_buf_line_count(bufnr)
            local lnum = math.min(math.max(1, item.lnum or 1), total_lines) - 1
            local col = math.max(0, (item.col or 1) - 1)
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = lnum,
              col = col,
              severity = vim.diagnostic.severity.ERROR,
              source = "Conform (" .. formatter .. ")",
              message = item.msg,
            })
          end

          table.insert(qf_items, {
            bufnr = bufnr or 0,
            filename = (item.file ~= "" and item.file ~= "<standard input>") and item.file or (bufnr and vim.api.nvim_buf_get_name(bufnr) or "Conform"),
            lnum = item.lnum or 1,
            col = item.col or 1,
            text = string.format("[%s] %s", formatter, item.msg),
            type = "E",
          })

          table.insert(notif_lines, string.format("  • Line %d:%d: %s", item.lnum or 1, item.col or 1, item.msg))
        end

        -- Publish diagnostics on buffer
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) and #diagnostics > 0 then
          vim.diagnostic.set(conform_ns, bufnr, diagnostics)
        end

        -- Update Quickfix list
        if #qf_items > 0 then
          vim.fn.setqflist(qf_items, "r")
          vim.fn.setqflist({}, "a", { title = "Conform Formatter Errors" })
        end

        -- Show notification with real error details
        local notif_body = string.format("Formatter '%s' failed (%d error%s):\n%s", formatter, #parsed_errors, #parsed_errors > 1 and "s" or "", table.concat(notif_lines, "\n"))
        vim.notify(notif_body, vim.log.levels.ERROR, { title = "Conform: " .. formatter })
      end

      --- Format buffer with error handling
      local function format_buffer(bufnr, opts)
        bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
        opts = opts or {}
        local timeout = vim.fn.has("win32") == 1 and 3000 or 1000
        conform.format(vim.tbl_extend("force", {
          bufnr = bufnr,
          async = false,
          lsp_format = "fallback",
          timeout_ms = timeout,
          quiet = true,
        }, opts), function(err, did_edit)
          if err then
            handle_conform_errors(err, bufnr)
          else
            clear_conform_errors(bufnr)
            if did_edit then
              vim.notify("Formatted buffer successfully", vim.log.levels.INFO, { title = "Conform" })
            end
          end
        end)
      end

      conform.setup({
        formatters_by_ft = {
          javascript = { "oxfmt" },
          typescript = { "oxfmt" },
          javascriptreact = { "oxfmt" },
          typescriptreact = { "oxfmt" },
          css = { "oxfmt" },
          html = { "oxfmt" },
          json = { "oxfmt" },
          yaml = { "oxfmt" },
          markdown = { "oxfmt" },
          python = { "ruff_format" },
          c = { "clang-format" },
          cpp = { "clang-format" },
          rust = { "rustfmt" },
          go = { "gofmt" },
          java = { "google-java-format" },
          toml = { "taplo" },
        },
        notify_on_error = false,
        format_on_save = function(bufnr)
          local timeout = vim.fn.has("win32") == 1 and 3000 or 1000
          return {
            timeout_ms = timeout,
            lsp_format = "fallback",
            quiet = true,
          }, function(err)
            if err then
              handle_conform_errors(err, bufnr)
            else
              clear_conform_errors(bufnr)
            end
          end
        end,
        formatters = {
          oxfmt = {
            command = "oxfmt",
            args = { "--stdin-filepath", "$FILENAME" },
            stdin = true,
          },
          ruff_format = { prepend_args = { "--config", 'format.indent-style="tab"', "--config", "indent-width=4" } },
          ["clang-format"] = { prepend_args = { "-style={UseTab: Always, TabWidth: 4, IndentWidth: 4}" } },
          rustfmt = { prepend_args = { "--config", "hard_tabs=true,tab_spaces=4" } },
        },
      })

      -- Interactive navigation inside :ConformInfo floating window
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "conform-info",
        desc = "ConformInfo interactive error navigation & quickfix export",
        callback = function(args)
          local buf = args.buf
          -- Press <CR> on any error line in ConformInfo to jump to the source file & line
          vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            local _, parsed = parse_formatter_error(line, nil)
            if parsed and #parsed > 0 then
              local item = parsed[1]
              if item.file and item.file ~= "" and item.file ~= "Conform" and item.file ~= "<standard input>" then
                vim.cmd("close")
                vim.cmd("edit " .. vim.fn.fnameescape(item.file))
                pcall(vim.api.nvim_win_set_cursor, 0, { math.max(1, item.lnum or 1), math.max(0, (item.col or 1) - 1) })
              else
                vim.notify("Cannot jump: file path is stdin or not specified", vim.log.levels.WARN, { title = "ConformInfo" })
              end
            else
              vim.notify("No error line found under cursor", vim.log.levels.INFO, { title = "ConformInfo" })
            end
          end, { buffer = buf, silent = true, desc = "Jump to error under cursor" })

          -- Press 'E' in ConformInfo to load all errors into Quickfix
          vim.keymap.set("n", "E", function()
            local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local content = table.concat(buf_lines, "\n")
            local _, parsed = parse_formatter_error(content, nil)
            if #parsed > 0 then
              local qf_list = {}
              for _, it in ipairs(parsed) do
                table.insert(qf_list, {
                  filename = (it.file ~= "" and it.file ~= "<standard input>") and it.file or "Conform",
                  lnum = it.lnum or 1,
                  col = it.col or 1,
                  text = string.format("[%s] %s", it.formatter or "formatter", it.msg),
                  type = "E",
                })
              end
              vim.fn.setqflist(qf_list, "r")
              vim.fn.setqflist({}, "a", { title = "ConformInfo Errors (" .. #qf_list .. ")" })
              vim.cmd("copen")
              vim.notify(string.format("Exported %d errors to Quickfix", #qf_list), vim.log.levels.INFO, { title = "ConformInfo" })
            else
              vim.notify("No error lines found in ConformInfo", vim.log.levels.INFO, { title = "ConformInfo" })
            end
          end, { buffer = buf, silent = true, desc = "Export all errors to Quickfix" })
        end,
      })

      -- User Command: Format current buffer or visual selection
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line and end_line:len() or 0 },
          }
        end
        format_buffer(0, { range = range })
      end, { range = true, desc = "Format buffer or selection with Conform error handling" })

      -- User Command: Load recent conform.log errors into Quickfix list
      vim.api.nvim_create_user_command("ConformErrors", function()
        local log = require("conform.log")
        local logfile = log.get_logfile()
        if vim.fn.filereadable(logfile) ~= 1 then
          vim.notify("No conform.log found at: " .. logfile, vim.log.levels.INFO, { title = "Conform" })
          return
        end
        local f = io.open(logfile, "r")
        if not f then
          vim.notify("Failed to open conform.log", vim.log.levels.ERROR, { title = "Conform" })
          return
        end
        local content = f:read("*a")
        f:close()

        local curr_buf = vim.api.nvim_get_current_buf()
        local _, parsed = parse_formatter_error(content, curr_buf)
        if #parsed == 0 then
          vim.notify("No errors found in conform.log", vim.log.levels.INFO, { title = "Conform" })
          return
        end

        local qf_list = {}
        for _, it in ipairs(parsed) do
          table.insert(qf_list, {
            filename = (it.file ~= "" and it.file ~= "<standard input>") and it.file or (curr_buf and vim.api.nvim_buf_get_name(curr_buf) or "Conform"),
            lnum = it.lnum or 1,
            col = it.col or 1,
            text = string.format("[%s] %s", it.formatter or "formatter", it.msg),
            type = "E",
          })
        end

        vim.fn.setqflist(qf_list, "r")
        vim.fn.setqflist({}, "a", { title = "Conform Log Errors (" .. #qf_list .. ")" })
        vim.cmd("copen")
      end, { desc = "Load errors from conform.log into Quickfix list" })

      -- Keymaps for formatting and error inspection
      vim.keymap.set({ "n", "v" }, "<leader>cf", function() vim.cmd("Format") end, { noremap = true, silent = true, desc = "Conform: Format Buffer" })
      vim.keymap.set("n", "<leader>ce", "<cmd>ConformErrors<CR>", { noremap = true, silent = true, desc = "Conform: View Formatter Errors (Quickfix)" })
    end,
  },

  -- Next-Gen High Performance Autocompletion Engine (Rust SIMD-accelerated fuzzy matching)
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<Up>"] = { "fallback" },
        ["<Down>"] = { "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        menu = {
          border = "rounded",
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = "rounded",
          },
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "rounded",
        },
      },
    },
    opts_extend = { "sources.default" },
  },


  -- Diagnostics & Errors Panel
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { modes = { diagnostics = { auto_preview = true } } },
    keys = {
      {
        "<leader>xx",
        function()
          local trouble = require("trouble")
          if trouble.is_open() then
            trouble.close()
            return
          end

          local diags = vim.diagnostic.get(0)
          if #diags == 0 then
            vim.notify("No diagnostics in active file", vim.log.levels.INFO, { title = "Diagnostics" })
            return
          end

          trouble.open({ mode = "diagnostics", focus = true })
        end,
        desc = "Diagnostics / Errors (Trouble)",
      },
    },
  },

  -- =========================================================================
  -- DEBUG ADAPTER PROTOCOL (DAP) & GO DEBUGGING (Delve)
  -- =========================================================================
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      "theHamsta/nvim-dap-virtual-text",
      "leoluz/nvim-dap-go",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local dap_go = require("dap-go")
      local dap_vt = require("nvim-dap-virtual-text")

      -- Setup inline virtual text for variable inspection during debugging
      dap_vt.setup({
        commented = true,
        highlight_changed_variables = true,
        show_stop_reason = true,
      })

      -- Setup DAP UI with rich debugger layout
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
        floating = {
          border = "rounded",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
      })

      -- Helper to find the actual delve binary executable (handles Windows vs Unix, GOPATH, ~/go/bin, and system PATH)
      local function get_delve_path()
        local is_win = vim.fn.has("win32") == 1
        local ext = is_win and ".exe" or ""

        -- 1. Check ~/go/bin
        local go_bin = vim.fs.joinpath(vim.fn.expand("~/go/bin"), "dlv" .. ext)
        if vim.uv.fs_stat(go_bin) then
          return go_bin
        end

        -- 3. Check GOPATH/bin if set
        if vim.env.GOPATH then
          local gopath_bin = vim.fs.joinpath(vim.env.GOPATH, "bin", "dlv" .. ext)
          if vim.uv.fs_stat(gopath_bin) then
            return gopath_bin
          end
        end

        -- 4. Check system exepath (if it's an .exe or binary directly)
        local sys_path = vim.fn.exepath("dlv" .. ext)
        if sys_path ~= "" and not sys_path:lower():match("%.cmd$") and not sys_path:lower():match("%.bat$") then
          return sys_path
        end

        -- 5. Fallback
        return is_win and "dlv.exe" or "dlv"
      end

      -- Helper to detect Go project / module root (where go.mod or .git resides)
      local function get_go_project_root(bufnr)
        local buf_name = bufnr and vim.api.nvim_buf_get_name(bufnr) or vim.api.nvim_buf_get_name(0)
        local start_dir = (buf_name ~= "") and vim.fs.dirname(buf_name) or vim.fn.getcwd()
        local root = vim.fs.root(start_dir, { "go.mod", "go.work", ".git" })
        return root or start_dir
      end

      -- Sanitize Windows path artifacts like "./C:/..." produced by treesitter test runner
      local function sanitize_go_program_path(prog)
        if not prog or prog == "" or prog == "${file}" or prog == "${fileDirname}" then
          return prog
        end
        prog = prog:gsub("^%./([a-zA-Z]:)", "%1"):gsub("^%.\\([a-zA-Z]:)", "%1")
        return prog
      end

      -- Setup DAP for Go (delve integration)
      dap_go.setup({
        dap_configurations = {
          {
            type = "go",
            name = "Attach remote",
            mode = "remote",
            request = "attach",
          },
        },
        delve = {
          path = get_delve_path(),
          initialize_timeout_sec = 20,
          port = "${port}",
          args = {},
          build_flags = "",
          detached = vim.fn.has("win32") == 0,
        },
      })

      -- Directly configure DAP adapter for Go with dynamic root and Delve binary resolution
      dap.adapters.go = function(callback, client_config)
        local dlv_path = get_delve_path()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local start_dir = (buf_name ~= "") and vim.fs.dirname(buf_name) or vim.fn.getcwd()
        local root = (client_config and client_config.cwd) or vim.fs.root(start_dir, { "go.mod", "go.work", ".git" }) or start_dir

        if client_config then
          if not client_config.cwd then
            client_config.cwd = root
          end
          if client_config.program then
            client_config.program = sanitize_go_program_path(client_config.program)
          end
        end

        callback({
          type = "server",
          port = "${port}",
          executable = {
            command = dlv_path,
            args = { "dap", "-l", "127.0.0.1:${port}" },
            cwd = root,
            detached = vim.fn.has("win32") == 0,
          },
          options = {
            initialize_timeout_sec = 20,
          },
        })
      end

      -- Open UI automatically when debug session starts
      -- Kept open after execution terminates so variables & stack traces can be inspected
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      -- Custom signs & highlights for breakpoints and execution pointer
      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "🔘", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    end,
  },



  -- Inline Jupyter Notebook Cell Outputs & Execution (Molten)
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    lazy = false,
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_virt_lines = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_auto_open_output = false
      vim.g.molten_cover_empty_lines = true
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<CR>", desc = "Initialize Jupyter Kernel" },
      { "<leader>rc", "<cmd>MoltenEvaluateCell<CR>", desc = "Evaluate Cell Inline" },
      { "<leader>rd", "<cmd>MoltenDelete<CR>", desc = "Delete Cell Output" },
      { "<leader>ro", "<cmd>MoltenShowOutput<CR>", desc = "Show Output Float Window" },
      { "<leader>rr", "<cmd>MoltenReevaluateCell<CR>", desc = "Re-evaluate Cell" },
      { "<leader>r", ":<C-u>MoltenEvaluateVisual<CR>", mode = "v", desc = "Evaluate Visual Selection Inline" },
    },
  },

  { "echasnovski/mini.bufremove", version = "*", config = function() require("mini.bufremove").setup() end },
  { "mechatroner/rainbow_csv", event = "BufRead" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        }
      })
    end,
  },
  { "echasnovski/mini.pairs", version = "*", config = function() require("mini.pairs").setup() end },
  { "folke/which-key.nvim", event = "VeryLazy", config = function() require("which-key").setup({ delay = 500, win = { border = "rounded" } }) end },
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup({ current_line_blame = true, current_line_blame_opts = { delay = 500, virt_text_pos = 'eol' } }) end },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20, open_mapping = [[<c-\>]], direction = "float", shade_terminals = false, float_opts = { border = "curved" },
        on_open = function(term)
          if _G.Update_Term_Winbar then _G.Update_Term_Winbar(term.window) end
          vim.cmd("startinsert!")
        end,
      })
    end,
  },

  -- Inline Image Viewer (Kitty Graphics Protocol)
  {
    "3rd/image.nvim",
    event = "VeryLazy",
    config = function()
      require("image").setup({
        backend = "kitty",
        processor = "magick_cli",
        max_width_window_percentage = 90,
        max_height_window_percentage = 80,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = { "blink-cmp-menu", "blink-cmp-documentation", "aerial", "NvimTree", "" },
        ignore_download_error = true,
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif", "*.bmp", "*.tiff", "*.ico", "*.svg" },
      })
    end,
  },

  -- Modern In-Buffer Markdown Renderer (Ghostty & Kitty Protocol Compatible)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = {
        enabled = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      checkbox = { enabled = true },
      bullet = { enabled = true },
    },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<CR>", ft = "markdown", desc = "Toggle Markdown Render" },
    },
  },

  -- =========================================================================
  -- AESTHETICS & MOTION UPGRADES
  -- =========================================================================

  -- Smooth Animated Cursor Smear
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      cursor_color = "#7aa2f7",
      stiffness = 0.8,
      trailing_stiffness = 0.5,
    },
  },

  -- Rounded Floating UI Inputs & Select Dialogs
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = { 
        border = "rounded",
        mappings = {
          n = { ["<Esc>"] = "Close", ["<CR>"] = "Confirm" },
          i = { ["<Esc>"] = "Close", ["<CR>"] = "Confirm", ["<Up>"] = "HistoryPrev", ["<Down>"] = "HistoryNext" },
        }
      },
      select = { backend = { "telescope", "builtin" }, builtin = { border = "rounded" } },
    },
  },

  -- Animated Scope & Indent Guides
  {
    "echasnovski/mini.indentscope",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      symbol = "│",
      options = { try_as_border = true },
    },
    config = function(_, opts)
      require("mini.indentscope").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "alpha",
          "dashboard",
          "fzf",
          "help",
          "lazy",
          "mason",
          "neo-tree",
          "NvimTree",
          "notify",
          "toggleterm",
          "trouble",
          "checkhealth",
          "aerial",
          "dapui_scopes",
          "dapui_breakpoints",
          "dapui_stacks",
          "dapui_watches",
          "dapui_console",
          "dap-repl",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },

  -- IDE Breadcrumb Navigation Winbar
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },

  -- Modern Floating Cmdline, Notifications & Messages
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.styled_parts"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },

  -- Real-Time Color Code Swatches
  {
    "brenoprata10/nvim-highlight-colors",
    event = "BufReadPre",
    opts = {
      render = "background",
      enable_named_colors = true,
      enable_tail_wind = true,
    },
  },


  -- Sleek Diagnostic & Git Scrollbar
  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPre",
    opts = {
      handlers = {
        cursor = true,
        diagnostic = true,
        gitsigns = true,
        search = false,
      },
    },
  },

}, {
  checker = { enabled = true, notify = false, frequency = 86400 },
  change_detection = { notify = false },
  rocks = { enabled = false }
})

-- =========================================================================
-- 3. LSP CONFIGURATION 
-- =========================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config("*", { capabilities = capabilities })

-- TypeScript / JavaScript LSP (vtsls - High-performance VS Code TypeScript Language Service)
vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
})

-- Oxc / Oxlint LSP (Fast Rust-based Linter with LSP mode)
vim.lsp.config("oxlint", {
  cmd = { "oxlint", "--lsp" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
  root_markers = {
    ".oxlintrc.json",
    ".oxlintrc.jsonc",
    "oxlint.config.ts",
    "package.json",
    ".git",
  },
})

vim.lsp.config("clangd", { cmd = { "clangd" }, filetypes = { "c", "cpp", "objc", "objcpp" } })
local basedpyright_analysis = {
  autoSearchPaths = true,
  useLibraryCodeForTypes = true,
  diagnosticMode = "openFilesOnly",
  typeCheckingMode = "standard",
  reportMissingTypeStubs = "none",
  reportUnknownMemberType = "none",
  reportUnusedCallResult = "none",
  reportUnknownArgumentType = "none",
  reportUnknownVariableType = "none",
}

vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".venv", ".git" },
  before_init = function(_, config)
    local root = config.root_dir or _G._project_root or vim.fn.getcwd()
    local venv = vim.fs.joinpath(root, ".venv")
    if vim.fn.isdirectory(venv) == 1 then
      local is_win = vim.fn.has("win32") == 1
      local py_candidates = {
        vim.fs.joinpath(venv, "Scripts", "python.exe"),
        vim.fs.joinpath(venv, "bin", "python"),
        vim.fs.joinpath(venv, "Scripts", "python"),
        vim.fs.joinpath(venv, "bin", "python.exe"),
      }
      local python_path = is_win and py_candidates[1] or py_candidates[2]
      for _, cand in ipairs(py_candidates) do
        if vim.uv.fs_stat(cand) then
          python_path = cand
          break
        end
      end

      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = python_path
      config.settings.python.venvPath = root
      config.settings.python.venv = ".venv"
    end
  end,
  settings = {
    basedpyright = {
      analysis = basedpyright_analysis,
    },
    python = {
      analysis = basedpyright_analysis,
    },
  },
})
vim.lsp.config("rust_analyzer", { cmd = { "rust-analyzer" }, filetypes = { "rust" }, settings = { ["rust-analyzer"] = { checkOnSave = true, check = { command = "check" }, cargo = { allFeatures = true } } } })

-- Go LSP (Resolved to native GOPATH binary to avoid Windows Device Guard blocking Mason AppData package)
local function get_gopls_cmd()
  local candidates = {
    vim.fn.expand("~/go/bin/gopls.exe"),
    vim.fn.expand("~/go/bin/gopls"),
    "C:\\Program Files\\Go\\bin\\gopls.exe",
    "gopls",
  }
  for _, cand in ipairs(candidates) do
    if vim.fn.filereadable(cand) == 1 or cand == "gopls" then
      return { cand }
    end
  end
  return { "gopls" }
end

vim.lsp.config("gopls", {
  cmd = get_gopls_cmd(),
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  settings = {
    gopls = { completeUnimported = true, usePlaceholders = true, analyses = { unusedparams = true, unusedvariable = true, unusedwrite = true }, semanticTokens = true },
  },
})

-- Java LSP
vim.lsp.config("jdtls", {
  cmd = { "jdtls" },
  filetypes = { "java" },
  root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git", "settings.gradle", "settings.gradle.kts" },
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
        },
        filteredTypes = { "com.sun.*", "io.micrometer.shaded.*", "java.awt.*", "jdk.*", "sun.*" },
      },
      sources = {
        organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
      },
    },
  },
})

-- LaTeX LSP
vim.lsp.config("texlab", {
  cmd = { "texlab" },
  filetypes = { "tex", "plaintex", "bib" },
})

vim.lsp.enable("vtsls")
vim.lsp.enable("oxlint")
vim.lsp.enable("clangd")
vim.lsp.enable("basedpyright")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("jdtls")
vim.lsp.enable("texlab")
vim.lsp.enable("taplo")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }
    
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, { buffer = bufnr, silent = true, desc = "LSP Go to Definition" })

    local function show_references()
      local ok, builtin = pcall(require, "telescope.builtin")
      if ok then
        builtin.lsp_references({ show_line = true })
      else
        vim.lsp.buf.references()
      end
    end

    vim.keymap.set("n", "gr", show_references, { buffer = bufnr, silent = true, desc = "LSP Go to References (Telescope)" })
    vim.keymap.set("n", "gh", vim.lsp.buf.hover, { buffer = bufnr, silent = true, desc = "LSP Hover Documentation" })
    vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { buffer = bufnr, silent = true, desc = "LSP Hover Documentation" })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, silent = true, desc = "Code Action" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, silent = true, desc = "Rename Symbol" })
  end,
})

-- =========================================================================
-- 4. CORE EDITOR SETTINGS
-- =========================================================================
vim.opt.termguicolors = true
vim.opt.number = true        
vim.opt.relativenumber = true 
vim.opt.signcolumn = "yes"   
vim.opt.tabstop = 4          
vim.opt.shiftwidth = 4
vim.opt.expandtab = false 
vim.opt.guicursor = "a:blinkon0" 
vim.opt.confirm = true
vim.opt.clipboard = "unnamedplus"
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "key,mouse"
vim.opt.ignorecase = true  
vim.opt.smartcase = true   
vim.opt.updatetime = 300   -- Fast CursorHold trigger for diagnostic popups
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal" } -- Exclude 'blank' to avoid saving empty/untitled placeholder windows

vim.diagnostic.config({
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = { " Diagnostics", "Bold" },
    prefix = function(diagnostic)
      if diagnostic.severity == vim.diagnostic.severity.ERROR then
        return "󰅚 ", "DiagnosticSignError"
      elseif diagnostic.severity == vim.diagnostic.severity.WARN then
        return "󰀦 ", "DiagnosticSignWarn"
      elseif diagnostic.severity == vim.diagnostic.severity.INFO then
        return "󰋼 ", "DiagnosticSignInfo"
      else
        return "󰌵 ", "DiagnosticSignHint"
      end
    end,
  },
  virtual_text = { severity = vim.diagnostic.severity.ERROR },
  signs = true,
  underline = true,
  update_in_insert = false,
})

-- Auto-show floating diagnostic popup ONLY when cursor rests on a line with errors/warnings
vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype
    if ft == "" or ft == "NvimTree" or ft == "aerial" or ft == "toggleterm" or ft == "trouble" or ft == "alpha" or ft == "lazy" or ft == "mason" or ft:find("^dap") then
      return
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diagnostics = vim.diagnostic.get(0, { lnum = lnum })

    if #diagnostics > 0 then
      vim.diagnostic.open_float(nil, {
        focus = false,
        scope = "line",
      })
    end
  end,
})

-- =========================================================================
-- JUPYTEXT (.ipynb <-> .py) AUTOMATIC CONVERSION
-- =========================================================================
local jupytext_group = vim.api.nvim_create_augroup("JupytextSync", { clear = true })

local function get_jupytext_cmd(sub_args)
  local local_bin = vim.fn.expand("~/.local/bin/jupytext")
  local cmd = {}
  if vim.fn.executable("jupytext") == 1 then
    table.insert(cmd, "jupytext")
  elseif vim.fn.executable(local_bin) == 1 then
    table.insert(cmd, local_bin)
  elseif vim.fn.executable("uvx") == 1 then
    table.insert(cmd, "uvx")
    table.insert(cmd, "jupytext")
  else
    table.insert(cmd, local_bin)
  end
  for _, arg in ipairs(sub_args) do
    table.insert(cmd, arg)
  end
  return cmd
end

local function get_nbconvert_cmd(file)
  local local_bin = vim.fn.expand("~/.local/bin/jupyter")
  if vim.fn.executable("jupyter") == 1 then
    return { "jupyter", "nbconvert", "--to", "notebook", "--nbformat", "4", "--inplace", file }
  elseif vim.fn.executable(local_bin) == 1 then
    return { local_bin, "nbconvert", "--to", "notebook", "--nbformat", "4", "--inplace", file }
  elseif vim.fn.executable("jupyter-nbconvert") == 1 then
    return { "jupyter-nbconvert", "--to", "notebook", "--nbformat", "4", "--inplace", file }
  elseif vim.fn.executable("uvx") == 1 then
    return { "uvx", "--from", "nbconvert", "jupyter-nbconvert", "--to", "notebook", "--nbformat", "4", "--inplace", file }
  else
    return { "jupyter", "nbconvert", "--to", "notebook", "--nbformat", "4", "--inplace", file }
  end
end

vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
  group = jupytext_group,
  pattern = "*.ipynb",
  callback = function(args)
    local file = args.file
    local cmd = get_jupytext_cmd({ "--to", "py:percent", "--output", "-", file })
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or out == "" then
      local fname = vim.fn.fnamemodify(file, ":t")
      vim.notify("Jupytext failed to convert " .. fname .. ":\n" .. (out ~= "" and out or "Empty output"), vim.log.levels.WARN)

      vim.schedule(function()
        local nb_cmd_display = 'jupyter nbconvert --to notebook --nbformat 4 --inplace "' .. fname .. '"'
        local options = {
          "Run: " .. nb_cmd_display,
          "Cancel"
        }

        vim.ui.select(options, {
          prompt = "[Jupytext Error] Format version incompatible.\nPress ENTER to run nbconvert, ESC to cancel:",
        }, function(choice, idx)
          if idx == 1 then
            local conv_cmd = get_nbconvert_cmd(file)
            vim.notify("Upgrading notebook format for " .. fname .. "...", vim.log.levels.INFO)
            local conv_out = vim.fn.system(conv_cmd)
            if vim.v.shell_error == 0 then
              vim.notify("Successfully upgraded " .. fname .. " to nbformat 4! Reloading...", vim.log.levels.INFO)
              local retry_cmd = get_jupytext_cmd({ "--to", "py:percent", "--output", "-", file })
              local retry_out = vim.fn.system(retry_cmd)
              if vim.v.shell_error == 0 and retry_out ~= "" then
                local lines = vim.split(retry_out, "\n", { trimempty = false })
                if vim.api.nvim_buf_is_valid(args.buf) then
                  vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
                  vim.bo[args.buf].filetype = "python"
                  vim.bo[args.buf].modified = false
                end
              else
                vim.notify("Jupytext conversion failed after upgrade: " .. retry_out, vim.log.levels.ERROR)
              end
            else
              vim.notify("nbconvert failed:\n" .. conv_out, vim.log.levels.ERROR)
            end
          else
            vim.notify("Notebook format upgrade cancelled.", vim.log.levels.WARN)
          end
        end)
      end)
      return
    end

    local raw_lines = vim.split(out, "\n", { trimempty = false })
    local lines = {}
    local in_frontmatter = false
    for i, line in ipairs(raw_lines) do
      if i == 1 and line == "# ---" then
        in_frontmatter = true
      elseif in_frontmatter and line == "# ---" then
        in_frontmatter = false
      elseif not in_frontmatter then
        table.insert(lines, line)
      end
    end
    while #lines > 0 and lines[1] == "" do
      table.remove(lines, 1)
    end

    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
    vim.bo[args.buf].filetype = "python"
    vim.bo[args.buf].modified = false
  end,
})

vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
  group = jupytext_group,
  pattern = "*.ipynb",
  callback = function(args)
    local file = args.file
    local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    local cmd = get_jupytext_cmd({ "--from", "py:percent", "--to", "ipynb", "--output", file, "-" })
    local out = vim.fn.system(cmd, content)
    if vim.v.shell_error ~= 0 then
      vim.notify("Jupytext failed to save " .. file .. ": " .. out, vim.log.levels.ERROR)
      return
    end
    vim.bo[args.buf].modified = false
  end,
})

-- Rounded borders for LSP floating windows
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
  config = config or {}
  config.border = "rounded"
  return vim.lsp.handlers.hover(err, result, ctx, config)
end

vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
  config = config or {}
  config.border = "rounded"
  return vim.lsp.handlers.signature_help(err, result, ctx, config)
end

-- =========================================================================
-- 5. CUSTOM KEYBINDINGS & COMMANDS
-- =========================================================================

-- Utility Command: Clear Telescope Project History
vim.api.nvim_create_user_command("ClearProjects", function()
  local history_file = vim.fn.stdpath("data") .. "/project_nvim/project_history"
  os.remove(history_file)
  print("Project history cleared. (Restart Neovim to reflect changes)")
end, { desc = "Wipe the recent projects list from Telescope" })

-- Utility Command: Asynchronously delete file or folder in background (:AsyncDelete [path])
vim.api.nvim_create_user_command("AsyncDelete", function(opts)
  local path = (opts.args ~= "") and vim.fn.expand(opts.args) or vim.api.nvim_buf_get_name(0)
  if not path or path == "" then
    vim.notify("No file or path specified to delete", vim.log.levels.WARN, { title = "Async Delete" })
    return
  end
  local name = vim.fn.fnamemodify(path, ":t")
  local is_dir = vim.fn.isdirectory(path) == 1
  local prompt_msg = string.format("Delete %s '%s' in background? [y/N]: ", is_dir and "folder" or "file", name)
  vim.ui.input({ prompt = prompt_msg }, function(choice)
    if choice and (choice:lower() == "y" or choice:lower() == "yes") then
      if _G.Async_Delete_Path then
        _G.Async_Delete_Path(path, function()
          local status_tree, tree_api = pcall(require, "nvim-tree.api")
          if status_tree then pcall(tree_api.tree.reload) end
        end)
      end
    end
  end)
end, { nargs = "?", complete = "file", desc = "Delete file or directory asynchronously in background" })

-- Search Upgrades
vim.keymap.set('n', '/', '/\\V', { noremap = true, desc = "Literal Search Forward" })
vim.keymap.set('v', '/', '/\\V', { noremap = true, desc = "Literal Search Forward" })
vim.keymap.set('n', '?', '?\\V', { noremap = true, desc = "Literal Search Backward" })
vim.keymap.set('v', '?', '?\\V', { noremap = true, desc = "Literal Search Backward" })

-- Telescope File Finders
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-f>', builtin.current_buffer_fuzzy_find, { noremap = true, silent = true, desc = "Fuzzy Find in File" })
vim.keymap.set('n', '<leader>f', builtin.find_files, { noremap = true, silent = true, desc = "Find Files" })
vim.keymap.set('n', '<leader>F', builtin.live_grep, { noremap = true, silent = true, desc = "Find Text" })
vim.keymap.set('n', '<leader>fb', function()
  require('telescope').extensions.file_browser.file_browser({
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Ctrl+o: Open the CURRENT browsed directory as the project root
      local open_as_project = function()
        local finder = action_state.get_current_picker(prompt_bufnr).finder
        local dir = finder.path
        if not dir then return end
        actions.close(prompt_bufnr)
        
        -- Detach from current session to prevent overwriting it
        vim.v.this_session = ""
        
        _G._project_root = dir
        vim.cmd("cd " .. vim.fn.fnameescape(dir))
        vim.cmd("NvimTreeOpen " .. vim.fn.fnameescape(dir))
        local scratch_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(scratch_buf)
      end

      map("i", "<C-o>", open_as_project)
      map("n", "<C-o>", open_as_project)
      return true -- keep all default mappings
    end,
  })
end, { noremap = true, silent = true, desc = "Directory Browser (Ctrl+o to open as project)" })

-- =========================================================================
-- DEBUGGING KEYMAPS (DAP / Delve)
-- =========================================================================
vim.keymap.set('n', '<leader>dc', function() require('dap').continue() end, { noremap = true, silent = true, desc = "Debug: Start / Continue" })
vim.keymap.set('n', '<leader>db', function() require('dap').toggle_breakpoint() end, { noremap = true, silent = true, desc = "Debug: Toggle Breakpoint" })
vim.keymap.set('n', '<leader>dB', function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
    if condition and condition ~= "" then
      require('dap').set_breakpoint(condition)
    end
  end)
end, { noremap = true, silent = true, desc = "Debug: Conditional Breakpoint" })
vim.keymap.set('n', '<leader>dn', function() require('dap').step_over() end, { noremap = true, silent = true, desc = "Debug: Step Over (Next)" })
vim.keymap.set('n', '<leader>di', function() require('dap').step_into() end, { noremap = true, silent = true, desc = "Debug: Step Into" })
vim.keymap.set('n', '<leader>do', function() require('dap').step_out() end, { noremap = true, silent = true, desc = "Debug: Step Out" })
vim.keymap.set('n', '<leader>dt', function()
  local ft = vim.bo.filetype
  if ft ~= "go" then
    vim.notify("Not a Go buffer", vim.log.levels.WARN)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local file_dir = vim.fs.dirname(file_path)
  local root = vim.fs.root(file_dir, { "go.mod", "go.work", ".git" }) or file_dir
  local rel_dir = "."
  if file_dir ~= root and file_dir:sub(1, #root) == root then
    rel_dir = "./" .. file_dir:sub(#root + 2):gsub("\\", "/")
  end
  local dap_go = require("dap-go")
  local ok = dap_go.debug_test({
    program = rel_dir,
    cwd = root,
  })
  if not ok then
    require("dap").run({
      type = "go",
      name = "Debug Test (Package)",
      request = "launch",
      mode = "test",
      program = rel_dir,
      cwd = root,
      outputMode = "remote",
    })
  end
end, { noremap = true, silent = true, desc = "Debug: Go Test Under Cursor" })
vim.keymap.set('n', '<leader>dT', function() require('dap-go').debug_last_test() end, { noremap = true, silent = true, desc = "Debug: Last Go Test" })
vim.keymap.set('n', '<leader>dq', function()
  require('dap').terminate()
  require('dapui').close()
end, { noremap = true, silent = true, desc = "Debug: Terminate & Close UI" })
vim.keymap.set('n', '<leader>du', function() require('dapui').toggle() end, { noremap = true, silent = true, desc = "Debug: Toggle DAP UI" })
vim.keymap.set('n', '<leader>dr', function() require('dap').repl.toggle() end, { noremap = true, silent = true, desc = "Debug: Toggle REPL" })
vim.keymap.set({ 'n', 'v' }, '<leader>de', function() require('dapui').eval() end, { noremap = true, silent = true, desc = "Debug: Evaluate Expression" })

-- =========================================================================
-- THE NEW PROJECT / SESSION WORKFLOW
-- =========================================================================
vim.keymap.set('n', '<leader>p', ':AutoSession search<CR>', { noremap = true, silent = true, desc = "Active Projects (Restore Tabs)" })
vim.keymap.set('n', '<leader>fp', ':Telescope projects<CR>', { noremap = true, silent = true, desc = "Find New Project Folders" })

-- THE SIDEBAR (Aerial Code Outline)
vim.keymap.set("n", "<leader>a", function()
  -- If we're in a sidebar, switch to the code window first
  local ft = vim.bo.filetype
  if ft == "NvimTree" or ft == "aerial" or ft == "toggleterm" or ft == "trouble" then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local wft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and wft ~= "NvimTree" and wft ~= "aerial" and wft ~= "toggleterm" and wft ~= "trouble" and wft ~= "alpha" then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
  end

  local aerial = require("aerial")
  if aerial.is_open() then
    -- User is manually closing — stays closed until explicitly reopened
    _G._aerial_user_closed = true
    aerial.close()
  else
    -- User is manually opening — clear the global flag
    _G._aerial_user_closed = false
    aerial.open({ focus = false })
  end
end, { noremap = true, silent = true, desc = "Toggle Code Structure Sidebar" })

-- =========================================================================
-- RETURN TO DASHBOARD (Home)
-- =========================================================================
vim.keymap.set('n', '<leader>h', function()
  if vim.bo.filetype == "alpha" then return end
  pcall(function() require("aerial").close() end)
  pcall(function() require("nvim-tree.api").tree.close() end)
  vim.cmd("silent! wall") -- Save all modified buffers first
  -- Reset cwd to the tracked project root before saving
  if _G._project_root and vim.fn.isdirectory(_G._project_root) == 1 then
    vim.cmd("cd " .. vim.fn.fnameescape(_G._project_root))
  end
  vim.cmd("AutoSession save") -- Save current session
  for _, client in ipairs(vim.lsp.get_clients()) do client:stop() end -- Stop LSP servers on return to dashboard (comment out to keep servers running)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
      vim.cmd("bdelete! " .. bufnr)
    end
  end
  vim.v.this_session = "" -- Clear session to prevent overwriting on next project
  vim.cmd("Alpha") -- Open Dashboard
end, { noremap = true, silent = true, desc = "Save & Return to Dashboard" })


-- Cycle Focus: Forward and Reverse between NvimTree, Active File, and Aerial (Code Structure)
local function cycle_panel_focus(reverse)
  local current_ft = vim.bo.filetype

  -- Helper: find the first normal (non-sidebar) code window
  local function find_code_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and ft ~= "NvimTree" and ft ~= "aerial" and ft ~= "toggleterm" and ft ~= "trouble" and ft ~= "alpha" then
        return win
      end
    end
    return nil
  end

  -- Helper: find the aerial window (if open)
  local function find_aerial_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and ft == "aerial" then
        return win
      end
    end
    return nil
  end

  local aerial_win = find_aerial_win()
  local code_win = find_code_win()

  if reverse then
    -- Reverse direction: NvimTree -> Aerial -> Code -> NvimTree
    if current_ft == "NvimTree" then
      if aerial_win then
        vim.api.nvim_set_current_win(aerial_win)
      elseif code_win then
        vim.api.nvim_set_current_win(code_win)
      end
    elseif current_ft == "aerial" then
      if code_win then
        vim.api.nvim_set_current_win(code_win)
      else
        vim.cmd("wincmd p")
      end
    else
      vim.cmd("NvimTreeFocus")
    end
  else
    -- Forward direction: NvimTree -> Code -> Aerial -> NvimTree
    if current_ft == "NvimTree" then
      if code_win then
        vim.api.nvim_set_current_win(code_win)
      else
        vim.cmd("wincmd p")
      end
    elseif current_ft == "aerial" then
      vim.cmd("NvimTreeFocus")
    else
      if aerial_win then
        vim.api.nvim_set_current_win(aerial_win)
      else
        vim.cmd("NvimTreeFocus")
      end
    end
  end
end

vim.keymap.set({'n', 'i', 'v'}, '<C-M-e>', function() cycle_panel_focus(false) end, { noremap = true, silent = true, desc = "Cycle Focus Forward: File -> Structure -> Tree" })
vim.keymap.set({'n', 'i', 'v'}, '<C-M-S-e>', function() cycle_panel_focus(true) end, { noremap = true, silent = true, desc = "Cycle Focus Reverse: File -> Tree -> Structure" })
vim.keymap.set({'n', 'i', 'v'}, '<C-A-S-e>', function() cycle_panel_focus(true) end, { noremap = true, silent = true, desc = "Cycle Focus Reverse: File -> Tree -> Structure" })

-- Clean fallback shortcuts (Alt+e / Alt+Shift+e) for terminals that don't pass Ctrl+Alt+Shift
vim.keymap.set({'n', 'i', 'v'}, '<M-e>', function() cycle_panel_focus(false) end, { noremap = true, silent = true, desc = "Cycle Focus Forward: File -> Structure -> Tree" })
vim.keymap.set({'n', 'i', 'v'}, '<M-S-e>', function() cycle_panel_focus(true) end, { noremap = true, silent = true, desc = "Cycle Focus Reverse: File -> Tree -> Structure" })

-- Buffer Navigation
vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = "Next File Tab" })
vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = "Previous File Tab" })

-- Window Split Navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })

-- Smart Close
local function get_normal_window_count()
  local count = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then 
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      if ft ~= "NvimTree" and ft ~= "toggleterm" and ft ~= "trouble" and ft ~= "aerial" and ft ~= "alpha" then
        count = count + 1
      end
    end
  end
  return count
end

vim.keymap.set('n', '<leader>w', function()
  if vim.bo.filetype == "NvimTree" or vim.bo.filetype == "aerial" or vim.bo.filetype == "alpha" then return end
  if get_normal_window_count() > 1 then vim.cmd("close") else
    if not require("mini.bufremove").delete(0, false) then vim.cmd('bdelete!') end
  end
end, { noremap = true, silent = true, desc = "Close Current File or Split Safely" })

-- General Core Bindings
vim.keymap.set('n', '<leader>q', ':qa<CR>', { noremap = true, silent = true, desc = "Quit All" })
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-z>', 'u', { noremap = true, silent = true })
vim.keymap.set('i', '<C-z>', '<C-o>u', { noremap = true, silent = true })
vim.keymap.set('n', '<C-y>', '<C-r>', { noremap = true, silent = true })
vim.keymap.set('i', '<C-y>', '<C-o><C-r>', { noremap = true, silent = true })
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', { noremap = true, silent = true })
vim.keymap.set({ 'v', 'x', 's', 'c' }, '<M-j>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set({ 'v', 'x', 's', 'c' }, '<M-J>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set({ 'v', 'x', 's', 'c' }, '<M-S-j>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set('n', '<M-j>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })
vim.keymap.set('n', '<M-J>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })
vim.keymap.set('n', '<M-S-j>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })

-- Escape with Alt+u
vim.keymap.set({ 'i', 'v', 'x', 's', 'c' }, '<M-u>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set({ 'i', 'v', 'x', 's', 'c' }, '<M-U>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set({ 'i', 'v', 'x', 's', 'c' }, '<M-S-u>', '<Esc>', { noremap = true, silent = true, desc = "Escape" })
vim.keymap.set('n', '<M-u>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })
vim.keymap.set('n', '<M-U>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })
vim.keymap.set('n', '<M-S-u>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true, desc = "Escape / Clear Search" })

-- Backspace with Alt+b
vim.keymap.set({ 'i', 'c' }, '<M-b>', '<BS>', { noremap = true, silent = true, desc = "Backspace" })

-- Insert Mode Directional Navigation (Alt + h/j/k/l)
vim.keymap.set('i', '<M-h>', '<Left>',  { noremap = true, silent = true, desc = "Move Left (Insert)" })
vim.keymap.set('i', '<M-j>', '<Down>',  { noremap = true, silent = true, desc = "Move Down (Insert)" })
vim.keymap.set('i', '<M-k>', '<Up>',    { noremap = true, silent = true, desc = "Move Up (Insert)" })
vim.keymap.set('i', '<M-l>', '<Right>', { noremap = true, silent = true, desc = "Move Right (Insert)" })

-- Home & End Navigation
-- Insert mode: Ctrl+h (Home) / Ctrl+l (End)
vim.keymap.set('i', '<C-h>', '<Home>', { noremap = true, silent = true, desc = "Go to Line Start (Insert)" })
vim.keymap.set('i', '<C-l>', '<End>',  { noremap = true, silent = true, desc = "Go to Line End (Insert)" })
-- Normal & Visual modes: Move cursor or extend visual selection to line start/end
vim.keymap.set({ 'n', 'v', 'x' }, '<M-h>', '0', { noremap = true, silent = true, desc = "Go to Line Start" })
vim.keymap.set({ 'n', 'v', 'x' }, '<M-l>', '$', { noremap = true, silent = true, desc = "Go to Line End" })

-- Home & End Selection with Shift (Alt+Shift+h / Alt+Shift+l)
local function select_to_line_start_from_insert()
  local col = vim.fn.col('.')
  vim.cmd('stopinsert')
  if col <= 1 then
    vim.cmd('normal! v0')
    return
  end
  vim.cmd('normal! v0')
end

local function select_to_line_end_from_insert()
  local col = vim.fn.col('.')
  local line_len = #vim.api.nvim_get_current_line()
  vim.cmd('stopinsert')
  if col > line_len then
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { pos[1], col - 1 })
  vim.cmd('normal! v$')
end

vim.keymap.set('i', '<M-S-h>', select_to_line_start_from_insert, { noremap = true, silent = true, desc = "Select to Line Start from Insert" })
vim.keymap.set('i', '<M-H>', select_to_line_start_from_insert, { noremap = true, silent = true, desc = "Select to Line Start from Insert" })
vim.keymap.set('i', '<M-S-l>', select_to_line_end_from_insert, { noremap = true, silent = true, desc = "Select to Line End from Insert" })
vim.keymap.set('i', '<M-L>', select_to_line_end_from_insert, { noremap = true, silent = true, desc = "Select to Line End from Insert" })

vim.keymap.set('n', '<M-S-h>', 'v0', { noremap = true, silent = true, desc = "Select to Line Start" })
vim.keymap.set('n', '<M-H>', 'v0', { noremap = true, silent = true, desc = "Select to Line Start" })
vim.keymap.set('n', '<M-S-l>', 'v$', { noremap = true, silent = true, desc = "Select to Line End" })
vim.keymap.set('n', '<M-L>', 'v$', { noremap = true, silent = true, desc = "Select to Line End" })

vim.keymap.set({ 'v', 'x' }, '<M-S-h>', '0', { noremap = true, silent = true, desc = "Extend Selection to Line Start" })
vim.keymap.set({ 'v', 'x' }, '<M-H>', '0', { noremap = true, silent = true, desc = "Extend Selection to Line Start" })
vim.keymap.set({ 'v', 'x' }, '<M-S-l>', '$', { noremap = true, silent = true, desc = "Extend Selection to Line End" })
vim.keymap.set({ 'v', 'x' }, '<M-L>', '$', { noremap = true, silent = true, desc = "Extend Selection to Line End" })


-- Open in OS Viewer
vim.keymap.set('n', '<leader>o', function()
  local path = ""
  if vim.bo.filetype == "NvimTree" then
    local status_ok, api = pcall(require, "nvim-tree.api")
    if status_ok then
      local node = api.tree.get_node_under_cursor()
      if node then path = node.absolute_path; if node.type == "file" then path = vim.fn.fnamemodify(path, ":h") end end
    end
    if path == "" then path = vim.fn.getcwd() end
  else path = vim.fn.expand('%:p') end
  if path == "" then return end
  if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', path }, { detach = true })
  elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
  elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', path }, { detach = true }) end
end, { noremap = true, silent = true, desc = "Open in OS Explorer" })


-- Auto-open non-image binary files in OS viewer
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = { "*.pdf", "*.mp4", "*.mkv", "*.avi", "*.mp3", "*.zip", "*.tar", "*.gz" },
  callback = function(args)
    local path = vim.fn.expand(args.match)
    if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', path }, { detach = true })
    elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
    elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', path }, { detach = true }) end

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})

-- Open Git Remote in Browser
vim.keymap.set('n', '<leader>G', function()
  local url = vim.fn.system("git config --get remote.origin.url")
  if vim.v.shell_error ~= 0 or url == "" then return end
  url = url:gsub("%s+", ""):gsub("^git@([^:]+):", "https://%1/"):gsub("%.git$", "")
  if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', url }, { detach = true })
  elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', url }, { detach = true })
  elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', url }, { detach = true }) end
end, { noremap = true, silent = true, desc = "Open Git Remote" })

-- Terminal Exit & Splits
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>th', ':ToggleTerm direction=horizontal<CR>', { noremap = true, silent = true, desc = "Terminal (Horizontal)" })
vim.keymap.set('n', '<leader>tv', ':ToggleTerm direction=vertical size=40<CR>', { noremap = true, silent = true, desc = "Terminal (Vertical)" })

-- Visual / Select Mode Overrides
local modes = {'v', 's'}
for _, mode in ipairs(modes) do
  vim.keymap.set(mode, '<BS>', (mode == 's' and '<C-g>' or '') .. '"_d', { noremap = true })
  vim.keymap.set(mode, '<Del>', (mode == 's' and '<C-g>' or '') .. '"_d', { noremap = true })
  vim.keymap.set(mode, 'p', (mode == 's' and '<C-g>' or '') .. '"_dP', { noremap = true })
  vim.keymap.set(mode, 'P', (mode == 's' and '<C-g>' or '') .. '"_dP', { noremap = true })
end

-- Directional Visual Selection Keybindings (Shift + H/J/K/L, Shift + W/B, Shift + Arrows)
-- Shift + H: Select word backward (left in line)
vim.keymap.set('n', 'H', 'vb', { noremap = true, silent = true, desc = "Select word backward" })
vim.keymap.set('n', '<S-h>', 'vb', { noremap = true, silent = true, desc = "Select word backward" })
vim.keymap.set({ 'v', 'x' }, 'H', 'b', { noremap = true, silent = true, desc = "Extend selection word backward" })
vim.keymap.set({ 'v', 'x' }, '<S-h>', 'b', { noremap = true, silent = true, desc = "Extend selection word backward" })

-- Shift + L: Select word forward (right in line)
vim.keymap.set('n', 'L', 'vw', { noremap = true, silent = true, desc = "Select word forward" })
vim.keymap.set('n', '<S-l>', 'vw', { noremap = true, silent = true, desc = "Select word forward" })
vim.keymap.set({ 'v', 'x' }, 'L', 'w', { noremap = true, silent = true, desc = "Extend selection word forward" })
vim.keymap.set({ 'v', 'x' }, '<S-l>', 'w', { noremap = true, silent = true, desc = "Extend selection word forward" })

-- Shift + J: Select multiple lines downward
vim.keymap.set('n', 'J', 'vj', { noremap = true, silent = true, desc = "Select line downward" })
vim.keymap.set('n', '<S-j>', 'vj', { noremap = true, silent = true, desc = "Select line downward" })
vim.keymap.set({ 'v', 'x' }, 'J', 'j', { noremap = true, silent = true, desc = "Extend selection downward" })
vim.keymap.set({ 'v', 'x' }, '<S-j>', 'j', { noremap = true, silent = true, desc = "Extend selection downward" })

-- Shift + K: Select multiple lines upward
vim.keymap.set('n', 'K', 'vk', { noremap = true, silent = true, desc = "Select line upward" })
vim.keymap.set('n', '<S-k>', 'vk', { noremap = true, silent = true, desc = "Select line upward" })
vim.keymap.set({ 'v', 'x' }, 'K', 'k', { noremap = true, silent = true, desc = "Extend selection upward" })
vim.keymap.set({ 'v', 'x' }, '<S-k>', 'k', { noremap = true, silent = true, desc = "Extend selection upward" })

-- Shift + W: Select forward WORD (enters Visual mode and extends selection)
vim.keymap.set('n', 'W', 'vW', { noremap = true, silent = true, desc = "Select forward WORD" })
vim.keymap.set('n', '<S-w>', 'vW', { noremap = true, silent = true, desc = "Select forward WORD" })
vim.keymap.set({ 'v', 'x' }, 'W', 'W', { noremap = true, silent = true, desc = "Extend selection forward WORD" })
vim.keymap.set({ 'v', 'x' }, '<S-w>', 'W', { noremap = true, silent = true, desc = "Extend selection forward WORD" })

-- Shift + B: Select backward WORD (enters Visual mode and extends selection)
vim.keymap.set('n', 'B', 'vB', { noremap = true, silent = true, desc = "Select backward WORD" })
vim.keymap.set('n', '<S-b>', 'vB', { noremap = true, silent = true, desc = "Select backward WORD" })
vim.keymap.set({ 'v', 'x' }, 'B', 'B', { noremap = true, silent = true, desc = "Extend selection backward WORD" })
vim.keymap.set({ 'v', 'x' }, '<S-b>', 'B', { noremap = true, silent = true, desc = "Extend selection backward WORD" })

-- Shift + Arrow Keys Selection
vim.keymap.set('n', '<S-Down>', 'vj', { noremap = true, silent = true, desc = "Select line downward" })
vim.keymap.set('n', '<S-Up>', 'vk', { noremap = true, silent = true, desc = "Select line upward" })
vim.keymap.set('n', '<S-Left>', 'vb', { noremap = true, silent = true, desc = "Select word backward" })
vim.keymap.set('n', '<S-Right>', 'vw', { noremap = true, silent = true, desc = "Select word forward" })
vim.keymap.set({ 'v', 'x' }, '<S-Down>', 'j', { noremap = true, silent = true, desc = "Extend selection downward" })
vim.keymap.set({ 'v', 'x' }, '<S-Up>', 'k', { noremap = true, silent = true, desc = "Extend selection upward" })
vim.keymap.set({ 'v', 'x' }, '<S-Left>', 'b', { noremap = true, silent = true, desc = "Extend selection word backward" })
vim.keymap.set({ 'v', 'x' }, '<S-Right>', 'w', { noremap = true, silent = true, desc = "Extend selection word forward" })

-- Join lines alternative (since J is now selection downward)
vim.keymap.set('n', 'gJ', 'J', { noremap = true, silent = true, desc = "Join Lines" })

-- =========================================================================
-- 6. VS CODE STYLE COPY / CUT / PASTE 
-- =========================================================================
vim.keymap.set('s', 'y', '<C-g>y', { noremap = true, silent = true })
vim.keymap.set('v', '<C-c>', 'y', { noremap = true, silent = true })
vim.keymap.set('s', '<C-c>', '<C-g>y', { noremap = true, silent = true })
vim.keymap.set('n', '<C-c>', 'yy', { noremap = true, silent = true })
vim.keymap.set('i', '<C-c>', '<C-o>yy', { noremap = true, silent = true })
vim.keymap.set('v', '<C-x>', 'x', { noremap = true, silent = true })
vim.keymap.set('s', '<C-x>', '<C-g>c', { noremap = true, silent = true })
vim.keymap.set('n', '<C-x>', 'dd', { noremap = true, silent = true })
vim.keymap.set('i', '<C-x>', '<C-o>dd', { noremap = true, silent = true })
vim.keymap.set('i', '<C-v>', '<C-r>+', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>U', function()
  print("Updating plugins...")
  vim.cmd("Lazy update")
end, { noremap = true, silent = true, desc = "Update Plugins (Lazy)" })


-- =========================================================================
-- 8. TERMINAL MULTIPLEXING
-- =========================================================================
local status_ok, tt_api = pcall(require, "toggleterm.terminal")
if status_ok then
  local Terminal = tt_api.Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float", float_opts = { border = "curved" } })
  function _lazygit_toggle() lazygit:toggle() end
  vim.keymap.set('n', '<leader>gg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true, desc = "Toggle Lazygit" })

  -- In-Terminal Browser (Browsh with TrueColor support for WezTerm / Kitty / Ghostty)
  local browsh_cmd = vim.fn.executable("browsh") == 1 and "browsh" or (vim.fn.executable("browsh.exe") == 1 and "browsh.exe" or "browsh")
  local browser = Terminal:new({
    cmd = browsh_cmd,
    hidden = true,
    direction = "float",
    float_opts = {
      border = "curved",
      width = function() return math.floor(vim.o.columns * 0.96) end,
      height = function() return math.floor(vim.o.lines * 0.94) end,
      winblend = 0,
    },
    env = {
      COLORTERM = "truecolor",
      TERM = (vim.env.TERM and vim.env.TERM ~= "" and vim.env.TERM) or "xterm-256color",
    },
    on_open = function(term)
      vim.cmd("startinsert!")
      -- Pressing <leader>b inside browser terminal minimizes/hides it back to editor
      vim.keymap.set('t', '<leader>b', function()
        term:toggle()
      end, { buffer = term.bufnr, noremap = true, silent = true, desc = "Hide Browser" })
    end,
  })

  function _G.Toggle_Browser()
    if vim.fn.executable(browsh_cmd) ~= 1 then
      local is_windows = vim.fn.has("win32") == 1
      local hint = is_windows
        and "Browsh not found. Install via: 'scoop install browsh' or 'winget install browsh' (and ensure Firefox is installed)."
        or "Browsh not found. Install via package manager / AUR / brew: 'brew install browsh' (and ensure Firefox is installed)."
      vim.notify(hint, vim.log.levels.WARN, { title = "Browser (Browsh)" })
    end
    browser:toggle()
  end

  vim.keymap.set({ 'n', 't' }, '<leader>b', '<cmd>lua _G.Toggle_Browser()<CR>', { noremap = true, silent = true, desc = "Toggle In-Terminal Browser (Browsh)" })

  local function get_terms()
      local terms = {}
      for _, t in pairs(tt_api.get_all()) do table.insert(terms, t) end
      table.sort(terms, function(a, b) return a.id < b.id end)
      return terms
  end

  function _G.Update_Term_Winbar(win_id)
      if not win_id or not vim.api.nvim_win_is_valid(win_id) then return end
      local terms = get_terms()
      local bar = "  "
      for _, t in ipairs(terms) do
          if t.window and t.window == win_id then bar = bar .. "%#String# ● Term " .. t.id .. " %#Normal#  "
          else bar = bar .. "%#Comment# ○ Term " .. t.id .. " %#Normal#  " end
      end
      local buf = vim.api.nvim_win_get_buf(win_id)
      if vim.bo[buf].filetype == "toggleterm" then pcall(vim.api.nvim_set_option_value, 'winbar', bar, { win = win_id }) end
  end

  function _G.Term_New()
      local terms = get_terms()
      local max_id = 0
      for _, t in ipairs(terms) do if t.id > max_id then max_id = t.id end; if t:is_open() then t:close() end end
      vim.cmd((max_id + 1) .. "ToggleTerm direction=float")
  end

  function _G.Term_Next()
      local terms = get_terms()
      if #terms <= 1 then return end
      for i, t in ipairs(terms) do
          if t:is_open() then
              local next_term = terms[i + 1] or terms[1]
              t:close(); next_term:open(); vim.cmd("startinsert!")
              return
          end
      end
  end

  function _G.Term_Prev()
      local terms = get_terms()
      if #terms <= 1 then return end
      for i, t in ipairs(terms) do
          if t:is_open() then
              local prev_term = terms[i - 1] or terms[#terms]
              t:close(); prev_term:open(); vim.cmd("startinsert!")
              return
          end
      end
  end

  function _G.Term_Close()
      local terms = get_terms()
      if #terms == 0 then return end
      for i, t in ipairs(terms) do
          if t:is_open() then
              if #terms == 1 then t:shutdown() 
              else
                  local next_term = terms[i + 1] or terms[i - 1]
                  t:shutdown(); next_term:open()
              end
              vim.defer_fn(function()
                  local open_terms = get_terms()
                  for _, remaining_t in ipairs(open_terms) do
                      if remaining_t:is_open() and remaining_t.window and vim.api.nvim_win_is_valid(remaining_t.window) then
                          _G.Update_Term_Winbar(remaining_t.window)
                      end
                  end
                  vim.cmd("startinsert!") 
              end, 50)
              return
          end
      end
  end

  vim.keymap.set('t', '<M-t>', '<cmd>lua _G.Term_New()<CR>', { noremap = true, silent = true })
  vim.keymap.set('t', '<M-w>', '<cmd>lua _G.Term_Close()<CR>', { noremap = true, silent = true })
  vim.keymap.set('t', '<M-]>', '<cmd>lua _G.Term_Next()<CR>', { noremap = true, silent = true })
  vim.keymap.set('t', '<M-[>', '<cmd>lua _G.Term_Prev()<CR>', { noremap = true, silent = true })
end
