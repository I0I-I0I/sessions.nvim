local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local dropdown = require("telescope.themes").get_dropdown()

M.var = {}

M.var.marker = "FOR_TELESCOPE"
M.var.dirs = {}

function M.setup(opts)
	M.var.path = opts.path or "~/sessions/"
	M.var.attach_after_enter = opts.attach_after_enter or false
end

function M.attach_session()
	vim.cmd("silent source " .. M.var.path .. vim.fn.getcwd():gsub("/", ":") .. ".vim")
end

local function delete_session(prompt_bufnr)
	actions.close(prompt_bufnr)
	local selected = action_state.get_selected_entry()[1]
	local selected_copy = selected:sub(1, -1)
	selected = selected:gsub(" ", "_")
	local dir = M.var.dirs[selected]
	local file = dir:gsub("/", ":"):sub(1, -1) .. ".vim"

	vim.cmd("silent !rm -rf " .. M.var.path .. file)
	vim.cmd(
		"silent !rm -rf "
		.. M.var.path
		.. M.var.marker
		.. "\\(" .. selected:gsub('"', '\\"'):sub(1, -1) .. "\\)"
		.. file
	)
	print("Session deleted: " .. selected_copy)
	vim.cmd("SessionsList")
end

function M.enter(prompt_bufnr)
	actions.close(prompt_bufnr)
	local selected = action_state.get_selected_entry()
	local dir = selected[1]:gsub(" ", "_")

	vim.cmd("cd " .. M.var.dirs[dir])

	if M.var.attach_after_enter then
		M.attach_session()
	end
end

local function get_dirs()
	M.var.dirs = {}
	for k, _ in vim.fn.execute("!ls " .. M.var.path):gmatch("[A-Za-z_.:|0-9()\"'\\-]+.vim") do
		local dir = k:gsub(":", "/"):sub(1, -5)
		if dir:match(M.var.marker) then
			local session_name = dir:match("[(](.+)[)]")
			dir = dir:match(M.var.marker .. "[(].+[)](.*)")

			M.var.dirs[session_name] = dir
		end
	end
	return M.var.dirs
end

local function get_options()
	local sessions = {}
	for session_name, dir in pairs(get_dirs()) do
		table.insert(sessions, session_name:gsub("_", " "):sub(1, -1))
	end
	table.sort(sessions)

	return {
		preview = true,
		prompt_title = "🗃️ All sessions",
		finder = finders.new_table({
			results = sessions,
		}),
		sorter = sorters.get_generic_fuzzy_sorter(),

		attach_mappings = function(prompt_bufnr, map)
			map({ "n", "i" }, "<CR>", M.enter)
			map("n", "dd", delete_session)
			map("i", "<C-d>", delete_session)
			return true
		end,
	}
end

function M.save_session()
	vim.cmd("mksession! " .. M.var.path .. vim.fn.getcwd():gsub("/", ":") .. ".vim")
end

function M.create_session()
	M.save_session()
	local prompt = vim.fn.input("Enter Session Name: ")
	local prompt_copy = prompt:sub(1, -1)
	if prompt == "" then
		return
	end
	prompt = prompt:gsub(" ", "_")
	prompt = prompt:gsub('"', '\\"')
	vim.cmd(
		"silent !touch "
		.. M.var.path
		.. M.var.marker
		.. "\\(" .. prompt .. "\\)"
		.. vim.fn.getcwd():gsub("/", ":")
		.. ".vim"
	)
	print("Session created: " .. prompt_copy)
end

function M.open_list()
	pickers.new(dropdown, get_options()):find()
end

return M
