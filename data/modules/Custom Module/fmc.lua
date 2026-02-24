local P = {}
fmc = P -- package name

require("definitions")
require("settings")
P.fmcKeyQueue = {}
P.fmcQueueLocked = false
local fmcKeyWait = 0

local p_fov = globalProperty("sim/graphics/view/field_of_view_deg")
local acf_tailnum = globalProperty("sim/aircraft/view/acf_tailnum")
local ground_speed = globalProperty("sim/flightmodel/position/groundspeed")
local main_bus = nil
local main_battery = nil

local engine_N2_1 = globalPropertyfae("sim/flightmodel2/engines/N2_percent",1)
local engine_N2_2 = globalPropertyfae("sim/flightmodel2/engines/N2_percent",2)

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

local function is_plan_fuel_enable()
    local fuel_plan_option = globalProperty("laminar/B738/plan_fuel")
    local option_enable = get(fuel_plan_option)
    sasl.logDebug("Plan fuel option is " .. option_enable)
    local engine_N2_1_ = get(engine_N2_1)
    local engine_N2_2_ = get(engine_N2_2)
    sasl.logDebug("Engines N2 " .. engine_N2_1_ .. " / " .. engine_N2_2_)
    local result = option_enable >0 and engine_N2_1_ < 50 and engine_N2_2_ < 50
    if result then 
        sasl.logDebug("Fuel plan option enabled AND engines not running" )
    else 
        sasl.logDebug("Fuel plan option disable OR engines running" )
    end        
    return result
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
        
        -- Cap cruise altitude to B738 ceiling (FL410) to avoid FMC reject when Simbrief gives higher)
        local cruiseAlt = ofpData.maxStepClimb
        if cruiseAlt > 41000 then
            sasl.logInfo(string.format("Cruise altitude %dft above B738 limit, capping to 41000", cruiseAlt))
            cruiseAlt = 41000
        end

        sasl.logInfo("Zibo B737 status ok : computing the FMC")
        P.fmcQueueLocked = true
        -- clear the scratchpad
        pushKeyToBuffer("del", "", "")
        pushKeyToBuffer("del", "", "")
        pushKeyToBuffer("clr", "", "")
        pushKeyToBuffer("clr", "", "")

        pushKeyToBuffer("rte", ofpData.origin.icao_code .. ofpData.destination.icao_code .. definitions.OFPSUFFIX, "2L")
        pushKeyToBuffer("", ofpData.origin.plan_rwy, "3L")
        local flightNo = ""
        local airline = ""
        if type(ofpData.general) == "table" then
            flightNo = ofpData.general.flight_number or ""
            airline = ofpData.general.icao_airline or ""
        end
        flightNo = string.gsub(flightNo, "%s+", "")
        airline = string.gsub(airline, "%s+", "")
        local fmcFlightNo = flightNo
        if airline ~= "" and flightNo ~= "" then
            local flightNoUpper = string.upper(flightNo)
            local airlineUpper = string.upper(airline)
            local hasPrefix = false
            if string.sub(flightNoUpper, 1, #airlineUpper) == airlineUpper then
                hasPrefix = true
            elseif string.match(flightNoUpper, "^[A-Z]") then
                hasPrefix = true
            elseif string.match(flightNoUpper, "^[0-9][A-Z]") then
                hasPrefix = true
            end
            if not hasPrefix then
                fmcFlightNo = airline .. flightNo
            end
        end
        pushKeyToBuffer("", string.sub(fmcFlightNo, 1, 8), "2R")
        pushKeyToBuffer("init_ref", "", "6L")
        pushKeyToBuffer("3L", "", "")
        if is_plan_fuel_enable() then 
            pushKeyToBuffer("", string.format("%1.1f", (math.ceil(ofpData.fuel.plan_ramp / 100) * 100 + 100) / 1000), "2L")
        end
        pushKeyToBuffer("", string.format("%1.1f", ofpData.weights.est_zfw / 1000), "3L")
        if not settings.appSettings.ziboReserveFuelDisable then 
            pushKeyToBuffer("", string.format("%1.1f", (ofpData.fuel.reserve + ofpData.fuel.alternate_burn) / 1000), "4L")
        end 
        pushKeyToBuffer("", string.format("%1d", ofpData.general.costindex), "5L")
--        pushKeyToBuffer("", string.format("%1.0f", ofpData.general.initial_altitude / 100), "1R")
        pushKeyToBuffer("", string.format("%1.0f", cruiseAlt / 100), "1R")
        pushKeyToBuffer("", string.format("%03d/%03d", ofpData.navlog.fix[iTOC].wind_dir, ofpData.navlog.fix[iTOC].wind_spd), "2R")
        pushKeyToBuffer("", string.format("%dC", ofpData.navlog.fix[iTOC].oat), "3R")
        P.fmcQueueLocked = false
    else
        sasl.logInfo("Zibo B737 not detected : not computing the FMC")
    end
end

P.initTailNum()

return fmc
