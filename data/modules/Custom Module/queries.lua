local P = {}
queries = P -- package name

require("definitions")
require("settings")
require("helpers")
fmc = require("fmc")
require("messages")

--- weights/pax count/crz altitude
local dr_initial_altitude = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/general/initial_altitude", 0 , false , true , true)
local dr_max_altitude = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/general/max_altitude", 0 , false , true , true)
local dr_pax_count = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/weights/pax_count", 0 , false , true , true)
local dr_cargo = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/weights/cargo", 0 , false , true , true)
local dr_payload = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/weights/payload", 0 , false , true , true)
local dr_est_zfw = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/weights/est_zfw", 0 , false , true , true)
local dr_plan_ramp = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/fuel/plan_ramp", 0 , false , true , true)
local dr_min_takeoff = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/fuel/min_takeoff", 0 , false , true , true)
local dr_enroute_burn = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/fuel/enroute_burn", 0 , false , true , true)
local dr_reserve = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/fuel/reserve", 0 , false , true , true)
local dr_alternate_burn = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/fuel/alternate_burn", 0 , false , true , true)
local dr_est_tow = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/weights/est_tow", 0 , false , true , true)
local dr_weight_unit = createGlobalPropertys( definitions.APPNAMEPREFIX.. "/sb/params/units", "" , false , true , true)
local dr_weight_uniti = createGlobalPropertyi( definitions.APPNAMEPREFIX.. "/sb/params/units_flag", 0 , false , true , true)

P.OFP = {
    status = 0, -- 0 never set, 1 query in progress, 2 data ready
    values = {},
    output = {}
}

P.METAR = {
    status = 0, -- 0 never set, 1 query in progress, 2 data ready
    values = {},
    taf_values = {}
}

local function onContentsDownloaded(inUrl, inFilePath, inIsOk, inError)
    if inIsOk then
        sasl.logDebug(string.format("File downloaded! from %s to %s", inUrl, inFilePath))
    else
        sasl.logWarning(string.format("Downloading FAILED! from %s with error %s", inUrl, inError))
    end
    return inIsOk
end

local function fetchfmsFile(inUrl, inFilePath, inIsOk, inError)
    if onContentsDownloaded(inUrl, inFilePath, inIsOk, inError) then 
        local fmsZiboFilePath = definitions.XPFMSPATH .. definitions.ZIBOFILE .. ".fms"
        helpers.cp_file(inFilePath, fmsZiboFilePath) -- fms file for Zibo RC5.2+ datalink
    end    
end

local function formatOFPDisplay(ofpData)
    local t = {}

    pcall(function()
        local route = string.format("%s%s%s", ofpData.origin.icao_code, ofpData.destination.icao_code, definitions.OFPSUFFIX)

        -- find TOC
        local iTOC = ofpData.iTOC

        if ofpData.params.time_generated ~= nil then
            local ofpAge = os.time() - ofpData.params.time_generated
            if ofpAge > 2 * 60 * 60 then
                table.insert(t, "##E83E3EFF") -- change color
                table.insert(t, messages.translation['OFPTOOLDER'])
                table.insert(t, "#" .. definitions.textColorHtml) -- change color
                table.insert(t, "")
            end

        end
        if ofpData.params.ofp_layout ~= "LIDO" then
            table.insert(t, "##FFAF00FF") -- change color
            table.insert(t, string.format("OFP Layout: %s, " .. messages.translation['LIDOFORMAT1'], ofpData.params.ofp_layout))
            table.insert(t, messages.translation['LIDOFORMAT2'])
            table.insert(t, "")
        end

        table.insert(t, "#" .. definitions.textColorHtml) -- change color
        table.insert(t,
            string.format("FMS CO ROUTE / Flight #:  %s%s%s / %s%s%s / %s %s", ofpData.origin.icao_code, ofpData.destination.icao_code, definitions.OFPSUFFIX, ofpData.origin.iata_code,
                ofpData.destination.iata_code, definitions.OFPSUFFIX, ofpData.general.icao_airline, ofpData.general.flight_number))
        table.insert(t, string.format("Aircraft:                 %s", ofpData.aircraft.name))
        table.insert(t, string.format("Airports:                 %s - %s", ofpData.origin.name, ofpData.destination.name))
        -- table.insert(t, helpers.cleanString(string.format("Route:                    %s/%s %s %s/%s", ofpData.origin.icao_code, ofpData.origin.plan_rwy, ofpData.general.route,
        --    ofpData.destination.icao_code, ofpData.destination.plan_rwy), false))
        local routeStr = helpers.cleanString(string.format("Route:                    %s/%s %s %s/%s", ofpData.origin.icao_code, ofpData.origin.plan_rwy, ofpData.general.route,
            ofpData.destination.icao_code, ofpData.destination.plan_rwy), false)
        local routeTable = helpers.splitText(routeStr, 5, 70)
        for i = 1, #routeTable, 1 do
            table.insert(t, routeTable[i])
        end
        table.insert(t, string.format("Distance:                 %d nm ETE:%s", ofpData.general.route_distance, helpers.timeConvert(ofpData.times.est_time_enroute, "h")))
        table.insert(t, "")
        table.insert(t, string.format("Cruise Altitudes:        %s  → %s ft", helpers.format_thousand(ofpData.general.initial_altitude),   helpers.format_thousand(ofpData.maxStepClimb)))
        set(dr_initial_altitude, ofpData.general.initial_altitude)
        set(dr_max_altitude, ofpData.maxStepClimb)
        table.insert(t, string.format("Step Climb:               %s", ofpData.general.stepclimb_string))
        table.insert(t, string.format("Elevations:               %s (%d ft) - %s (%d ft)", ofpData.origin.icao_code, ofpData.origin.elevation, ofpData.destination.icao_code,
            ofpData.destination.elevation))
        table.insert(t, "")
        table.insert(t, string.format("Block Fuel:              %s %s", helpers.format_thousand((math.ceil(ofpData.fuel.plan_ramp / 1 ) * 1  )), ofpData.params.units))
        set(dr_plan_ramp, ofpData.fuel.plan_ramp)
        table.insert(t, string.format("Takeoff Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.min_takeoff), ofpData.params.units))
        set(dr_min_takeoff, ofpData.fuel.min_takeoff)
        table.insert(t, string.format("Trip Fuel:               %s %s", helpers.format_thousand((math.ceil(ofpData.fuel.enroute_burn / 1 ) * 1  )), ofpData.params.units))
        set(dr_enroute_burn, ofpData.fuel.enroute_burn)
        table.insert(t, string.format("Extra Fuel:              %s %s", helpers.format_thousand(ofpData.fuel.extra), ofpData.params.units))
        table.insert(t, string.format("Reserve Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.reserve), ofpData.params.units))
        set(dr_reserve, ofpData.fuel.reserve)
        table.insert(t, string.format("Alternate Fuel:          %s %s", helpers.format_thousand(ofpData.fuel.alternate_burn), ofpData.params.units))
        set(dr_alternate_burn, ofpData.fuel.alternate_burn)
        table.insert(t, string.format("Res+Alt Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.alternate_burn + ofpData.fuel.reserve), ofpData.params.units))
        table.insert(t, "")
        table.insert(t, string.format("Pax:                      %6d", ofpData.weights.pax_count))
        set(dr_pax_count, ofpData.weights.pax_count)
        table.insert(t, string.format("Cargo:                   %s %s", helpers.format_thousand(ofpData.weights.cargo), ofpData.params.units))
        set(dr_cargo, ofpData.weights.cargo)
        table.insert(t, string.format("Payload:                 %s %s", helpers.format_thousand(ofpData.weights.payload), ofpData.params.units))
        set(dr_payload, ofpData.weights.payload)
        table.insert(t, string.format("ZFW:                      %6.1f", ofpData.weights.est_zfw / 1000))
        set(dr_est_zfw, ofpData.weights.est_zfw)
        table.insert(t, string.format("TO / LW weight:              %s / %s %s", helpers.format_thousand(ofpData.weights.est_tow), helpers.format_thousand(ofpData.weights.est_ldw), ofpData.params.units))
        set(dr_est_tow, ofpData.weights.est_tow)
        set(dr_weight_unit, ofpData.params.units)
        if ofpData.params.units == 'kgs' then 
            set(dr_weight_uniti, 1)
        else
            set(dr_weight_uniti, 0)
        end        
        table.insert(t, string.format("Cost Index:               %6d", ofpData.general.costindex))
        table.insert(t, "")
        -- table.insert(t, "##CA321280") -- change color
        table.insert(t, string.format("TOC Wind:                %03d/%03d", ofpData.navlog.fix[iTOC].wind_dir, ofpData.navlog.fix[iTOC].wind_spd))
        table.insert(t, string.format("TOC Temp:                    %3d °C", ofpData.navlog.fix[iTOC].oat))
        table.insert(t, string.format("TOC ISA Dev:                 %3d °C", ofpData.navlog.fix[iTOC].oat_isa_dev))

        table.insert(t, "")
        if settings.appSettings.avwxtoken == "" then
            local metarStr = string.format("METAR: %s", helpers.cleanString(ofpData.weather.orig_metar, false))
            local metarTable = helpers.splitText(metarStr, 7, 70)
            for i = 1, #metarTable, 1 do
                table.insert(t, metarTable[i])
            end
            local tafStr = string.format("TAF:   %s", helpers.cleanString(ofpData.weather.orig_taf))
            local tafStr = helpers.splitText(tafStr, 7, 70)
            for i = 1, #tafStr, 1 do
                table.insert(t, tafStr[i])
            end

            local metarStr = string.format("METAR: %s", helpers.cleanString(ofpData.weather.dest_metar, false))
            local metarTable = helpers.splitText(metarStr, 7, 70)
            for i = 1, #metarTable, 1 do
                table.insert(t, metarTable[i])
            end
            local tafStr = string.format("TAF:   %s", helpers.cleanString(ofpData.weather.dest_taf))
            local tafStr = helpers.splitText(tafStr, 7, 70)
            for i = 1, #tafStr, 1 do
                table.insert(t, tafStr[i])
            end
            table.insert(t, "")
            table.insert(t, "##FFAF00FF") -- change color
            table.insert(t, messages.translation['AVWXNOTCONFIGURED'])
            table.insert(t, "#" .. definitions.textColorHtml) -- change color
        else
            if P.METAR.values['isError'] == false and P.METAR.values['taf_isError'] == false then
                if P.METAR.values[ofpData.origin.icao_code] ~= nil and P.METAR.values["taf_" .. ofpData.origin.icao_code] ~= nil then
                    local metarStr = string.format("METAR: %s", P.METAR.values[ofpData.origin.icao_code])
                    local metarTable = helpers.splitText(metarStr, 7, 70)
                    for i = 1, #metarTable, 1 do
                        table.insert(t, metarTable[i])
                    end
                    local tafStr = string.format("TAF:   %s", P.METAR.values["taf_" .. ofpData.origin.icao_code])
                    local tafStr = helpers.splitText(tafStr, 7, 70)
                    for i = 1, #tafStr, 1 do
                        table.insert(t, tafStr[i])
                    end
                else
                    table.insert(t, string.format(messages.translation['FETCHING'] .. " %s METAR & TAF...", ofpData.origin.icao_code))
                end

                if P.METAR.values[ofpData.destination.icao_code] ~= nil  and P.METAR.values["taf_" .. ofpData.destination.icao_code] ~= nil then
                    local metarStr = string.format("METAR: %s", P.METAR.values[ofpData.destination.icao_code])
                    local metarTable = helpers.splitText(metarStr, 7, 70)
                    table.insert(t, "")
                    for i = 1, #metarTable, 1 do
                        table.insert(t, metarTable[i])
                    end
                    local tafStr = string.format("TAF:   %s", P.METAR.values["taf_" .. ofpData.destination.icao_code])
                    local tafStr = helpers.splitText(tafStr, 7, 70)
                    for i = 1, #tafStr, 1 do
                        table.insert(t, tafStr[i])
                    end
                else
                    table.insert(t, string.format(messages.translation['FETCHING'] .. " %s METAR & TAF...", ofpData.destination.icao_code))
                end
            else
                table.insert(t, string.format(messages.translation['FETCHING'] .. " %s METAR & TAF... : Error Check your configuration", ofpData.origin.icao_code))
                table.insert(t, string.format(messages.translation['FETCHING'] .. " %s METAR & TAF... : Error Check your configuration", ofpData.destination.icao_code))
            end
        end
        P.OFP.output = t
    end)

end

local function fetchOFP(inUrl, inFilePath, inIsOk, inError)
    local xml2lua = require("xml2lua")
    package.loaded["xmlhandler.tree"] = nil
    local handler = require("xmlhandler.tree")

    P.OFP.output = {}
    if onContentsDownloaded(inUrl, inFilePath, inIsOk, inError) then
        local xfile = xml2lua.loadFile(inFilePath)
        local parser = xml2lua.parser(handler)
        parser:parse(xfile)
        P.OFP.values = handler.root

        local xmlFile = string.format("%s%s%s", P.OFP.values.OFP.origin.icao_code, P.OFP.values.OFP.destination.icao_code, definitions.OFPSUFFIX)
        local xmlFilePath = definitions.XPFMSPATH .. xmlFile .. ".xml"
        local xmlZiboFilePath = definitions.XPFMSPATH .. definitions.ZIBOFILE .. ".xml"
        helpers.cp_file(inFilePath, xmlFilePath)
        helpers.cp_file(inFilePath, xmlZiboFilePath) -- xml file for Zibo RC5.2+ datalink

        local downloadfmsFileUrl = definitions.SIMBRIEFOFPURL -- should use this, but is not working -- P.OFP.values.OFP.fms_downloads.directory 
        local fmsFileUrl = downloadfmsFileUrl .. P.OFP.values.OFP.fms_downloads.xpe.link
        sasl.net.downloadFileAsync(fmsFileUrl, definitions.XPFMSPATH .. xmlFile .. ".fms", fetchfmsFile)

        P.fetchMetar(P.OFP.values.OFP.origin.icao_code)
        P.fetchMetar(P.OFP.values.OFP.destination.icao_code)
        P.fetchTaf(P.OFP.values.OFP.origin.icao_code)
        P.fetchTaf(P.OFP.values.OFP.destination.icao_code)

        -- find TOC
        local iTOC = 1
        while P.OFP.values.OFP.navlog.fix[iTOC].ident ~= "TOC" do
            iTOC = iTOC + 1
        end
        P.OFP.values.OFP.iTOC = iTOC

        -- find max cruize Altitude
        local iTOC = 1
        local nfix = #P.OFP.values.OFP.navlog.fix
        local max_altitude = 0
        while iTOC <= nfix do
            if tonumber(P.OFP.values.OFP.navlog.fix[iTOC].altitude_feet) > max_altitude then 
                max_altitude = tonumber(P.OFP.values.OFP.navlog.fix[iTOC].altitude_feet)
            end
            iTOC = iTOC + 1
        end
        P.OFP.values.OFP.maxStepClimb = max_altitude
        


        formatOFPDisplay(P.OFP.values.OFP)
        if settings.appSettings.upload2FMC then
            fmc.uploadToZiboFMC(P.OFP.values.OFP)
        end
    end
    P.OFP.status = 2
end

function P.fechOFP()
    local userid = settings.appSettings.sbuser
    if string.len(userid) then
        local url = string.format(definitions.SIMBRIEFURL, userid)
        P.OFP.status = 1
        P.OFP.values = {}
        P.OFP.output = {string.format("Fetching %s's OFP...", userid)}
        sasl.net.downloadFileAsync(url, definitions.YANSHCACHESPATH .. definitions.APPNAMEPREFIX .. "_ofp.tmp", fetchOFP)
    end
end

local function fetchMetar(inUrl, inFilePath, inIsOk, inError)
    if onContentsDownloaded(inUrl, inFilePath, inIsOk, inError) then
        local values = sasl.readConfig(inFilePath, "xml")
        if values ~= nil then
            local icao_code = string.sub(values.AVWX.sanitized, 1, 4)
            P.METAR.values[icao_code] = values.AVWX.sanitized
            P.METAR.values['isError'] = false
            formatOFPDisplay(P.OFP.values.OFP)
        end
    else
        P.METAR.values['isError'] = true
        formatOFPDisplay(P.OFP.values.OFP)
    end
    P.METAR.status = 2
end

function P.fetchMetar(airport)
    local token = settings.appSettings.avwxtoken
    if string.len(airport) > 0 and string.len(token) > 0 then
        local url = string.format(definitions.AWVXURL, airport, token)
        P.METAR.status = 1
        P.METAR.values[airport] = nil
        P.METAR.values['isError'] = false
        formatOFPDisplay(P.OFP.values.OFP)
        sasl.net.downloadFileAsync(url, definitions.YANSHCACHESPATH .. definitions.APPNAMEPREFIX .. "_" .. airport .. "_metar.tmp", fetchMetar)
    end
end

local function fetchTaf(inUrl, inFilePath, inIsOk, inError)
    if onContentsDownloaded(inUrl, inFilePath, inIsOk, inError) then
        local values = sasl.readConfig(inFilePath, "xml")
        if values ~= nil then
            local icao_code = string.sub(values.AVWX.sanitized, 1, 4)
            P.METAR.values["taf_" .. icao_code] = string.gsub(values.AVWX.sanitized, "<br>","") -- some html tags may be here ????
            P.METAR.values['taf_isError'] = false
            formatOFPDisplay(P.OFP.values.OFP)
        end
    else
        P.METAR.values['taf_isError'] = true
        formatOFPDisplay(P.OFP.values.OFP)
    end
    P.METAR.status = 2
end

function P.fetchTaf(airport)
    local token = settings.appSettings.avwxtoken
    if string.len(airport) > 0 and string.len(token) > 0 then
        local url = string.format(definitions.AWVXTAFURL, airport, token)
        P.METAR.status = 1
        P.METAR.values["taf_" .. airport] = nil
        P.METAR.values['taf_isError'] = false
        formatOFPDisplay(P.OFP.values.OFP)
        sasl.net.downloadFileAsync(url, definitions.YANSHCACHESPATH .. definitions.APPNAMEPREFIX .. "_" .. airport .. "_taf.tmp", fetchTaf)
    end
end

function P.checkForUpdate()
    local url = definitions.GITHUBURL
    local updateAvailable = false
    local newVersion = ""
    downloadResult, contents = sasl.net.downloadFileContentsSync(url)
    if downloadResult then -- ... process data
        newVersion = helpers.cleanString(contents, true)
        sasl.logDebug(string.format("checkForUpdate: current version: %s, available version %s", definitions.VERSION, newVersion))
        if (newVersion) ~= (definitions.VERSION) then
            updateAvailable = true
            sasl.logInfo(string.format("checkForUpdate: New version available: %s", newVersion))
        end
    else
        sasl.logDebug("checkForUpdate FAILED")
    end
    return updateAvailable, newVersion
end

return queries
