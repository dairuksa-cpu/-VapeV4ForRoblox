for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end
writefile('newvape/profiles/commit.txt', 'main')

_G.__vapeModCache = setmetatable({}, {__mode = 'v'})
getgenv().__vape_require = function(mod)
	local cache = _G.__vapeModCache
	if cache[mod] then return cache[mod] end
	local suc, bc = pcall(getscriptbytecode, mod)
	if suc and bc and #bc > 0 then
		local fn = loadstring(bc)
		if fn then
			local s, r = pcall(fn)
			if s then cache[mod] = r; return r end
		end
		local src = decompile(mod)
		if src and #src > 0 then
			local fn = loadstring(src)
			if fn then
				s, r = pcall(fn)
				if s then cache[mod] = r; return r end
			end
		end
	end
	local oldId = getthreadidentity()
	setthreadidentity(2)
	local s, r = pcall(require, mod)
	setthreadidentity(oldId)
	if s then cache[mod] = r; return r end
	local proxy = setmetatable({}, {__index = function() return function() end end, __call = function() return proxy end})
	cache[mod] = proxy
	return proxy
end

local placeId = tostring(game.PlaceId)
local path = 'newvape/games/'..placeId..'.lua'
if isfile(path) then
	local c = readfile(path)
	c = c:gsub("lplr:Kick%b()", "")
	c = c:gsub("require%(", "__vape_require(")
	writefile(path, c)
else
	local suc, r = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..placeId..'.lua', true)
	if suc and type(r) == 'string' and not r:find('404') then
		r = r:gsub("lplr:Kick%b()", "")
		r = r:gsub("require%(", "__vape_require(")
		writefile(path, r)
	end
end

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
