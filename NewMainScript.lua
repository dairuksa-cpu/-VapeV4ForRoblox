for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

local delfile = delfile or function(file) writefile(file, '') end

-- Purge stale VapeV4ForRoblox cached files
local function purgeFile(file)
	if isfile(file) then
		local c = readfile(file)
		if c and c:find('VapeV4ForRoblox') then delfile(file) end
	end
end
purgeFile('newvape/main.lua')
if isfolder('newvape/games') then
	for _, f in listfiles('newvape/games') do if isfile(f) then purgeFile(f) end end
end
if isfolder('newvape/libraries') then
	for _, f in listfiles('newvape/libraries') do if isfile(f) then purgeFile(f) end end
end

-- Hook require with setthreadidentity to bypass executor's RobloxScript restriction
local origRequire = require
require = function(mod)
	local oldId = getthreadidentity()
	setthreadidentity(2)
	local suc, res = pcall(origRequire, mod)
	setthreadidentity(oldId)
	if suc then return res end
	local suc2, bc = pcall(getscriptbytecode, mod)
	if suc2 and bc and #bc > 0 then
		local fn, err = loadstring(bc)
		if fn then
			local suc3, res3 = pcall(fn)
			if suc3 then return res3 end
		end
	end
	error(res)
end

-- Download game config from VapeCompiled and strip Bedwars kick from source
local pid = tostring(game.PlaceId)
if pid ~= '0' then
	local gpath = 'newvape/games/'..pid..'.lua'
	if not isfile(gpath) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
		end)
		if suc and res and res ~= '404: Not Found' then
			-- Strip lplr:Kick('Bedwars...') from source so it never executes
			res = res:gsub("lplr:Kick%B%(%)", "")
			res = res:gsub("lplr:Kick%B%(%)", "")
			writefile(gpath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
		end
	end
end

-- Fresh main.lua from VapeCompiled every time
local suc, res = pcall(function()
	return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/main.lua', true)
end)
if not suc or not res or res == '404: Not Found' then
	error('Failed to download main.lua: ' .. tostring(res))
end
writefile('newvape/main.lua', '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
writefile('newvape/profiles/commit.txt', 'main')

-- Load Vape inside pcall so errors don't crash everything
local fn, loadErr = loadstring(readfile('newvape/main.lua'), 'main')
if not fn then error('Failed to compile main.lua: ' .. tostring(loadErr)) end
local suc, result = pcall(fn)
if not suc then error('Vape runtime error: ' .. tostring(result)) end
return result
