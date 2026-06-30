-- Minimal script: exact original flow + only kick removal via source gsub
local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end

local delfile = delfile or function(file) writefile(file, '') end

for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Ensure main.lua is fresh from VapeCompiled
local function downloadFile(path, func)
	if not isfile(path) then
		local commit = (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt')) or 'main'
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

-- Write commit as 'main' like original did  
writefile('newvape/profiles/commit.txt', 'main')

-- Pre-download game config with kick stripped
local pid = tostring(game.PlaceId)
if pid ~= '0' then
	local gpath = 'newvape/games/'..pid..'.lua'
	-- Always re-download to ensure kick is removed
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		res = res:gsub("lplr:Kick%b()", "")
		writefile(gpath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
