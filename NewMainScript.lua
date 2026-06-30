-- Polyfill for executors missing these globals
local delfile = delfile or function(file) writefile(file, '') end

for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

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

-- Hook require to fix executor's broken __call metamethod on RobloxScript modules
local origRequire = require
require = function(mod)
	local suc, res = pcall(origRequire, mod)
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

-- Block Kick with Bedwars message using direct metatable modification
if getrawmetatable and getnamecallmethod then
	local mt = getrawmetatable(game)
	if mt then
		local oldNamecall = mt.__namecall
		mt.__namecall = function(...)
			local method = getnamecallmethod()
			if method == "Kick" then
				local args = {...}
				for i = 1, #args do
					if type(args[i]) == "string" and args[i]:find("Bedwars") then
						return
					end
				end
			end
			return oldNamecall(...)
		end
	end
end

-- Download game config from VapeCompiled
local pid = tostring(game.PlaceId)
if pid ~= '0' and not isfile('newvape/games/'..pid..'.lua') then
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		writefile('newvape/games/'..pid..'.lua', '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
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
