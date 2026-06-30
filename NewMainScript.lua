local delfile = delfile or function(file) writefile(file, '') end

for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Delete any stale cached files that point to dead VapeV4ForRoblox repo
for _, dir in {'newvape/games', 'newvape/libraries', 'newvape/main.lua'} do
	if isfile(dir) then
		local content = readfile(dir)
		if content and content:find('VapeV4ForRoblox') then
			delfile(dir)
		end
	elseif isfolder(dir) then
		for _, file in listfiles(dir) do
			if isfile(file) then
				local content = readfile(file)
				if content and content:find('VapeV4ForRoblox') then
					delfile(file)
				end
			end
		end
	end
end

-- Download game config from VapeCompiled (has correct URLs, __namecall hook blocks Bedwars kick)
local pid = tostring(game.PlaceId)
if pid ~= '0' and not isfile('newvape/games/'..pid..'.lua') then
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
	end)
	if suc and res and res ~= '404: Not Found' then
		writefile('newvape/games/'..pid..'.lua', '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
	end
end

-- Fresh main.lua from VapeCompiled every time
local suc, res = pcall(function()
	return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/main.lua', true)
end)
if not suc or not res or res == '404: Not Found' then
	error('Failed to download main.lua: ' .. tostring(res))
end
writefile('newvape/main.lua', '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res)
writefile('newvape/profiles/commit.txt', 'main')

-- Hook __namecall to block Kick with Bedwars message
if hookmetamethod and getnamecallmethod then
	local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "Kick" then
			local args = {...}
			for i = 1, #args do
				if type(args[i]) == "string" and args[i]:find("Bedwars") then
					return
				end
			end
		end
		return oldNamecall(self, ...)
	end)
end

return loadstring(readfile('newvape/main.lua'), 'main')()
