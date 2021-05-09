local IS_DOS = false
local IS_UNIX = false

-- Written like this to silence Selene
local config = package["config"]
if config:sub(1, 1) == "/" then
    IS_UNIX = true
elseif config:sub(1, 1) == "\\" then
    IS_DOS = true
else
    error("Unknown operating system!")
end

local fs = {}

-- https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^".. sep.. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function run(command)
    local handle = io.popen(command, "r")
    local content = handle:read("*all")

    handle:close()
    return content
end

function fs.getDosPath(path)
    return path:gsub("/", "\\")
end

function fs.getUnixPath(path)
    return path:gsub("\\", "/")
end

function fs.getOSPath(path)
    if IS_DOS then
        return fs.getDosPath(path)
    elseif IS_UNIX then
        return fs.getUnixPath(path)
    end
end

function fs.dir(path)
    path = fs.getOSPath(path)

    local fileNames = {}
    if IS_DOS then
        local dir = split(run("dir ".. path), "\n")

        for i = 4, #dir - 2 do
            local fileName = dir[i]:sub(37)
            if fileName ~= "." and fileName ~= ".." then
                table.insert(fileNames, fileName)
            end
        end
    elseif IS_UNIX then
        fileNames = split(run("ls ".. path), "\n")
    end

    return fileNames
end

function fs.isFile(path)
    path = fs.getOSPath(path)

    if IS_DOS then
        if run("attrib ".. path):sub(1, 1):lower() == "a" then
            return true
        else
            return false
        end
    elseif IS_UNIX then
        if run("stat ".. path):find("regular file") then
            return true
        else
            return false
        end
    end
end

function fs.isDir(path)
    path = fs.getOSPath(path)

    if IS_DOS then
        if run("attrib ".. path):sub(1, 1):lower() == "a" then
            return false
        else
            return true
        end
    elseif IS_UNIX then
        if run("stat ".. path):find("directory") then
            return true
        else
            return false
        end
    end
end

-- https://github.com/LPGhatguy/lemur/blob/master/lib/fs.lua
function fs.read(path)
	local handle, err = io.open(path, "r")

	if not handle then
		return nil, err
	end

	local contents = handle:read("*all")

	handle:close()

	return contents
end

return fs