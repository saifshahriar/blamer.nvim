local config_mod = require("blamer.config")
local git = require("blamer.git")
local ui = require("blamer.ui")

local M = {}

local blamer_buffer_enabled = false
local blamer_show_enabled = false
local blamer_timer_id = -1

local function stop_timer()
	if blamer_timer_id ~= -1 then
		vim.fn.timer_stop(blamer_timer_id)
		blamer_timer_id = -1
	end
end

local function get_lines()
	local visual_line_number = vim.fn.line("v")
	local cursor_line_number = vim.fn.line(".")

	if visual_line_number < cursor_line_number then
		return vim.fn.range(visual_line_number, cursor_line_number)
	elseif cursor_line_number < visual_line_number then
		return vim.fn.range(cursor_line_number, visual_line_number)
	else
		return { cursor_line_number }
	end
end

function M.show()
	local config = config_mod.get()
	if not config.enabled or not blamer_buffer_enabled then
		return
	end

	if vim.bo.buftype ~= "" then
		return
	end

	local file_path = git.substitute_path_separator(vim.fn.expand("%:p"))
	if file_path == "" then
		return
	end

	local line_numbers = get_lines()
	if #line_numbers > 1 and not config.show_in_visual_modes then
		return
	end

	local line_count = #line_numbers
	local messages, err = git.get_messages(file_path, line_numbers[1], line_count)
	if err == "not_git" then
		blamer_buffer_enabled = false
		return
	end
	if not messages then
		return
	end

	ui.show(vim.fn.bufnr(""), line_numbers, messages)
end

function M.hide()
	ui.hide(vim.fn.bufnr(""))
end

function M.enable()
	config_mod.get().enabled = true
	blamer_buffer_enabled = git.is_buffer_git_tracked()
end

function M.disable()
	config_mod.get().enabled = false
end

function M.enable_show()
	local config = config_mod.get()
	if not config.enabled or not blamer_buffer_enabled or blamer_show_enabled then
		return
	end

	blamer_show_enabled = true
	M.show()
end

function M.disable_show()
	local config = config_mod.get()
	if not config.enabled or not blamer_buffer_enabled or not blamer_show_enabled then
		return
	end

	blamer_show_enabled = false
	stop_timer()
	M.hide()
end

function M.toggle()
	if config_mod.get().enabled then
		M.disable_show()
		M.disable()
	else
		M.enable()
		M.enable_show()
	end
end

local function refresh()
	local config = config_mod.get()
	if not config.enabled or not blamer_buffer_enabled or not blamer_show_enabled then
		return
	end

	stop_timer()
	M.hide()
	blamer_timer_id = vim.fn.timer_start(config.delay, function()
		M.show()
	end)
end

local function buffer_enter()
	if not config_mod.get().enabled then
		return
	end

	if git.is_buffer_git_tracked() then
		blamer_buffer_enabled = true
		git.update_git_user_config()
		M.enable_show()
	else
		blamer_buffer_enabled = false
	end
end

local function buffer_leave()
	if not config_mod.get().enabled then
		return
	end

	M.disable_show()
end

function M.setup(opts)
	config_mod.setup(opts)
	if vim.g.blamer_is_initialized then
		return
	end
	vim.g.blamer_is_initialized = true

	local config = config_mod.get()
	local group = vim.api.nvim_create_augroup("blamer", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", { group = group, callback = buffer_enter })
	vim.api.nvim_create_autocmd("BufLeave", { group = group, callback = buffer_leave })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "CursorMoved" }, { group = group, callback = refresh })

	if not config.show_in_insert_modes then
		vim.api.nvim_create_autocmd("InsertEnter", { group = group, callback = M.disable_show })
		vim.api.nvim_create_autocmd("InsertLeave", { group = group, callback = M.enable_show })
	end

	vim.api.nvim_create_user_command("BlamerShow", function()
		M.enable()
		M.enable_show()
	end, {})

	vim.api.nvim_create_user_command("BlamerHide", function()
		M.disable_show()
		M.disable()
	end, {})

	vim.api.nvim_create_user_command("BlamerToggle", function()
		M.toggle()
	end, {})

	vim.api.nvim_set_hl(0, "Blamer", { link = "Comment", default = true })
end

return M
