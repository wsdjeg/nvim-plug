--=============================================================================
-- keymaps.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local map = vim.keymap.set

map("n", "<leader>fs", "<cmd>write<cr>", { silent = true, desc = "save current buffer" })
