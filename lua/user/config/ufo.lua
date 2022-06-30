local status_ok, ufo = pcall(require, "ufo")
if not status_ok then
	return
end
-- https://github.com/Aetf/ucw.nvim/blob/main/lua/ucw/units/thirdparty/ufo.lua
local ftMap = {
	vim = "indent",
	go = "indent",
	rust = "indent",
	python = { "indent" },
	git = "",
}

local function selectProviderWithFunc()
	require("ufo").setup({
		provider_selector = function(bufnr, filetype)
			-- use indent provider for c fieltype
			if filetype == "c" then
				return function()
					return require("ufo").getFolds("indent", bufnr)
				end
			end
		end,
	})
end

local handler = function(virtText, lnum, endLnum, width, truncate)
	local newVirtText = {}
	local suffix = ("  %d "):format(endLnum - lnum)
	local sufWidth = vim.fn.strdisplaywidth(suffix)
	local targetWidth = width - sufWidth
	local curWidth = 0
	for _, chunk in ipairs(virtText) do
		local chunkText = chunk[1]
		local chunkWidth = vim.fn.strdisplaywidth(chunkText)
		if targetWidth > curWidth + chunkWidth then
			table.insert(newVirtText, chunk)
		else
			chunkText = truncate(chunkText, targetWidth - curWidth)
			local hlGroup = chunk[2]
			table.insert(newVirtText, { chunkText, hlGroup })
			chunkWidth = vim.fn.strdisplaywidth(chunkText)
			-- str width returned from truncate() may less than 2nd argument, need padding
			if curWidth + chunkWidth < targetWidth then
				suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
			end
			break
		end
		curWidth = curWidth + chunkWidth
	end
	table.insert(newVirtText, { suffix, "MoreMsg" })
	return newVirtText
end

local function customizeFoldText()
	-- global handler
	require("ufo").setup({
		fold_virt_text_handler = handler,
	})
end

local function customizeBufFoldText()
	-- buffer scope handler
	-- will override global handler if it is existed
	local bufnr = vim.api.nvim_get_current_buf()
	require("ufo").setFoldVirtTextHandler(bufnr, handler)
end

ufo.setup({
	provider_selector = function(bufnr, filetype)
		return ftMap[filetype]
	end,
	open_fold_hl_timeout = 200,
	fold_virt_text_handler = handler,
})
