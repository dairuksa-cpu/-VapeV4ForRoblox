for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

local delfile = delfile or function(file) writefile(file, '') end

-- Delete stale VapeV4ForRoblox cached files AND any cached game config that still has a kick
for _, dir in {'newvape/games', 'newvape/main.lua', 'newvape/libraries'} do
	if isfile(dir) then
		local c = readfile(dir)
		if c and (c:find('VapeV4ForRoblox') or c:find('lplr:Kick')) then delfile(dir) end
	elseif isfolder(dir) then
		for _, f in listfiles(dir) do
			if isfile(f) then
				local c = readfile(f)
				if c and (c:find('VapeV4ForRoblox') or c:find('lplr:Kick')) then delfile(f) end
			end
		end
	end
end

-- Hook require: try setthreadidentity if available, fallback to bytecode
local origRequire = require
require = function(mod)
	local oldId
	local hasId = (type(getthreadidentity) == 'function')
	if hasId then
		oldId = getthreadidentity()
		setthreadidentity(2)
	end
	local suc, res = pcall(origRequire, mod)
	if hasId then setthreadidentity(oldId) end
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

-- Download game config fresh every time, strip any kick from source
local pid = tostring(game.PlaceId)
if pid ~= '0' then
	local gpath = 'newvape/games/'..pid..'.lua'
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		-- Strip lplr:Kick with any argument from source (guaranteed removal)
		res = res:gsub("lplr:Kick%b()", "")
		res = res:gsub("lplr:Kick%b()", "")
		-- Also strip any other form of Kick call with Bedwars
		res = res:gsub("playersService%.LocalPlayer:Kick%b()", "")
		res = res:gsub("Players%.LocalPlayer:Kick%b()", "")
		writefile(gpath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

-- Fresh main.lua every time
local suc, res = pcall(function()
	return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/main.lua', true)
end)
if not suc or not res or res == '404: Not Found' then
	error('Failed to download main.lua: ' .. tostring(res))
end
writefile('newvape/main.lua', '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
writefile('newvape/profiles/commit.txt', 'main')

-- Load Vape inside pcall so game config errors don't crash everything
local fn, loadErr = loadstring(readfile('newvape/main.lua'), 'main')
if not fn then error('Failed to compile main.lua: ' .. tostring(loadErr)) end
local suc, result = pcall(fn)
if not suc then error('Vape runtime error: ' .. tostring(result)) end
return result
