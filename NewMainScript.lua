local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/7GrandDadPGN/VapeCompiled')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

-- Clean up any broken cached game files from old patches
for _, pid in ipairs({ "6872274481", "6872265039", "8560631822", "8444591321" }) do
	local path = 'newvape/games/' .. pid .. '.lua'
	if isfile(path) then
		local content = readfile(path)
		if content:find("lplr:Kick = function") or content:find("lplr:Kick%(") then
			delfile(path)
		end
	end
end

-- Block Kick with Bedwars message using multiple methods
local blocked = false
local function blockKick(...)
	if blocked then return end
	blocked = true
	local args = {...}
	local msg = ""
	for i = 1, #args do
		if type(args[i]) == "string" then
			msg = args[i]
			break
		end
	end
	if msg:find("Bedwars") then
		return true
	end
	blocked = false
	return false
end

-- Method 1: hookmetamethod
if hookmetamethod and getnamecallmethod then
	local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		if getnamecallmethod() == "Kick" and blockKick(...) then return end
		return oldNamecall(self, ...)
	end)
end

-- Method 2: getrawmetatable (more reliable)
if getrawmetatable and setreadonly and getnamecallmethod then
	local mt = getrawmetatable(game)
	local oldNamecall = mt.__namecall
	setreadonly(mt, false)
	mt.__namecall = function(...)
		if getnamecallmethod() == "Kick" and blockKick(select(1, ...)) then return end
		return oldNamecall(...)
	end
	setreadonly(mt, true)
end

-- Method 3: Override Kick on LocalPlayer directly
spawn(function()
	while task.wait(0.5) do
		local player = game:GetService("Players").LocalPlayer
		if player then
			player.Kick = function() end
			break
		end
	end
end)

return loadstring(downloadFile('newvape/main.lua'), 'main')()
