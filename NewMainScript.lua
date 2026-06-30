for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end
writefile('newvape/profiles/commit.txt', 'main')
local placeId = tostring(game.PlaceId)
local path = 'newvape/games/'..placeId..'.lua'
if isfile(path) then
	local c = readfile(path)
	local nc = c:gsub("lplr:Kick%b()", "")
	if nc ~= c then writefile(path, nc) end
end
_G.__vapeModCache = setmetatable({}, {__mode = 'v'})
local commit = 'main'
local function dl(p)
	if isfile(p) then return readfile(p) end
	local suc, r = pcall(game.HttpGet, game, 'https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/'..p:gsub('newvape/', ''), true)
	if not suc or type(r) ~= 'string' then error('DL failed: '..p..' - '..tostring(r)) end
	writefile(p, r)
	return r
end
local suc, fn = pcall(loadstring, dl('newvape/main.lua'), 'main')
if suc and fn then return fn() end
