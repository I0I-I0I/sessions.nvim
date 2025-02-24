local sessions = require("sessions")

vim.api.nvim_create_user_command("SessionsList", function()
	sessions.open_list()
end, {})

vim.api.nvim_create_user_command("SessionSave", function()
	sessions.save_session()
end, {})

vim.api.nvim_create_user_command("SessionCreate", function()
	sessions.create_session()
end, {})

vim.api.nvim_create_user_command("SessionAttach", function()
	local _, err = pcall(sessions.attach_session)
	if err then
		print("Cann't found session here")
	end
end, {})
