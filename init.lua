-- =========================================================================
-- 1. BOOTSTRAP PLUGIN MANAGER (lazy.nvim)
-- =========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " " -- Sets the leader key to Space

-- =========================================================================
-- 2. PLUGINS CONFIGURATION
-- =========================================================================
require("lazy").setup({
  
  -- High Contrast Theme (TokyoNight OLED Hack)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        -- Force pure black backgrounds
        on_colors = function(colors)
          colors.bg = "#000000"          -- Main background
          colors.bg_dark = "#000000"     -- Darker background areas
          colors.bg_float = "#000000"    -- Floating windows
          colors.bg_sidebar = "#000000"  -- NvimTree sidebar
          colors.bg_statusline = "#000000"
        end,

		-- Highlights for golang (which don't seem to work for some reason)
		on_highlights = function(hl, c)
          -- 1. Variables (admin, api): Standard foreground (white/gray) instead of flat blue
          hl["@variable"] = { fg = c.fg }
          hl["@lsp.type.variable"] = { fg = c.fg }

          -- 2. Packages/Modules (handlers, middleware): Teal/Green
          hl["@module"] = { fg = c.teal }
          hl["@lsp.type.namespace"] = { fg = c.teal }

          -- 3. Methods (.GET, .POST, .Use): Magenta/Purple
          hl["@function.method"] = { fg = c.magenta }
          hl["@function.method.call"] = { fg = c.magenta }
          hl["@lsp.type.method"] = { fg = c.magenta }

          -- 4. Standalone Functions (GetMaxTeams, AuthRequired): Blue
          hl["@function"] = { fg = c.blue }
          hl["@function.call"] = { fg = c.blue }
          hl["@lsp.type.function"] = { fg = c.blue }

          -- 5. Types & Interfaces: Orange
          hl["@type"] = { fg = c.orange }
          hl["@lsp.type.type"] = { fg = c.orange }
          hl["@lsp.type.interface"] = { fg = c.orange }
          
          -- 6. Struct Properties/Fields: Cyan
          hl["@property"] = { fg = c.cyan }
          hl["@lsp.type.property"] = { fg = c.cyan }
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
          [[    _  __                   _                 ]],
          [[   / |/ /__  ___ _  __ __  (_) __ _           ]],
          [[  /    / -_)/ _ \ |/ // / / / /  ' \          ]],
          [[ /_/|_/\__/ \___/___/ \_,_//_/ /_/_/_/        ]],
          [[                                              ]],
          [[            Welcome, AniruddhRaam.            ]],
      }

      dashboard.section.header.val = {}
      for _ = 1, #logo do table.insert(dashboard.section.header.val, "") end

      -- Custom section for the live-updating date and time
      local info_section = {
          type = "text",
          val = { "" },
          opts = { position = "center", hl = "Keyword" }
      }

      dashboard.section.buttons.val = {
          dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
          dashboard.button("d", "󰉖  Browse Dirs", ":Telescope file_browser<CR>"),
          dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
          dashboard.button("p", "󰏋  Projects", ":Telescope projects <CR>"),
          dashboard.button("s", "󰦛  Restore Session", ":AutoSession restore<CR>"),
          dashboard.button("q", "󰅙  Quit NVIM", ":qa<CR>"),
      }

      -- Dynamic layout to push logo to center and buttons to bottom
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


      vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
              -- Reset Logo
              for i = 1, #logo do dashboard.section.header.val[i] = "" end
              
              -- Logo State
              local row = 1
              local col = 1
              local pause_ticks = 0
              
              -- Info State
              local info_typed = false
              local info_col = 1
              
              local function get_datetime()
                  -- Format: Day, DD-MM-YYYY | HH:MM:SS
                  return os.date("%A, %d-%m-%Y  |  %H:%M:%S")
              end
              
              local function draw_frame()
                  if vim.bo.filetype ~= "alpha" then return end
                  local needs_redraw = false
                  
                  -- 1. Logo Animation (Looping)
                  if pause_ticks > 0 then
                      pause_ticks = pause_ticks - 1
                      if pause_ticks == 0 then
                          -- Clear logo for next loop
                          for i = 1, #logo do dashboard.section.header.val[i] = "" end
                          row = 1
                          col = 1
                          needs_redraw = true
                      end
                  else
                      if row <= #logo then
                          local target_line = logo[row]
                          col = col + 2 -- Typing speed
                          if col > #target_line then col = #target_line end
                          
                          dashboard.section.header.val[row] = target_line:sub(1, col)
                          needs_redraw = true

                          if col >= #target_line then
                              row = row + 1
                              col = 1
                              if row > #logo then
                                  pause_ticks = 75 -- Pauses for ~1.25 seconds before looping
                              end
                          end
                      end
                  end

                  -- 2. Info Animation (Types once, then just updates the time)
                  local current_info = get_datetime()
                  if not info_typed then
                      info_col = info_col + 1
                      if info_col >= #current_info then
                          info_col = #current_info
                          info_typed = true
                      end
                      info_section.val[1] = current_info:sub(1, info_col)
                      needs_redraw = true
                  else
                      -- Live clock ticking
                      if info_section.val[1] ~= current_info then
                          info_section.val[1] = current_info
                          needs_redraw = true
                      end
                  end
                  
                  if needs_redraw then pcall(vim.cmd.AlphaRedraw) end
                  
                  -- Master loop runs consistently at ~15ms (approx 60fps)
                  vim.defer_fn(draw_frame, 15)
              end
              
              draw_frame()
          end,
      })
    end
  },

  -- Automated Session Management
  {
    "rmagatti/auto-session",
    config = function()
      require("auto-session").setup({
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
        auto_restore_enabled = false, 
        pre_save_cmds = { "ToggleTermToggleAll" }, 
        bypass_session_save_file_types = { "alpha", "NvimTree" },
      })
    end,
  },

  -- Project Root Detection & Management
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern" },
        patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "go.mod" },
      })
    end
  },

  -- Lightning Fast Navigation (Flash)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = { search = { enabled = true } },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Visual Code Outline & Structure (Aerial)
  {
    "stevearc/aerial.nvim",
    dependencies = {
       "nvim-treesitter/nvim-treesitter",
       "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("aerial").setup({
        layout = { max_width = { 40, 0.2 }, min_width = 20, default_direction = "right" },
        filter_kind = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct" },
        icons = { 
           Class = "󰠱 ", Function = "󰊕 ", Method = "󰆧 ", Struct = "󰙅 ", Interface = " ", Module = "󰏗 ", Variable = "󰀫 "
        },
        show_guides = true,
      })
    end
  },

  -- Universal Test Runner (Neotest)
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
      "rouge8/neotest-rust",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-go")({ experimental = { test_table = true } }),
          require("neotest-python")({ runner = "pytest" }),
          require("neotest-rust")({ args = { "--no-capture" } }),
        },
        status = { virtual_text = true },
        output = { open_on_run = true },
      })
    end
  },

  -- Ultimate Searching & Fuzzy Finding (Telescope) + File Browser (cd interface)
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = { 
        "nvim-lua/plenary.nvim", 
        "nvim-tree/nvim-web-devicons",
        "nvim-telescope/telescope-file-browser.nvim"
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { ".git/", "node_modules/", "__pycache__/", ".venv/", "target/" },
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
        },
        extensions = {
          file_browser = {
            theme = "ivy",
            hijack_netrw = true,
          },
        }
      })
      require("telescope").load_extension("projects")
      require("telescope").load_extension("file_browser") 
    end,
  },

  -- Persistent File Explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        on_attach = function(bufnr)
          local api = require('nvim-tree.api')
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set('n', 'q', '<cmd>wincmd p<CR>', { buffer = bufnr, noremap = true, silent = true, desc = "Return to code (don't close)" })
        end,
        view = { width = 35, side = "left" },
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
            { filetype = "aerial", text = "Outline", highlight = "Directory", separator = true }
          }
        }
      }) 
    end 
  },

  -- Syntax Highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local status_ok, configs = pcall(require, "nvim-treesitter.configs")
      if not status_ok then return end
      configs.setup({
        ensure_installed = { 
            "javascript", "typescript", "c", "cpp", "python", "html", 
            "css", "lua", "markdown", "rust", "toml",
            "go", "gomod", "gowork", "gosum", "gotmpl"
        },
        highlight = { 
            enable = true,
            additional_vim_regex_highlighting = false, -- Disabled to prevent legacy syntax conflicts
        },
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          python = { "ruff_format" },
          c = { "lsp_format" },
          cpp = { "lsp_format" },
          html = { "lsp_format" },
          rust = { "rustfmt" },
          go = { "goimports", "gofmt" },
        },
        format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
        formatters = {
          prettier = { prepend_args = { "--use-tabs", "--tab-width", "4", "--no-semi" } },
        },
      })
    end,
  },

  -- Autocompletion Engine
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Mason and related tools for LSP management
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {}, 
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "html-lsp",
          "clangd",
          "ruff",
          "typescript-language-server",
          "pyrefly",
          "rust-analyzer",
          "gopls",
          "goimports", 
        },
        auto_update = false,
        run_on_start = true,
      })
    end,
  },

  -- Diagnostics & Errors Panel (Trouble)
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      modes = { diagnostics = { auto_preview = true } }
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true<CR>", desc = "Diagnostics / Errors (Trouble)" },
    },
  },

  -- Jupyter Notebook Viewing (.ipynb)
  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      require("jupytext").setup({ style = "light", output_extension = "py", force_ft = "python" })
    end,
  },

  -- Smart Buffer Closing
  {
    "echasnovski/mini.bufremove",
    version = "*",
    config = function() require("mini.bufremove").setup() end,
  },

  -- Beautiful CSV viewing
  { "mechatroner/rainbow_csv", event = "BufRead" },

  -- Statusline (Lualine)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "tokyonight", component_separators = '|', section_separators = '' },
      })
    end,
  },

  -- Auto-Pairs
  { "echasnovski/mini.pairs", version = "*", config = function() require("mini.pairs").setup() end },

  -- Shortcut Cheat Sheet (Which-Key)
  { "folke/which-key.nvim", event = "VeryLazy", config = function() require("which-key").setup({ delay = 500 }) end },

  -- Git Integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({ current_line_blame = true, current_line_blame_opts = { delay = 500, virt_text_pos = 'eol' } })
    end,
  },

  -- Floating Terminal Manager
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]], 
        direction = "float",
        shade_terminals = false, 
        float_opts = { border = "curved" },
        on_open = function(term)
          if _G.Update_Term_Winbar then
            _G.Update_Term_Winbar(term.window)
          end
          vim.cmd("startinsert!")
        end,
      })
    end,
  },

}, {
  checker = { enabled = true, notify = false, frequency = 86400 },
  change_detection = { notify = false }
})

-- =========================================================================
-- 3. LSP CONFIGURATION 
-- =========================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("html", {})   
vim.lsp.config("ts_ls", {})  

vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
})

vim.lsp.config("ruff", {
  init_options = {
    settings = { args = {} },
  },
})

vim.lsp.config("pyrefly", {
  cmd = { "pyrefly", "lsp" },
  filetypes = { "python" },
})

vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = { command = "clippy" },
      cargo = { allFeatures = true },
    },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = { unusedparams = true },
      semanticTokens = true, -- Forces deep syntax parsing
    },
  },
})

vim.lsp.enable("html")
vim.lsp.enable("ts_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("ruff")
vim.lsp.enable("pyrefly")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }
    
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
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
vim.opt.incsearch = true   

vim.diagnostic.config({
  virtual_text = { severity = vim.diagnostic.severity.ERROR },
  signs = true,
  underline = true,
})

-- =========================================================================
-- 5. CUSTOM KEYBINDINGS 
-- =========================================================================

-- THE SEARCH UPGRADES
vim.keymap.set('n', '/', '/\\V', { noremap = true, desc = "Literal Search Forward" })
vim.keymap.set('v', '/', '/\\V', { noremap = true, desc = "Literal Search Forward" })
vim.keymap.set('n', '?', '?\\V', { noremap = true, desc = "Literal Search Backward" })
vim.keymap.set('v', '?', '?\\V', { noremap = true, desc = "Literal Search Backward" })

-- Modern Floating Search (Telescope)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-f>', builtin.current_buffer_fuzzy_find, { noremap = true, silent = true, desc = "Fuzzy Find in File" })
vim.keymap.set('n', '<leader>f', builtin.find_files, { noremap = true, silent = true, desc = "Find Files in Project" })
vim.keymap.set('n', '<leader>F', builtin.live_grep, { noremap = true, silent = true, desc = "Find Text in Project" })
vim.keymap.set('n', '<leader>p', ':Telescope projects<CR>', { noremap = true, silent = true, desc = "Find Projects" })

-- NEW: Directory Browser (Like 'cd')
vim.keymap.set('n', '<leader>d', ':Telescope file_browser<CR>', { noremap = true, silent = true, desc = "Directory Browser (cd)" })

-- Structural Outline (Aerial)
vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { noremap = true, silent = true, desc = "Toggle Code Outline" })

-- Test Runner (Neotest)
vim.keymap.set("n", "<leader>tr", function() require("neotest").run.run() end, { desc = "Run Nearest Test" })
vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run Current File Tests" })
vim.keymap.set("n", "<leader>to", function() require("neotest").output_panel.toggle() end, { desc = "Toggle Test Output" })

-- Session Management (UPDATED Command)
vim.keymap.set("n", "<leader>ss", "<cmd>AutoSession restore<CR>", { desc = "Restore Project Session" })

-- --- STRICT FILE TREE TOGGLE (Only Ctrl+Alt+e)
local function toggle_tree_focus()
  if vim.bo.filetype == "NvimTree" then vim.cmd("wincmd p") else vim.cmd("NvimTreeFocus") end
end
vim.keymap.set({'n', 'i', 'v'}, '<C-M-e>', toggle_tree_focus, { noremap = true, silent = true, desc = "Toggle Tree Focus" })

-- --- STRICT BUFFER NAVIGATION (Overrides Jump List Issue)
vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = "Next File Tab" })
vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = "Previous File Tab" })

-- Explicit Window Split Navigation (To hop between your splits manually)
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true, desc = "Move to left split" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true, silent = true, desc = "Move to below split" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true, silent = true, desc = "Move to above split" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true, silent = true, desc = "Move to right split" })

-- Helper to check if multiple active code windows exist (for safe closing)
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

-- Smart Close: Closes the split if multiple exist, otherwise safely closes the file
vim.keymap.set('n', '<leader>w', function()
  if vim.bo.filetype == "NvimTree" or vim.bo.filetype == "aerial" then return end
  if get_normal_window_count() > 1 then
    vim.cmd("close")
  else
    if not require("mini.bufremove").delete(0, false) then vim.cmd('bdelete!') end
  end
end, { noremap = true, silent = true, desc = "Close Current File or Split Safely" })

-- General Core Bindings
vim.keymap.set('n', '<leader>q', ':qa<CR>', { noremap = true, silent = true, desc = "Quit Entirely" })
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<CR>', { noremap = true, silent = true, desc = "Save File" })
vim.keymap.set('n', '<C-z>', 'u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('i', '<C-z>', '<C-o>u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('n', '<C-y>', '<C-r>', { noremap = true, silent = true, desc = "Redo" })
vim.keymap.set('i', '<C-y>', '<C-o><C-r>', { noremap = true, silent = true, desc = "Redo" })
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', { noremap = true, silent = true, desc = "Clear Search Highlights" })

-- Open in OS Viewer
vim.keymap.set('n', '<leader>o', function()
  local path = ""
  if vim.bo.filetype == "NvimTree" then
    local status_ok, api = pcall(require, "nvim-tree.api")
    if status_ok then
      local node = api.tree.get_node_under_cursor()
      if node then
        path = node.absolute_path
        if node.type == "file" then path = vim.fn.fnamemodify(path, ":h") end
      end
    end
    if path == "" then path = vim.fn.getcwd() end
  else
    path = vim.fn.expand('%:p')
  end

  if path == "" then return end
  if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', path }, { detach = true })
  elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
  elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', path }, { detach = true }) end
  print("Opened in OS: " .. path)
end, { noremap = true, silent = true, desc = "Open in OS Viewer" })

-- Open Git Remote in Browser
vim.keymap.set('n', '<leader>G', function()
  local url = vim.fn.system("git config --get remote.origin.url")
  if vim.v.shell_error ~= 0 or url == "" then
    print("No git remote origin found in this directory.")
    return
  end
  
  url = url:gsub("%s+", "")
  url = url:gsub("^git@([^:]+):", "https://%1/")
  url = url:gsub("%.git$", "")
  
  if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', url }, { detach = true })
  elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', url }, { detach = true })
  elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', url }, { detach = true }) end
  print("Opened Git Remote: " .. url)
end, { noremap = true, silent = true, desc = "Open Git Remote in Browser" })

-- Terminal Exit & Splits
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { noremap = true, silent = true, desc = "Exit Terminal Mode" })
vim.keymap.set('n', '<leader>th', ':ToggleTerm direction=horizontal<CR>', { noremap = true, silent = true, desc = "Terminal (Horizontal)" })
vim.keymap.set('n', '<leader>tv', ':ToggleTerm direction=vertical size=40<CR>', { noremap = true, silent = true, desc = "Terminal (Vertical)" })

-- Visual Mode (v) Backspace & Paste
vim.keymap.set('v', '<BS>', '"_d', { noremap = true, desc = "Delete without copying" })
vim.keymap.set('v', '<Del>', '"_d', { noremap = true, desc = "Delete without copying" })
vim.keymap.set('v', 'p', '"_dP', { noremap = true, desc = "Paste without copying" })
vim.keymap.set('v', 'P', '"_dP', { noremap = true, desc = "Paste without copying" })

-- Select Mode (s) Backspace & Paste 
vim.keymap.set('s', '<BS>', '<C-g>"_d', { noremap = true, desc = "Delete without copying" })
vim.keymap.set('s', '<Del>', '<C-g>"_d', { noremap = true, desc = "Delete without copying" })
vim.keymap.set('s', 'p', '<C-g>"_dP', { noremap = true, desc = "Paste without copying" })
vim.keymap.set('s', 'P', '<C-g>"_dP', { noremap = true, desc = "Paste without copying" })

-- =========================================================================
-- 6. VS CODE STYLE COPY / CUT / PASTE 
-- =========================================================================
vim.keymap.set('s', 'y', '<C-g>y', { noremap = true, silent = true, desc = "Copy selection" })
vim.keymap.set('v', '<C-c>', 'y', { noremap = true, silent = true, desc = "Copy" })
vim.keymap.set('s', '<C-c>', '<C-g>y', { noremap = true, silent = true, desc = "Copy" })
vim.keymap.set('n', '<C-c>', 'yy', { noremap = true, silent = true, desc = "Copy Line" })
vim.keymap.set('i', '<C-c>', '<C-o>yy', { noremap = true, silent = true, desc = "Copy Line" })
vim.keymap.set('v', '<C-x>', 'x', { noremap = true, silent = true, desc = "Cut" })
vim.keymap.set('s', '<C-x>', '<C-g>c', { noremap = true, silent = true, desc = "Cut & Insert" })
vim.keymap.set('n', '<C-x>', 'dd', { noremap = true, silent = true, desc = "Cut Line" })
vim.keymap.set('i', '<C-x>', '<C-o>dd', { noremap = true, silent = true, desc = "Cut Line" })
vim.keymap.set('i', '<C-v>', '<C-r>+', { noremap = true, silent = true, desc = "Paste" })

vim.keymap.set('n', '<leader>U', function()
  print("Starting safe system update...")
  vim.cmd("Lazy update")
  vim.cmd("MasonToolsUpdate")
end, { noremap = true, silent = true, desc = "Update Plugins & LSPs" })

-- =========================================================================
-- 7. CODE EXECUTION
-- =========================================================================
vim.keymap.set('v', '<leader>r', ':<C-U>ToggleTermSendVisualLines<CR>', { noremap = true, silent = true, desc = "Send Selection to Terminal" })
vim.keymap.set('n', '<leader>r', '<cmd>ToggleTermSendCurrentLine<CR><cmd>norm j<CR>', { noremap = true, silent = true, desc = "Send Line to Terminal" })

vim.keymap.set('n', '<leader>R', function()
  local file = vim.fn.expand('%')
  local ext = vim.fn.expand('%:e')
  vim.cmd("w") 
  if ext == 'py' or ext == 'ipynb' then vim.cmd('TermExec cmd="uv run python ' .. file .. '"')
  elseif ext == 'c' then vim.cmd('TermExec cmd="gcc ' .. file .. ' -o out && ./out"')
  elseif ext == 'cpp' then vim.cmd('TermExec cmd="g++ ' .. file .. ' -o out && ./out"')
  elseif ext == 'js' or ext == 'ts' then vim.cmd('TermExec cmd="node ' .. file .. '"')
  elseif ext == 'rs' then vim.cmd('TermExec cmd="cargo run"')
  elseif ext == 'go' then vim.cmd('TermExec cmd="go run ' .. file .. '"')
  else print("No auto-run command configured for this filetype.") end
end, { noremap = true, silent = true, desc = "Run Entire File" })

-- =========================================================================
-- 8. ADVANCED INTEGRATIONS
-- =========================================================================
local status_ok, tt_api = pcall(require, "toggleterm.terminal")
if status_ok then
  local Terminal = tt_api.Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float", float_opts = { border = "curved" } })
  function _lazygit_toggle() lazygit:toggle() end
  vim.keymap.set('n', '<leader>gg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true, desc = "Toggle Lazygit" })

-- =========================================================================
-- 9. MULTIPLE TERMINAL MULTIPLEXING 
-- =========================================================================
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
          if t.window and t.window == win_id then
              bar = bar .. "%#String# ● Term " .. t.id .. " %#Normal#  "
          else
              bar = bar .. "%#Comment# ○ Term " .. t.id .. " %#Normal#  "
          end
      end
      local buf = vim.api.nvim_win_get_buf(win_id)
      if vim.bo[buf].filetype == "toggleterm" then
          pcall(vim.api.nvim_set_option_value, 'winbar', bar, { win = win_id })
      end
  end

  function _G.Term_New()
      local terms = get_terms()
      local max_id = 0
      for _, t in ipairs(terms) do
          if t.id > max_id then max_id = t.id end
          if t:is_open() then t:close() end
      end
      vim.cmd((max_id + 1) .. "ToggleTerm direction=float")
  end

  function _G.Term_Next()
      local terms = get_terms()
      if #terms <= 1 then return end
      for i, t in ipairs(terms) do
          if t:is_open() then
              local next_term = terms[i + 1] or terms[1]
              t:close()
              next_term:open()
              vim.cmd("startinsert!")
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
              t:close()
              prev_term:open()
              vim.cmd("startinsert!")
              return
          end
      end
  end

  function _G.Term_Close()
      local terms = get_terms()
      if #terms == 0 then return end
      for i, t in ipairs(terms) do
          if t:is_open() then
              if #terms == 1 then
                  t:shutdown() 
              else
                  local next_term = terms[i + 1] or terms[i - 1]
                  t:shutdown() 
                  next_term:open()
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

  vim.keymap.set('t', '<M-t>', '<cmd>lua _G.Term_New()<CR>', { noremap = true, silent = true, desc = "New Terminal" })
  vim.keymap.set('t', '<M-w>', '<cmd>lua _G.Term_Close()<CR>', { noremap = true, silent = true, desc = "Close Terminal" })
  vim.keymap.set('t', '<M-]>', '<cmd>lua _G.Term_Next()<CR>', { noremap = true, silent = true, desc = "Next Terminal" })
  vim.keymap.set('t', '<M-[>', '<cmd>lua _G.Term_Prev()<CR>', { noremap = true, silent = true, desc = "Prev Terminal" })
end
