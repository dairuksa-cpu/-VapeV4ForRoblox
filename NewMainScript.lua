-- Minimal script: original Vape flow + kick removal via gsub + require fix for executor

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file) writefile(file, '') end

for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Hook require: try identity trick, then bytecode, finally return a proxy to prevent crashes
local moduleCache = setmetatable({}, {__mode = 'v'})
local origRequire = require
require = function(mod)
	if moduleCache[mod] then return moduleCache[mod] end
	local hasId = (type(getthreadidentity) == 'function' and type(setthreadidentity) == 'function')
	local oldId
	if hasId then oldId = getthreadidentity(); setthreadidentity(2) end
	local suc, res = pcall(origRequire, mod)
	if hasId then setthreadidentity(oldId) end
	if suc then moduleCache[mod] = res; return res end
	local suc2, bc = pcall(getscriptbytecode, mod)
	if suc2 and bc and #bc > 0 then
		local fn, err = loadstring(bc)
		if fn then
			local suc3, res3 = pcall(fn)
			if suc3 then moduleCache[mod] = res3; return res3 end
		end
	end
	-- Return graceful proxy so game config doesn't crash
	local proxy = {}
	setmetatable(proxy, {
		__index = function() return function() end end,
		__call = function() return proxy end
	})
	moduleCache[mod] = proxy
	return proxy
end

-- Pre-download game config with kick stripped
local pid = tostring(game.PlaceId)
if pid ~= '0' then
	local gpath = 'newvape/games/'..pid..'.lua'
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		res = res:gsub("lplr:Kick%b()", "")
		writefile(gpath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

-- Download main.lua from VapeCompiled
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
writefile('newvape/profiles/commit.txt', 'main')

return loadstring(downloadFile('newvape/main.lua'), 'main')()
