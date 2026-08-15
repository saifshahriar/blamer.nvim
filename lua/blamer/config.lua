local M = {}

local defaults = {
	enabled = false,
	delay = 1000,
	show_in_visual_modes = true,
	show_in_insert_modes = true,
	prefix = "   ",
	template = "<author>, <author-time> • <summary>",
	date_format = "%d/%m/%y %H:%M",
	relative_time = false,
}

local config = vim.deepcopy(defaults)

local function parse_template_fields(template)
	local fields = {}
	for word in template:gmatch("%S+") do
		local field = word:match("<([^<>]+)>")
		if field then
			fields[#fields + 1] = field
		end
	end
	return fields
end

function M.get()
	return config
end

function M.setup(opts)
	opts = opts or {}
	for key, value in pairs(opts) do
		config[key] = value
	end
	config.fields = parse_template_fields(config.template)
end

return M
