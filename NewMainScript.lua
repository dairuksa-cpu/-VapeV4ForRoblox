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

-- Patch Bedwars compiled game files
local commit = readfile('newvape/profiles/commit.txt')
for _, pid in ipairs({ "6872274481", "6872265039", "8560631822", "8444591321" }) do
	local path = 'newvape/games/' .. pid .. '.lua'
	if isfile(path) then
		local content = readfile(path)
		-- Fix old broken patch from previous version
		local patched = content:gsub("lplr:Kick = function%(%) end", "nil")
		-- Patch the actual kick call (match through closing paren)
		patched = patched:gsub("lplr:Kick%('Bedwars[^']-')", "nil")
		if patched ~= content then
			writefile(path, patched)
		end
	else
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..commit..'/games/'..pid..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			res = res:gsub("lplr:Kick%('Bedwars[^']-')", "nil")
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			writefile(path, res)
		end
	end
end

-- Hook __namecall to block Kick with Bedwars message as a safety net
if hookmetamethod and getnamecallmethod then
	local oldNamecall = hookmetamethod(game, "__namecall", function(...)
		local method = getnamecallmethod()
		if method == "Kick" then
			local args = {...}
			local msg = args[2]
			if type(msg) == "string" and msg:find("Bedwars") then
				return
			end
		end
		return oldNamecall(...)
	end)
end

-- Bedwars Scaffold module (toggle with G key)
spawn(function()
	local player = game.Players.LocalPlayer
	local mouse = player:GetMouse()
	local userInput = game:GetService("UserInputService")
	local runService = game:GetService("RunService")
	local scaffoldOn = false

	local blockKeywords = {"wool", "stone", "wood", "endstone", "glass", "terracotta", "clay", "ladder", "plank", "oak", "spruce", "birch", "netherrack", "obsidian", "sandstone", "blast"}

	local function isBlockItem(name)
		local lower = name:lower()
		for _, kw in ipairs(blockKeywords) do
			if lower:find(kw) then return true end
		end
		return false
	end

	local function getBlockTool()
		local char = player.Character
		if not char then return nil end
		local held = char:FindFirstChildOfClass("Tool")
		local backpack = player.Backpack
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and isBlockItem(child.Name) then
				return child
			end
		end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") and isBlockItem(child.Name) then
				return child
			end
		end
		return held and isBlockItem(held.Name) and held or nil
	end

	local function placeBlockUnder()
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local pos = hrp.Position
		local below = Vector3.new(math.floor(pos.X + 0.5), math.floor(pos.Y - 1.5), math.floor(pos.Z + 0.5))
		if workspace:FindPartOnRayWithIgnoreList(Ray.new(below + Vector3.new(0, 3, 0), Vector3.new(0, -5, 0)), {char, workspace:FindFirstChild("Debris")}) then return end
		local tool = getBlockTool()
		if not tool then return end
		if tool.Parent ~= char then
			char.Humanoid:EquipTool(tool)
			wait(0.05)
		end
		local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
		if remote then
			remote:FireServer(CFrame.new(below))
		else
			local cd = tool:FindFirstChildWhichIsA("ClickDetector")
			if cd then
				fireclickdetector(cd)
			end
		end
	end

	userInput.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.G then
			scaffoldOn = not scaffoldOn
		end
	end)

	runService.RenderStepped:Connect(function()
		if not scaffoldOn then return end
		placeBlockUnder()
	end)
end)

return loadstring(downloadFile('newvape/main.lua'), 'main')()
