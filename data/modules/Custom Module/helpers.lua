local P = {}
helpers = P -- package name

function P.cp_file(source, destination)
    local inp = assert(io.open(source, "rb"))
    local out = assert(io.open(destination, "wb"))
    local data = inp:read("*all")
    out:write(data)
    out:close()
    inp:close()
end

local function splitLines(text)
    local lines = {}
    if text == nil or text == "" then
        return lines
    end
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    for line in string.gmatch(text, "([^\n]*)\n?") do
        if line == "" and #lines > 0 and lines[#lines] == "" then
            break
        end
        table.insert(lines, line)
    end
    return lines
end

local function parseFmsWaypointLine(line)
    local fields = {}
    for field in string.gmatch(line, "%S+") do
        table.insert(fields, field)
    end
    if #fields ~= 6 then
        return nil
    end
    if tonumber(fields[1]) == nil or tonumber(fields[4]) == nil or tonumber(fields[5]) == nil or tonumber(fields[6]) == nil then
        return nil
    end
    return {
        waypointType = fields[1],
        ident = fields[2],
        via = fields[3],
        altitude = fields[4],
        latitude = fields[5],
        longitude = fields[6],
        raw = line
    }
end

local function shouldDedupFmsWaypoint(previousWaypoint, currentWaypoint)
    if previousWaypoint == nil or currentWaypoint == nil then
        return false
    end
    if previousWaypoint.ident ~= currentWaypoint.ident then
        return false
    end
    if previousWaypoint.waypointType ~= currentWaypoint.waypointType then
        return false
    end
    if previousWaypoint.altitude ~= currentWaypoint.altitude then
        return false
    end
    if previousWaypoint.latitude ~= currentWaypoint.latitude or previousWaypoint.longitude ~= currentWaypoint.longitude then
        return false
    end
    if previousWaypoint.via == "ADEP" or previousWaypoint.via == "ADES" or currentWaypoint.via == "ADEP" or currentWaypoint.via == "ADES" then
        return false
    end
    if string.sub(previousWaypoint.ident, 1, 2) == "RW" or string.sub(currentWaypoint.ident, 1, 2) == "RW" then
        return false
    end
    return previousWaypoint.via == "DRCT" or currentWaypoint.via == "DRCT"
end

function P.dedupConsecutiveFmsWaypoints(filePath)
    local file = io.open(filePath, "rb")
    if file == nil then
        sasl.logWarning("Unable to open FMS file for dedup: " .. filePath)
        return 0
    end

    local contents = file:read("*all")
    file:close()

    local newLine = "\n"
    if string.find(contents, "\r\n", 1, true) ~= nil then
        newLine = "\r\n"
    end

    local lines = splitLines(contents)
    if #lines == 0 then
        return 0
    end

    local outputLines = {}
    local removedCount = 0
    local previousWaypoint = nil

    for i = 1, #lines do
        local currentLine = lines[i]
        local currentWaypoint = parseFmsWaypointLine(currentLine)
        if shouldDedupFmsWaypoint(previousWaypoint, currentWaypoint) then
            removedCount = removedCount + 1
            if previousWaypoint.via == "DRCT" and currentWaypoint.via ~= "DRCT" then
                outputLines[#outputLines] = currentLine
                previousWaypoint = currentWaypoint
            end
        else
            table.insert(outputLines, currentLine)
            previousWaypoint = currentWaypoint
        end
    end

    if removedCount == 0 then
        return 0
    end

    local enrouteCount = 0
    for i = 1, #outputLines do
        if parseFmsWaypointLine(outputLines[i]) ~= nil then
            enrouteCount = enrouteCount + 1
        end
    end

    for i = 1, #outputLines do
        if string.match(outputLines[i], "^NUMENR%s+") ~= nil then
            outputLines[i] = string.format("NUMENR %d", enrouteCount)
            break
        end
    end

    file = io.open(filePath, "wb")
    if file == nil then
        sasl.logWarning("Unable to write deduped FMS file: " .. filePath)
        return 0
    end
    file:write(table.concat(outputLines, newLine))
    file:close()

    sasl.logInfo(string.format("Deduped %d consecutive waypoint duplicate(s) in %s", removedCount, filePath))
    return removedCount
end

function P.format_thousand(v)
    local s = string.format("%6d", math.floor(v))
    local pos = string.len(s) % 3
    if pos == 0 then
        pos = 3
    end
    return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos + 1), "(...)", " %1")
end

function P.timeConvert(seconds, sep)
    local seconds = tonumber(seconds)

    if seconds <= 0 then
        return "no data";
    else
        -- hours = string.format("%2.f", math.floor(seconds / 3600));
        -- mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        -- return hours .. sep .. mins
        return string.format("%2d%s%02d", math.floor(seconds / 3600), sep, math.floor(seconds / 60) % 60)
    end
end

function P.cleanString(text, noSpace)
    local newText = ""
    local loopSkip = false

    for i = 1, string.len(text), 1 do
        -- ugly filtering
        if string.byte(string.sub(text, i, i)) >= 32 then
            newText = newText .. string.sub(text, i, i)
            loopSkip = false
        else
            if not loopSkip then
                newText = newText .. " "
            end
            loopSkip = true
        end
    end

    if noSpace then
        newText = string.gsub(newText, " ", "")
    end

    return newText
end

function P.ifnull(text, sub)
    if type(text) ~= 'string'  then
        return sub
    end
    return text
end

function P.trimInnerSpace(text)
    local newText = ""
    local loopSkip = false

    for i = 1, string.len(text), 1 do
        -- ugly filtering
        if string.byte(string.sub(text, i, i)) > 32 then
            newText = newText .. string.sub(text, i, i)
            loopSkip = false
        else
            if not loopSkip then
                newText = newText .. " "
            end
            loopSkip = true
        end
    end

    return newText
end

function P.splitText(text, tabSize, maxColumn)

    local tab = ""
    local current_pos = 1
    local current_length = 0
    local sub_string = ""
    local split = {}

    for i = 1, tabSize, 1 do
        tab = tab .. " "
    end

    for i = 1, #text, 1 do
        if string.sub(text, i, i) == " " and current_length > maxColumn then
            sub_string = string.sub(text, current_pos, i - 1)
            if #split > 0 then
                sub_string = tab .. sub_string
            end
            table.insert(split, sub_string)
            current_pos = i + 1
            current_length = 0
        end
        current_length = current_length + 1
    end

    sub_string = string.sub(text, current_pos, #text)
    if #split > 0 then
        sub_string = tab .. sub_string
    end
    if #sub_string > 0 then
        table.insert(split, sub_string)
    end
    return split
end

local function os_is_unix()
    return sasl.getOS() ~= 'Windows'
end

function P.create_directories(dirnames)
    local cmd, args = nil, ""

    for i, dirname in pairs(dirnames) do
        assert(dirname:find("\"", 1, true) == nil)
    end
    if os_is_unix() then
        for i, dirname in pairs(dirnames) do
            args = args .. " \"" .. dirname .. "\""
        end
        cmd = "mkdir -p -- " .. args
        sasl.logDebug("file", 1, "executing: " .. cmd)
        os.execute(cmd)
    else
        -- Because CMD.EXE on Windows is dumb as a sack of hammers,
        -- we need to feed it commands in 8191-character increments,
        -- because NOBODY would ever need more than 8191 characters
        -- on a line, right?
        for i, dirname in pairs(dirnames) do
            -- the 290 character reserve here is because CMD.EXE
            -- counts the hostname and current directory into
            -- its line length (?!)
            if #args + #dirname + 3 > 7900 then
                -- Unfuck any slashes into backslashes to deal
                -- with FlyWithLua's broken SCRIPT_DIRECTORY
                args = args:gsub("/", "\\")
                cmd = "mkdir " .. args
                sasl.logDebug("file", 1, "executing: " .. cmd)
                os.execute(cmd)
                args = ""
            end
            args = args .. " \"" .. dirname .. "\""
        end
        if args ~= "" then
            args = args:gsub("/", "\\")
            cmd = "mkdir " .. args
            sasl.logDebug("file", 1, "executing: " .. cmd)
            os.execute(cmd)
        end
    end
end

function file_exists_v2(file)
    -- some error codes:
    -- 13 : EACCES - Permission denied
    -- 17 : EEXIST - File exists
    -- 20	: ENOTDIR - Not a directory
    -- 21	: EISDIR - Is a directory
    --
    local isok, errstr, errcode = os.rename(file, file)
    if isok == nil then
        if errcode == 13 then
            -- Permission denied, but it exists
            return true
        end
        return false
    end
    return true
end

function dir_exists_v2(path)
    return file_exists_v2(path .. "/")
end

function P.check_create_path(path)
    if not dir_exists_v2(path) then
        sasl.logInfo("Folder " .. path .. " does not exist... creating it")
        helpers.create_directories({path})
        if not dir_exists_v2(path) then
            sasl.logWarning("Failure to create folder " .. path)
            return false
        end
    end

    return true
end

function P.remove_directory(dirname)
    local cmd

    assert(dirname:find("..", 1, true) == nil)
    if os_is_unix() then
        assert(dirname:find("/", 1, true) ~= 1 or #dirname > 1)
        cmd = "rm -rf -- \"" .. dirname .. "\""
    else
        dirname = dirname:gsub("/", "\\")
        assert(dirname:find("[a-zA-Z]:\\") ~= 1 or #dirname > 3)
        assert(dirname:find("[a-zA-Z]:\\[Ww][Ii][Nn][Dd][Oo][Ww][Ss]") == nil)
        cmd = "rd /s /q \"" .. dirname .. "\""
    end

    sasl.logDebug("file", 1, "executing: " .. cmd)
    local res = os.execute(cmd)
end

return helpers
