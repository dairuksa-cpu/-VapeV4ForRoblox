for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Strip kick from game configs at EVERY possible intercept point
local genv = getgenv()

-- 1) Hook loadstring: strip kick right before compilation
local origLoadstring = genv.loadstring
genv.loadstring = function(str, chunkname)
	if type(str) == "string" and str:find("lplr:Kick") then
		str = str:gsub("lplr:Kick%b()", "")
	end
	return origLoadstring(str, chunkname)
end

-- 2) Hook readfile: strip kick when read from disk
local origReadfile = genv.readfile
genv.readfile = function(path)
	local content = origReadfile(path)
	if type(path) == "string" and path:find("newvape/games/") and content and content:find("lplr:Kick") then
		content = content:gsub("lplr:Kick%b()", "")
	end
	return content
end

-- Hook require: try setthreadidentity, bytecode, then graceful proxy
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
