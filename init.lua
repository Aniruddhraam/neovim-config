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
                vim.cmd("enew") -- Open empty buffer to clear the Alpha background
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

      vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
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
          -- Reset cwd to the explicitly tracked project root before saving.
          function()
            if _G._project_root and vim.fn.isdirectory(_G._project_root) == 1 then
              vim.cmd("cd " .. vim.fn.fnameescape(_G._project_root))
            end
          end,
        },
        post_restore_cmds = {
          -- Open NvimTree rooted at the (now-correct) project cwd
          function()
            vim.cmd("NvimTreeOpen " .. vim.fn.fnameescape(vim.fn.getcwd()))
          end,
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
    dependencies = {
       "nvim-treesitter/nvim-treesitter",
       "nvim-tree/nvim-web-devicons"
    },
    config = function()
      require("aerial").setup({
        layout = { max_width = { 40, 0.2 }, min_width = 25, default_direction = "right" },
        filter_kind = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct", "Variable" },
        icons = { 
           Class = "󰠱 ", Function = "󰊕 ", Method = "󰆧 ", Struct = "󰙅 ", Interface = " ", Module = "󰏗 ", Variable = "󰀫 "
        },
        show_guides = true,
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
        "nvim-telescope/telescope-file-browser.nvim"
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
          buffer_previewer_maker = new_maker,
          file_ignore_patterns = { ".git/", "node_modules/", "__pycache__/", ".venv/", "target/" },
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          mappings = {
            i = {
              ["<C-e>"] = open_in_tree, -- Press Ctrl+e in any telescope window to jump to the tree
            },
            n = {
              ["<C-e>"] = open_in_tree,
            }
          }
        },
        extensions = {
          file_browser = { theme = "ivy", hijack_netrw = true },
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
        sync_root_with_cwd = true, -- Follow cwd changes so tree matches project root
        on_attach = function(bufnr)
          local api = require('nvim-tree.api')
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set('n', 'q', '<cmd>wincmd p<CR>', { buffer = bufnr, noremap = true, silent = true, desc = "Return to code" })
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
        "javascript", "typescript", "c", "cpp", "python", "html",
        "css", "lua", "markdown", "rust", "toml",
        "go", "gomod", "gowork", "gosum", "gotmpl",
        "java",
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
          java = { "google-java-format" },
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
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, { name = "luasnip" },
        }, {
          { name = "buffer" }, { name = "path" },
        }),
      })
    end,
  },

  -- Mason and related tools for LSP management
  { "williamboman/mason.nvim", cmd = "Mason", config = function() require("mason").setup() end },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = { "html-lsp", "clangd", "ruff", "typescript-language-server", "basedpyright", "rust-analyzer", "gopls", "goimports", "jdtls", "google-java-format" },
        auto_update = false,
        run_on_start = true,
      })
    end,
  },

  -- Diagnostics & Errors Panel
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { modes = { diagnostics = { auto_preview = true } } },
    keys = { { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true<CR>", desc = "Diagnostics / Errors (Trouble)" } },
  },

  { "GCBallesteros/jupytext.nvim", config = function() require("jupytext").setup({ style = "light", output_extension = "py", force_ft = "python" }) end },
  { "echasnovski/mini.bufremove", version = "*", config = function() require("mini.bufremove").setup() end },
  { "mechatroner/rainbow_csv", event = "BufRead" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "tokyonight", component_separators = '|', section_separators = '' } })
    end,
  },
  { "echasnovski/mini.pairs", version = "*", config = function() require("mini.pairs").setup() end },
  { "folke/which-key.nvim", event = "VeryLazy", config = function() require("which-key").setup({ delay = 500 }) end },
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

}, {
  checker = { enabled = true, notify = false, frequency = 86400 },
  change_detection = { notify = false }
})

-- =========================================================================
-- 3. LSP CONFIGURATION 
-- =========================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

vim.lsp.config("*", { capabilities = capabilities })
vim.lsp.config("html", {})   
vim.lsp.config("ts_ls", {})  

vim.lsp.config("clangd", { cmd = { "clangd" }, filetypes = { "c", "cpp", "objc", "objcpp" } })
vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
})
vim.lsp.config("rust_analyzer", { cmd = { "rust-analyzer" }, filetypes = { "rust" }, settings = { ["rust-analyzer"] = { checkOnSave = true, check = { command = "check" }, cargo = { allFeatures = true } } } })

-- Go LSP
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  settings = {
    gopls = { completeUnimported = true, usePlaceholders = true, analyses = { unusedparams = true }, semanticTokens = true },
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

vim.lsp.enable("html")
vim.lsp.enable("ts_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("basedpyright")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("jdtls")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }
    
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
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
vim.opt.incsearch = true   

vim.diagnostic.config({ virtual_text = { severity = vim.diagnostic.severity.ERROR }, signs = true, underline = true, update_in_insert = true })

-- =========================================================================
-- 5. CUSTOM KEYBINDINGS & COMMANDS
-- =========================================================================

-- Utility Command: Clear Telescope Project History
vim.api.nvim_create_user_command("ClearProjects", function()
  local history_file = vim.fn.stdpath("data") .. "/project_nvim/project_history"
  os.remove(history_file)
  print("Project history cleared. (Restart Neovim to reflect changes)")
end, { desc = "Wipe the recent projects list from Telescope" })

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
vim.keymap.set('n', '<leader>d', function()
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
        vim.cmd("enew")
      end

      map("i", "<C-o>", open_as_project)
      map("n", "<C-o>", open_as_project)
      return true -- keep all default mappings
    end,
  })
end, { noremap = true, silent = true, desc = "Directory Browser (Ctrl+o to open as project)" })

-- =========================================================================
-- THE NEW PROJECT / SESSION WORKFLOW
-- =========================================================================
vim.keymap.set('n', '<leader>p', ':AutoSession search<CR>', { noremap = true, silent = true, desc = "Active Projects (Restore Tabs)" })
vim.keymap.set('n', '<leader>fp', ':Telescope projects<CR>', { noremap = true, silent = true, desc = "Find New Project Folders" })

-- THE SIDEBAR (Aerial Code Outline)
vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { noremap = true, silent = true, desc = "Toggle Code Structure Sidebar" })

-- =========================================================================
-- RETURN TO DASHBOARD (Home)
-- =========================================================================
vim.keymap.set('n', '<leader>h', function()
  if vim.bo.filetype == "alpha" then return end
  vim.cmd("silent! wall") -- Save all modified buffers first
  -- Reset cwd to the tracked project root before saving
  if _G._project_root and vim.fn.isdirectory(_G._project_root) == 1 then
    vim.cmd("cd " .. vim.fn.fnameescape(_G._project_root))
  end
  vim.cmd("AutoSession save") -- Save current session
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
      vim.cmd("bdelete! " .. bufnr)
    end
  end
  vim.v.this_session = "" -- Clear session to prevent overwriting on next project
  vim.cmd("Alpha") -- Open Dashboard
end, { noremap = true, silent = true, desc = "Save & Return to Dashboard" })


-- File Tree Toggle
local function toggle_tree_focus()
  if vim.bo.filetype == "NvimTree" then
    -- Find the first normal (non-sidebar) window to switch to,
    -- instead of relying on wincmd p which fails when there is
    -- no "previous window" (e.g. right after session restore).
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and ft ~= "NvimTree" and ft ~= "aerial" and ft ~= "toggleterm" and ft ~= "trouble" then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    vim.cmd("wincmd p") -- fallback
  else
    vim.cmd("NvimTreeFocus")
  end
end
vim.keymap.set({'n', 'i', 'v'}, '<C-M-e>', toggle_tree_focus, { noremap = true, silent = true, desc = "Toggle Tree Focus" })

-- Buffer Navigation
vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<CR>', { noremap = true, silent = true, desc = "Next File Tab" })
vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', { noremap = true, silent = true, desc = "Previous File Tab" })

-- Window Split Navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
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

-- Auto-open binary files in OS viewer instead of Neovim
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.pdf", "*.mp4", "*.mkv", "*.avi", "*.mp3", "*.zip", "*.tar", "*.gz" },
  callback = function(args)
    local path = vim.fn.expand(args.match)
    if vim.fn.has('mac') == 1 then vim.fn.jobstart({ 'open', path }, { detach = true })
    elseif vim.fn.has('unix') == 1 then vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
    elseif vim.fn.has('win32') == 1 then vim.fn.jobstart({ 'cmd', '/c', 'start', '""', path }, { detach = true }) end
    
    -- Schedule buffer deletion so it doesn't interrupt the current event loop
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
  print("Starting safe system update...")
  vim.cmd("Lazy update")
  vim.cmd("MasonToolsUpdate")
end, { noremap = true, silent = true, desc = "Update Plugins & Tools" })

-- =========================================================================
-- 7. CODE EXECUTION
-- =========================================================================
vim.keymap.set('v', '<leader>r', ':<C-U>ToggleTermSendVisualLines<CR>', { noremap = true, silent = true, desc = "Run Selected Lines" })
vim.keymap.set('n', '<leader>r', '<cmd>ToggleTermSendCurrentLine<CR><cmd>norm j<CR>', { noremap = true, silent = true, desc = "Run Current Line" })

vim.keymap.set('n', '<leader>R', function()
  local file = vim.fn.expand('%')
  local ext = vim.fn.expand('%:e')
  local escaped = vim.fn.shellescape(file)
  vim.cmd("w") 
  if ext == 'py' or ext == 'ipynb' then vim.cmd('TermExec cmd="uv run python ' .. escaped .. '"')
  elseif ext == 'c' then vim.cmd('TermExec cmd="gcc ' .. escaped .. ' -o out && ./out"')
  elseif ext == 'cpp' then vim.cmd('TermExec cmd="g++ ' .. escaped .. ' -o out && ./out"')
  elseif ext == 'js' or ext == 'ts' then vim.cmd('TermExec cmd="node ' .. escaped .. '"')
  elseif ext == 'rs' then vim.cmd('TermExec cmd="cargo run"')
  elseif ext == 'go' then vim.cmd('TermExec cmd="go run ' .. escaped .. '"')
  elseif ext == 'java' then vim.cmd('TermExec cmd="javac ' .. escaped .. ' && java ' .. vim.fn.shellescape(vim.fn.expand('%:t:r')) .. '"')
  end
end, { noremap = true, silent = true, desc = "Execute Current File" })

-- =========================================================================
-- 8. TERMINAL MULTIPLEXING
-- =========================================================================
local status_ok, tt_api = pcall(require, "toggleterm.terminal")
if status_ok then
  local Terminal = tt_api.Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float", float_opts = { border = "curved" } })
  function _lazygit_toggle() lazygit:toggle() end
  vim.keymap.set('n', '<leader>gg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true, desc = "Toggle Lazygit" })

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
