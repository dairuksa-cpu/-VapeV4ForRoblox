for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end
writefile('newvape/profiles/commit.txt', 'main')

_G.__vapeModCache = setmetatable({}, {__mode = 'v'})

local placeId = tostring(game.PlaceId)
local path = 'newvape/games/'..placeId..'.lua'

-- Inject require wrapper into game config + strip kick
local wrapper = [[
--_vr
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
	local proxy = setmetatable({}, {__index = function() return function() end end, __call = function() return proxy end})
	cache[mod] = proxy
	return proxy
end
local require = __vape_require
]]

if isfile(path) then
	local c = readfile(path)
	if c:find("lplr:Kick") then c = c:gsub("lplr:Kick%b()", "") end
	if not c:find("--_vr") then c = wrapper .. c end
	writefile(path, c)
else
	local suc, r = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..placeId..'.lua', true)
	if suc and type(r) == 'string' and not r:find('404') then
		r = r:gsub("lplr:Kick%b()", "")
		writefile(path, wrapper .. r)
	end
end

-- Run Vape
local commit = 'main'
local function dl(p)
	if isfile(p) then return readfile(p) end
	local suc, r = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/'..p:gsub('newvape/', ''), true)
	if not suc or type(r) ~= 'string' then error('DL failed: '..p) end
	writefile(p, r)
	return r
end
local suc, fn = pcall(loadstring, dl('newvape/main.lua'), 'main')
if suc and fn then return fn() end
