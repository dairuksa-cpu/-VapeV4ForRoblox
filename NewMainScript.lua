local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file) writefile(file, '') end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

-- Download game config from our repo first, then VapeCompiled as fallback
local pid = tostring(game.PlaceId)
if pid ~= '0' and not isfile('newvape/games/'..pid..'.lua') then
	local suc, res = pcall(function()
		return game:HttpGet('https://raw.githubusercontent.com/dairuksa-cpu/-VapeV4ForRoblox/main/games/'..pid..'.lua', true)
	end)
	if not suc or not res or res == '404: Not Found' then
		suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/main/games/'..pid..'.lua', true)
		end)
	end
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
