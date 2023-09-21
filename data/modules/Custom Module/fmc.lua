local P = {}
fmc = P -- package name

require("definitions")

P.fmcKeyQueue = {}
P.fmcQueueLocked = false
local fmcKeyWait = 0

local p_fov = globalProperty("sim/graphics/view/field_of_view_deg")
local acf_tailnum = globalProperty("sim/aircraft/view/acf_tailnum")
local ground_speed = globalProperty("sim/flightmodel/position/groundspeed")
local main_bus = nil
local main_battery = nil

function P.isOnGround()
    return (get(ground_speed) < 5)
end

function P.isFMConPower()
    if main_battery == nil or main_bus == nil then
        return false
    end
    return (get(main_bus) > 0) and (get(main_battery) > 0)
end

function P.initTailNum()
    P.isZibo = (string.sub(get(acf_tailnum), 1, 5) == "ZB738")
    if P.isZibo then
        sasl.logDebug("is zibo YES ->" .. string.sub(get(acf_tailnum), 1, 5) .. "<-")
        main_bus = globalProperty("laminar/B738/electric/main_bus")
        main_battery = globalProperty("laminar/B738/electric/battery_pos")
    else 
        sasl.logDebug("is zibo -> NO" )
    end
end

function P.pushKeyToFMC()
    if fmcKeyWait > 0 then
        fmcKeyWait = fmcKeyWait - 1
        return
    end
    if P.fmcQueueLocked == false then
        if #P.fmcKeyQueue ~= 0 then
            local b = table.remove(P.fmcKeyQueue, 1)
            if b == '_WAIT_' then
                fmcKeyWait = 15
                sasl.logDebug(b)
                return
            end
            local viewOutsideCommand = sasl.findCommand(b)
            sasl.commandOnce(viewOutsideCommand)
            sasl.logDebug(b)
        end
    end
end

local function pushKeyToBuffer(startKey, inputString, endKey)

    inputString = string.upper(inputString)

    if startKey ~= "" then
        table.insert(P.fmcKeyQueue, "laminar/B738/button/fmc1_" .. startKey)
    end

    local c = ""
    if inputString ~= "" then
        for i = 1, string.len(inputString), 1 do
            c = string.sub(inputString, i, i)
            if c == "/" then
                c = "slash"
            end
            if c == "-" then
                c = "minus"
            end
            if c == "." then
                c = "period"
            end
            if c == " " then
                c = "SP"
            end
            table.insert(P.fmcKeyQueue, "laminar/B738/button/fmc1_" .. c)
        end
    end

    if endKey ~= "" then
        table.insert(P.fmcKeyQueue, "laminar/B738/button/fmc1_" .. endKey)
        table.insert(P.fmcKeyQueue, "_WAIT_")
    end

end

function P.uploadToZiboFMC(ofpData)

    if P.isZibo then
        if not P.isFMConPower() then
            sasl.logInfo("Zibo B737 not powered : not computing the FMC")
            return 
        end
        if not P.isOnGround() then
            sasl.logInfo("Zibo B737 not on ground : not computing the FMC")
            return 
        end
        -- find TOC
        local iTOC = ofpData.iTOC
        

        sasl.logInfo("Zibo B737 status ok : computing the FMC")
        P.fmcQueueLocked = true
        pushKeyToBuffer("rte", ofpData.origin.icao_code .. ofpData.destination.icao_code .. definitions.OFPSUFFIX, "2L")
        pushKeyToBuffer("", ofpData.origin.plan_rwy, "3L")
        pushKeyToBuffer("", ofpData.general.flight_number, "2R")
        pushKeyToBuffer("init_ref", "", "6L")
        pushKeyToBuffer("3L", "", "")
        pushKeyToBuffer("", string.format("%1.1f", (math.ceil(ofpData.fuel.plan_ramp / 100) * 100 + 100) / 1000), "2L")
        pushKeyToBuffer("", string.format("%1.1f", ofpData.weights.est_zfw / 1000), "3L")
        pushKeyToBuffer("", string.format("%1.1f", (ofpData.fuel.reserve + ofpData.fuel.alternate_burn) / 1000), "4L")
        pushKeyToBuffer("", string.format("%1d", ofpData.general.costindex), "5L")
        pushKeyToBuffer("", string.format("%1.0f", ofpData.general.initial_altitude / 100), "1R")
        pushKeyToBuffer("", string.format("%03d/%03d", ofpData.navlog.fix[iTOC].wind_dir, ofpData.navlog.fix[iTOC].wind_spd), "2R")
        pushKeyToBuffer("", string.format("%dC", ofpData.navlog.fix[iTOC].oat_isa_dev), "3R")
        P.fmcQueueLocked = false
    else
        sasl.logInfo("Zibo B737 not detected : not computing the FMC")
    end
end

P.initTailNum()

return fmc
