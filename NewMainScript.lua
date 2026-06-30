for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not isfile('newvape/profiles/commit.txt') then
	writefile('newvape/profiles/commit.txt', 'main')
end

-- Pre-download & strip kick from game config before Vape runs
local placeId = tostring(game.PlaceId)
local gameConfigPath = 'newvape/games/'..placeId..'.lua'
local commit = readfile('newvape/profiles/commit.txt')

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
		writefile(gameConfigPath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

-- Hook require via hookfunction (C-level, can't be silently ignored)
local moduleCache = setmetatable({}, {__mode = 'v'})
local origRequire = hookfunction(require, function(mod)
	if moduleCache[mod] then return moduleCache[mod] end

	-- Try 1: normal require (works for most modules)
	local suc, res = pcall(origRequire, mod)
	if suc then moduleCache[mod] = res; return res end

	-- Try 2: setthreadidentity(2) + require
	local oldId = getthreadidentity()
	setthreadidentity(2)
	local suc2, res2 = pcall(origRequire, mod)
	setthreadidentity(oldId)
	if suc2 then moduleCache[mod] = res2; return res2 end

	-- Try 3: getscriptbytecode + loadstring
	local suc3, bc = pcall(getscriptbytecode, mod)
	if suc3 and bc and #bc > 0 then
		local fn = loadstring(bc)
		if fn then
			local suc4, res4 = pcall(fn)
			if suc4 then moduleCache[mod] = res4; return res4 end
		end
		local src = decompile(mod)
		if src and #src > 0 then
			local fn2 = loadstring(src)
			if fn2 then
				local suc4, res4 = pcall(fn2)
				if suc4 then moduleCache[mod] = res4; return res4 end
			end
		end
	end

	-- Proxy fallback (keeps Vape from crashing, features get stubs)
	local proxy = setmetatable({}, {
		__index = function() return function() end end,
		__call = function() return proxy end
	})
	moduleCache[mod] = proxy
	return proxy
end)

-- Hook loadstring (backup defense)
local origLoadstring = hookfunction(loadstring, function(str, chunkname)
	if type(str) == "string" and str:find("lplr:Kick") then
		str = str:gsub("lplr:Kick%b()", "")
	end
	return origLoadstring(str, chunkname)
end)

-- Hook readfile (backup defense)
local origReadfile = hookfunction(readfile, function(path)
	local content = origReadfile(path)
	if type(content) == "string" and content:find("lplr:Kick") then
		content = content:gsub("lplr:Kick%b()", "")
	end
	return content
end)

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
