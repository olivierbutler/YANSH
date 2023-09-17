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

return helpers