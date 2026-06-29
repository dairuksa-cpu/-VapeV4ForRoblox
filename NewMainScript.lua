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

-- Hook readfile to auto-download clean game files from our repo
local OLD_REPO = 'https://raw.githubusercontent.com/dairuksa-cpu/-VapeV4ForRoblox/main/games/'
local oldReadfile = readfile
readfile = function(file)
	local content = oldReadfile(file)
	if content and file:find('newvape/games/') then
		if content:find('Bedwars is no longer supported') then
			local pid = file:match('newvape/games/(.+)%.lua')
			if pid then
				local suc, res = pcall(function()
					return game:HttpGet(OLD_REPO..pid..'.lua', true)
				end)
				if suc and res ~= '404: Not Found' then
					content = res
					writefile(file, res)
				end
			end
		end
	end
	return content
end

-- Also hook global loadstring as backup
local oldLoadstring = loadstring
loadstring = function(text, chunkname)
	if type(text) == 'string' and text:find('Bedwars is no longer supported') then
		text = text:gsub("lplr:Kick%Bedwars[^']-')", "")
	end
	return oldLoadstring(text, chunkname)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
