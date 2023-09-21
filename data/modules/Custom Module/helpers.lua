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
        hours = string.format("%2.f", math.floor(seconds / 3600));
        mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)));
        return hours .. sep .. mins
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

return helpers
