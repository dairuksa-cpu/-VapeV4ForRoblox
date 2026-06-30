for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

local delfile = delfile or function(file) writefile(file, '') end

-- Purge any stale cached files containing kick or VapeV4ForRoblox
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

-- Hook require: try setthreadidentity, fallback to bytecode
local origRequire = require
require = function(mod)
	local oldId
	local hasId = (type(getthreadidentity) == 'function' and type(setthreadidentity) == 'function')
	if hasId then oldId = getthreadidentity(); setthreadidentity(2) end
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

-- Hook loadstring: strip kick from game configs right before Vape executes them
local origLoadstring = loadstring
loadstring = function(str, chunkname)
	if chunkname and type(str) == 'string' and str:find('lplr:Kick') then
		str = str:gsub("lplr:Kick%b()", "")
	end
	return origLoadstring(str, chunkname)
end

-- Force download game config fresh each time, strip any kick from source
local pid = tostring(game.PlaceId)
if pid ~= '0' then
	local gpath = 'newvape/games/'..pid..'.lua'
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		res = res:gsub("lplr:Kick%b()", "")
		res = res:gsub("lplr:Kick%b()", "")
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

-- Backup: __namecall hook directly on lplr
if hookmetamethod and getnamecallmethod then
	local lplr = game:GetService('Players').LocalPlayer
	if lplr then
		local old = hookmetamethod(lplr, "__namecall", function(...)
			local method = getnamecallmethod()
			if method == "Kick" then
				local args = {...}
				for i = 1, #args do
					if type(args[i]) == "string" and args[i]:find("Bedwars") then
						return
					end
				end
			end
			return old(...)
		end)
	end
end

-- Load Vape inside pcall
local fn, loadErr = loadstring(readfile('newvape/main.lua'), 'main')
if not fn then error('Failed to compile main.lua: ' .. tostring(loadErr)) end
local suc, result = pcall(fn)
if not suc then error('Vape runtime error: ' .. tostring(result)) end
return result
