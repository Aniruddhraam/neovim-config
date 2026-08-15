-- Ensure ~/.local/bin and ~/go/bin are in PATH across all operating systems (Linux, macOS, Windows)
local is_win = vim.fn.has("win32") == 1
local path_sep = is_win and ";" or ":"
local extra_paths = {
  vim.fn.expand("~/.local/bin"),
  vim.fn.expand("~/go/bin"),
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

      -- Handle tab/buffer switches: re-open or close aerial as needed
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "" or ft == "aerial" or ft == "NvimTree" or ft == "alpha" or ft == "toggleterm" or ft == "trouble" then
            return
          end
          -- If user explicitly closed aerial, keep it closed globally
          if _G._aerial_user_closed then return end
          vim.defer_fn(function()
            if not vim.api.nvim_buf_is_valid(args.buf) then return end
            if vim.api.nvim_get_current_buf() ~= args.buf then return end
            local curr_ft = vim.bo[args.buf].filetype
            if curr_ft == "" or curr_ft == "aerial" or curr_ft == "NvimTree" or curr_ft == "alpha" or curr_ft == "toggleterm" or curr_ft == "trouble" then
              return
            end
            if _G._aerial_user_closed then return end
            local ok, aerial = pcall(require, "aerial")
            if not ok then return end
            local ok_count, count = pcall(aerial.num_symbols, args.buf)
            if ok_count and count and count > 0 then
              if not aerial.is_open({ bufnr = args.buf }) then
                pcall(aerial.open, { bufnr = args.buf, focus = false })
              end
            else
              local backends = require("aerial.backends").get_status(args.buf)
              local has_supported = false
              for _, b in ipairs(backends or {}) do
                if b.supported then has_supported = true; break end
              end
              if not has_supported and aerial.is_open() then
                pcall(aerial.close)
              end
            end
          end, 300)
        end,
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
      require("nvim-tree").setup({
        sync_root_with_cwd = true, -- Follow cwd changes so tree matches project root
        on_attach = function(bufnr)
          local api = require('nvim-tree.api')
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set('n', 'q', '<cmd>wincmd p<CR>', { buffer = bufnr, noremap = true, silent = true, desc = "Return to code" })
        end,
        view = { width = 35, side = "left" },
        filesystem_watchers = {
          enable = true,
          debounce_delay = 50,
          ignore_dirs = {},
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

  -- Formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          python = { "ruff_format" },
          c = { "clang-format" },
          cpp = { "clang-format" },
          rust = { "rustfmt" },
          go = { "goimports", "gofmt" },
          java = { "google-java-format" },
        },
        format_on_save = { timeout_ms = vim.fn.has("win32") == 1 and 3000 or 1000, lsp_format = "fallback" },
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
        window = {
          completion = cmp.config.window.bordered({ border = "rounded" }),
          documentation = cmp.config.window.bordered({ border = "rounded" }),
        },
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
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
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = { "prettier", "clang-format", "html-lsp", "clangd", "ruff", "typescript-language-server", "basedpyright", "rust-analyzer", "gopls", "goimports", "delve", "jdtls", "google-java-format", "texlab" },
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

      -- Helper to find the actual delve binary executable (handles Windows .cmd vs .exe, Mason, GOPATH, and Unix)
      local function get_delve_path()
        local is_win = vim.fn.has("win32") == 1
        local ext = is_win and ".exe" or ""

        -- 1. Check Mason packages directory (direct binary, bypassing Windows .CMD wrappers)
        local mason_pkg = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "delve", "dlv" .. ext)
        if vim.uv.fs_stat(mason_pkg) then
          return mason_pkg
        end

        -- 2. Check ~/go/bin
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
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "aerial", "NvimTree", "" },
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
          ["cmp.entry.get_documentation"] = true,
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
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

vim.lsp.config("*", { capabilities = capabilities })
vim.lsp.config("html", {})   
vim.lsp.config("ts_ls", {})  

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

-- LaTeX LSP
vim.lsp.config("texlab", {
  cmd = { "texlab" },
  filetypes = { "tex", "plaintex", "bib" },
})

vim.lsp.enable("html")
vim.lsp.enable("ts_ls")
vim.lsp.enable("clangd")
vim.lsp.enable("basedpyright")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("jdtls")
vim.lsp.enable("texlab")

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
vim.opt.updatetime = 300   -- Fast CursorHold trigger for diagnostic popups

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
        vim.cmd("enew")
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
