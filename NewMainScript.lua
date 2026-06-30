for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Ensure commit file exists
if not isfile('newvape/profiles/commit.txt') then
	writefile('newvape/profiles/commit.txt', 'main')
end

-- Pre-download & strip kick from game config BEFORE Vape runs
local placeId = tostring(game.PlaceId)
local gameConfigPath = 'newvape/games/'..placeId..'.lua'
local commit = readfile('newvape/profiles/commit.txt')

-- If file exists with kick, strip it. If not, download + strip + save
if isfile(gameConfigPath) then
	local content = readfile(gameConfigPath)
	if content and content:find("lplr:Kick") then
		content = content:gsub("lplr:Kick%b()", "")
		writefile(gameConfigPath, content)
	end
else
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/games/'..placeId..'.lua', true)
	end)
	if suc and res and not res:find('404') then
		if res:find("lplr:Kick") then
			res = res:gsub("lplr:Kick%b()", "")
		end
		local watermark = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'
		writefile(gameConfigPath, watermark..res)
	end
end

-- Hooks as backup (try multiple envs)
local genv = getgenv()
local origLoadstring = genv.loadstring
if origLoadstring then
	genv.loadstring = function(str, chunkname)
		if type(str) == "string" and str:find("lplr:Kick") then
			str = str:gsub("lplr:Kick%b()", "")
		end
		return origLoadstring(str, chunkname)
	end
end

local origReadfile = genv.readfile
if origReadfile then
	genv.readfile = function(path)
		local content = origReadfile(path)
		if type(content) == "string" and content:find("lplr:Kick") then
			content = content:gsub("lplr:Kick%b()", "")
		end
		return content
	end
end

-- Require hook (setthreadidentity + bytecode + proxy)
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
	local proxy = setmetatable({}, {
		__index = function() return function() end end,
		__call = function() return proxy end
	})
	moduleCache[mod] = proxy
	return proxy
end

-- Download & run Vape's main.lua
local function downloadVapeFile(path)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return readfile(path)
end

return loadstring(downloadVapeFile('newvape/main.lua'), 'main')()
