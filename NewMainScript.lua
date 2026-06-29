local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local function tryGetCommit()
		local suc, page = pcall(game.HttpGet, game, 'https://github.com/7GrandDadPGN/VapeCompiled', true)
		if not suc or type(page) ~= 'string' then return nil end
		local idx = page:find('currentOid')
		if not idx then return nil end
		local hash = page:sub(idx + 13, idx + 52)
		if #hash == 40 then return hash end
		return nil
	end
	local commit = tryGetCommit() or 'main'
	if (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

-- Pre-download the current game config from VapeCompiled so Vape finds it cached locally
local function preloadGameConfig()
	local pid = tostring(game.PlaceId)
	if pid ~= '0' and not isfile('newvape/games/'..pid..'.lua') then
		local commit = (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt')) or 'main'
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/games/'..pid..'.lua', true)
		end)
		if suc and res and res ~= '404: Not Found' then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			writefile('newvape/games/'..pid..'.lua', res)
		end
	end
end
preloadGameConfig()

-- Hook __namecall to block Kick with Bedwars message
if hookmetamethod and getnamecallmethod then
	local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "Kick" then
			local args = {...}
			for i = 1, #args do
				if type(args[i]) == "string" and args[i]:find("Bedwars") then
					return
				end
			end
		end
		return oldNamecall(self, ...)
	end)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
