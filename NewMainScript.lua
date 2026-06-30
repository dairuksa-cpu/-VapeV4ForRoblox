for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not isfile('newvape/profiles/commit.txt') then
	writefile('newvape/profiles/commit.txt', 'main')
end

local placeId = tostring(game.PlaceId)
local gameConfigPath = 'newvape/games/'..placeId..'.lua'
local commit = readfile('newvape/profiles/commit.txt')

-- Shared module cache (lives in _G so the injected wrapper can access it)
_G.__vapeModCache = setmetatable({}, {__mode = 'v'})

-- Pre-download game config, strip kick, inject require wrapper
local function buildGameConfig(content)
	-- Strip kick
	if content:find("lplr:Kick") then
		content = content:gsub("lplr:Kick%b()", "")
	end

	-- Inject require wrapper at the TOP of the file as a local variable.
	-- All nested functions inside this chunk will capture it as an upvalue.
	local wrapper = [[
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

	return wrapper .. content
end

if isfile(gameConfigPath) then
	local content = readfile(gameConfigPath)
	if content:find("lplr:Kick") or not content:find("__vape_require") then
		content = buildGameConfig(content)
		writefile(gameConfigPath, content)
	end
else
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/games/'..placeId..'.lua', true)
	end)
	if suc and res and not res:find('404') then
		res = buildGameConfig(res)
		writefile(gameConfigPath, '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

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
