local config_mod = require("blamer.config")

local M = {}

local user_name = ""
local user_email = ""

local is_windows = vim.fn.has("win16") == 1
	or vim.fn.has("win32") == 1
	or vim.fn.has("win64") == 1
	or vim.fn.has("win95") == 1

local function head(array)
	if #array == 0 then
		return ""
	end
	return array[1]
end

local function get_relative_time(commit_timestamp)
	local current_timestamp = vim.fn.localtime()
	local elapsed = current_timestamp - commit_timestamp

	local minute_seconds = 60
	local hour_seconds = minute_seconds * 60
	local day_seconds = hour_seconds * 24
	local month_seconds = day_seconds * 30
	local year_seconds = month_seconds * 12

	if elapsed == 0 then
		return "a while ago"
	end

	local function to_relative_string(time, divisor, time_word)
		local count = math.floor(time / divisor + 0.5)
		local plural = count > 1 and time_word .. "s" or time_word
		return count .. " " .. plural .. " ago"
	end

	if elapsed < minute_seconds then
		return to_relative_string(elapsed, 1, "second")
	elseif elapsed < hour_seconds then
		return to_relative_string(elapsed, minute_seconds, "minute")
	elseif elapsed < day_seconds then
		return to_relative_string(elapsed, hour_seconds, "hour")
	elseif elapsed < month_seconds then
		return to_relative_string(elapsed, day_seconds, "day")
	elseif elapsed < year_seconds then
		return to_relative_string(elapsed, month_seconds, "month")
	else
		return to_relative_string(elapsed, year_seconds, "year")
	end
end

local function commit_data_to_message(commit_data)
	local config = config_mod.get()
	local message = config.template
	for _, field in ipairs(config.fields) do
		message = message:gsub(vim.pesc("<" .. field .. ">"), function()
			return commit_data[field] or ""
		end)
	end
	return message
end

local function parse_commit_data_line(line)
	local config = config_mod.get()
	local words = vim.split(line, " ", { plain = true, trimempty = true })
	local property = words[1]
	local value = table.concat(words, " ", 2)

	if property:lower():find("time", 1, true) then
		if config.relative_time then
			value = get_relative_time(tonumber(value))
		else
			value = vim.fn.strftime(config.date_format, tonumber(value))
		end
	end

	if value:lower() == user_name:lower() or value:lower() == user_email:lower() then
		value = "You"
	end

	return { [property] = value }
end

local function buffer_dir()
	return vim.fn.shellescape(M.substitute_path_separator(vim.fn.expand("%:h")))
end

function M.substitute_path_separator(path)
	return is_windows and path:gsub("\\", "/") or path
end

function M.get_messages(file, line_number, line_count)
	local end_line = line_number + line_count - 1
	local file_path_escaped = vim.fn.shellescape(file)
	local command = "LC_ALL=C git -C "
		.. buffer_dir()
		.. " --no-pager blame --line-porcelain -L "
		.. line_number
		.. ","
		.. end_line
		.. " -- "
		.. file_path_escaped

	local result = vim.fn.system(command)
	local lines = vim.split(result, "\n", { plain = true, trimempty = true })
	if #lines == 0 then
		return nil
	end

	local hash = vim.split(lines[1], " ", { plain = true, trimempty = true })[1]
	local hash_is_empty = not (hash and hash:match(string.rep("%x", 40)))

	if hash_is_empty then
		if result:lower():find("fatal", 1, true) and result:lower():find("not a git repository", 1, true) then
			vim.notify("[blamer.nvim] Not a git repository", vim.log.levels.WARN, { title = "blamer.nvim" })
			return nil, "not_git"
		end

		if result:lower():find("no matches found", 1, true) then
			return nil
		elseif result:lower():find("no such path", 1, true) then
			return nil
		elseif result:lower():find("is outside repository", 1, true) then
			return nil
		elseif result:lower():find("has only", 1, true) and result:lower():find("lines", 1, true) then
			return nil
		elseif result:lower():find("no such ref", 1, true) then
			return nil
		end

		vim.notify("[blamer.nvim] " .. result, vim.log.levels.ERROR, { title = "blamer.nvim" })
		return nil
	end

	local tab_ascii = 9
	local commit_data = {}
	local commit_data_per_line = {}

	for _, line in ipairs(lines) do
		local line_words = vim.split(line, " ", { plain = true, trimempty = true })
		local first = line_words[1]
		local is_line_hash = first:match(string.rep("%x", 40)) ~= nil
		local has_line_tab = first:byte() == tab_ascii

		if is_line_hash then
			commit_data = {
				["commit-short"] = first:sub(1, 8),
				["commit-long"] = first,
			}
		elseif has_line_tab then
			if (commit_data.author or ""):lower() == "not committed yet" then
				commit_data.author = "You"
				commit_data.committer = "You"
				commit_data.summary = "Uncommitted changes"
			end
			commit_data_per_line[#commit_data_per_line + 1] = vim.deepcopy(commit_data)
		else
			commit_data = vim.tbl_extend("force", commit_data, parse_commit_data_line(line))
		end
	end

	return vim.tbl_map(commit_data_to_message, commit_data_per_line)
end

function M.update_git_user_config()
	local dir_path = buffer_dir()
	user_name =
		head(vim.split(vim.fn.system("git -C " .. dir_path .. " config --get user.name"), "\n", { plain = true }))
	user_email =
		head(vim.split(vim.fn.system("git -C " .. dir_path .. " config --get user.email"), "\n", { plain = true }))
end

function M.is_buffer_git_tracked()
	local file_path = vim.fn.shellescape(M.substitute_path_separator(vim.fn.expand("%:p")))
	if file_path == "" then
		return false
	end

	local dir_path = vim.fn.shellescape(M.substitute_path_separator(vim.fn.expand("%:h")))
	local result = vim.fn.system("git -C " .. dir_path .. " ls-files --error-unmatch " .. file_path)
	if result:sub(1, 5) == "fatal" then
		return false
	end

	return true
end

return M
