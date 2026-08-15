local config_mod = require("blamer.config")

local M = {}

local namespace = vim.api.nvim_create_namespace("blamer")

function M.show(bufnr, line_numbers, messages)
	local prefix = config_mod.get().prefix
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
	for index, line_number in ipairs(line_numbers) do
		vim.api.nvim_buf_set_extmark(bufnr, namespace, line_number - 1, 0, {
			hl_mode = "combine",
			virt_text = { { prefix .. messages[index], "Blamer" } },
		})
	end
end

function M.hide(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

return M
