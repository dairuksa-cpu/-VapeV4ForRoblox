for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not isfile('newvape/profiles/commit.txt') then
	writefile('newvape/profiles/commit.txt', 'main')
end

-- Module cache accessible from anywhere via _G
_G.__vapeModCache = setmetatable({}, {__mode = 'v'})

-- Try to set global require wrapper (might be silently ignored, but worth trying)
-- Must be done BEFORE Vape runs
_G.__vape_orig_require = require
_G.require = function(mod)
	local cache = _G.__vapeModCache
	if cache[mod] then return cache[mod] end

	local suc, res = pcall(_G.__vape_orig_require, mod)
	if suc then cache[mod] = res; return res end

	local oldId = getthreadidentity()
	setthreadidentity(2)
	suc, res = pcall(_G.__vape_orig_require, mod)
	setthreadidentity(oldId)
	if suc then cache[mod] = res; return res end

	local suc2, bc = pcall(getscriptbytecode, mod)
	if suc2 and bc and #bc > 0 then
		local fn = loadstring(bc)
		if fn then
			suc, res = pcall(fn)
			if suc then cache[mod] = res; return res end
		end
		local src = decompile(mod)
		if src and #src > 0 then
			local fn2 = loadstring(src)
			if fn2 then
				suc, res = pcall(fn2)
				if suc then cache[mod] = res; return res end
			end
		end
	end

	local proxy = setmetatable({}, {
		__index = function() return function() end end,
		__call = function() return proxy end
	})
	cache[mod] = proxy
	return proxy
end

-- Strip kick from existing cached game config file
local placeId = tostring(game.PlaceId)
local gameConfigPath = 'newvape/games/'..placeId..'.lua'
if isfile(gameConfigPath) then
	local content = readfile(gameConfigPath)
	if content:find("lplr:Kick") then
		content = content:gsub("lplr:Kick%b()", "")
		writefile(gameConfigPath, content)
	end
end

-- Download & run Vape's main.lua
local commit = readfile('newvape/profiles/commit.txt')
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

-- Also inject require wrapper into game config file if Vape already downloaded it
-- (This handles the case where the file appears AFTER our initial check but BEFORE main.lua runs)
if isfile(gameConfigPath) then
	local content = readfile(gameConfigPath)
	if not content:find("__vape_require_injected") then
		local wrapper = [[
-- __vape_require_injected
local __vape_orig_require = require
local __vape_require = function(mod)
	local cache = _G.__vapeModCache
	if cache[mod] then return cache[mod] end

	local suc, res = pcall(__vape_orig_require, mod)
	if suc then cache[mod] = res; return res end

	local oldId = getthreadidentity()
	setthreadidentity(2)
	suc, res = pcall(__vape_orig_require, mod)
	setthreadidentity(oldId)
	if suc then cache[mod] = res; return res end

	local suc2, bc = pcall(getscriptbytecode, mod)
	if suc2 and bc and #bc > 0 then
		local fn = loadstring(bc)
		if fn then
			suc, res = pcall(fn)
			if suc then cache[mod] = res; return res end
		end
		local src = decompile(mod)
		if src and #src > 0 then
			local fn2 = loadstring(src)
			if fn2 then
				suc, res = pcall(fn2)
				if suc then cache[mod] = res; return res end
			end
		end
	end

	local proxy = setmetatable({}, {
		__index = function() return function() end end,
		__call = function() return proxy end
	})
	cache[mod] = proxy
	return proxy
end
local require = __vape_require
]]
		content = wrapper .. content
		writefile(gameConfigPath, content)
	end
end

return loadstring(downloadVapeFile('newvape/main.lua'), 'main')()
