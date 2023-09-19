local P = {}
queries = P -- package name

require("definitions")
require("settings")
require("helpers")
fmc = require("fmc")

P.OFP = {
    status = 0, -- 0 never set, 1 query in progress, 2 data ready
    values = {},
    output = {}
}

P.METAR = {
    status = 0, -- 0 never set, 1 query in progress, 2 data ready
    values = {}
}

local function onContentsDownloaded(inUrl, inFilePath, inIsOk, inError)
    if inIsOk then
        logInfo(string.format("File downloaded! from %s to %s", inUrl, inFilePath))
    else
        sasl.logWarning(string.format("Downloading FAILED! from %s with error %s", inUrl, inError))
    end
    return inIsOk
end

local function fetchfmsFile(inUrl, inFilePath, inIsOk, inError)
    onContentsDownloaded(inUrl, inFilePath, inIsOk, inError)
end

local function formatOFPDisplay(ofpData)
    local t = {}

    pcall(function()
        local route = string.format("%s%s%s", ofpData.origin.icao_code, ofpData.destination.icao_code, definitions.OFPSUFFIX)

        -- find TOC
        local iTOC = 1
        while ofpData.navlog.fix[iTOC].ident ~= "TOC" do
            iTOC = iTOC + 1
        end

        if ofpData.params.time_generated ~= nil then
            local ofpAge = os.time() - ofpData.params.time_generated
            if ofpAge > 2 * 60 * 60 then
                table.insert(t, "##FF0000FF") -- change color
                table.insert(t, "Warning, this OFP is older than 2 hours")
                table.insert(t, "#" .. definitions.textColorHtml) -- change color
                table.insert(t, "#" .. definitions.textColorHtml) -- change color
                table.insert(t, "")
            end

        end
        if ofpData.params.ofp_layout  ~= "LIDO" then
            table.insert(t, "##FF00BFFF") -- change color
            table.insert(t, string.format("OFP Layout: %s, (LIDO layout is prefered),", ofpData.params.ofp_layout))
            table.insert(t, "FMC's UPLINK DATA (Wind forecasts) will not be available")
            table.insert(t, "")
        end

        table.insert(t, "#" .. definitions.textColorHtml) -- change color
        table.insert(t,
            string.format("FMS CO ROUTE:             %s%s%s / %s%s%s", ofpData.origin.icao_code, ofpData.destination.icao_code, definitions.OFPSUFFIX, ofpData.origin.iata_code,
                ofpData.destination.iata_code, definitions.OFPSUFFIX))
        table.insert(t, string.format("Aircraft:                 %s", ofpData.aircraft.name))
        table.insert(t, string.format("Airports:                 %s - %s", ofpData.origin.name, ofpData.destination.name))
        table.insert(t,
            string.format("Route:                    %s/%s %s %s/%s", ofpData.origin.icao_code, ofpData.origin.plan_rwy, ofpData.general.route, ofpData.destination.icao_code,
                ofpData.destination.plan_rwy))
        table.insert(t, string.format("Distance:                 %d nm ETE:%s", ofpData.general.route_distance, helpers.timeConvert(ofpData.times.est_time_enroute, "h")))
        table.insert(t, string.format("Cruise Altitude:         %s ft", helpers.format_thousand(ofpData.general.initial_altitude)))
        table.insert(t, string.format("Elevations:               %s (%d ft) - %s (%d ft)", ofpData.origin.icao_code, ofpData.origin.elevation, ofpData.destination.icao_code,
            ofpData.destination.elevation))
        table.insert(t, "")
        table.insert(t, string.format("Block Fuel:              %s %s", helpers.format_thousand((math.ceil(ofpData.fuel.plan_ramp / 100) * 100 + 100)), ofpData.params.units))
        table.insert(t, string.format("Takeoff Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.min_takeoff), ofpData.params.units))
        table.insert(t, string.format("Trip Fuel:               %s %s", helpers.format_thousand((math.ceil(ofpData.fuel.enroute_burn / 100) * 100 + 100)), ofpData.params.units))
        table.insert(t, string.format("Reserve Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.reserve), ofpData.params.units))
        table.insert(t, string.format("Alternate Fuel:          %s %s", helpers.format_thousand(ofpData.fuel.alternate_burn), ofpData.params.units))
        table.insert(t, string.format("Res+Alt Fuel:            %s %s", helpers.format_thousand(ofpData.fuel.alternate_burn + ofpData.fuel.reserve), ofpData.params.units))
        table.insert(t, "")
        table.insert(t, string.format("Pax:                      %6d", ofpData.weights.pax_count))
        table.insert(t, string.format("Cargo:                   %s %s", helpers.format_thousand(ofpData.weights.cargo), ofpData.params.units))
        table.insert(t, string.format("Payload:                 %s %s", helpers.format_thousand(ofpData.weights.payload), ofpData.params.units))
        table.insert(t, string.format("ZFW:                      %6.1f", ofpData.weights.est_zfw / 1000))
        table.insert(t, string.format("Cost Index:               %6d", ofpData.general.costindex))
        table.insert(t, "")
        table.insert(t, "##CA321280") -- change color
        table.insert(t, string.format("TOC Wind:                %03d/%03d", ofpData.navlog.fix[iTOC].wind_dir, ofpData.navlog.fix[iTOC].wind_spd))
        table.insert(t, string.format("TOC Temp:                    %3d °C", ofpData.navlog.fix[iTOC].oat))
        table.insert(t, string.format("TOC ISA Dev:                 %3d °C", ofpData.navlog.fix[iTOC].oat_isa_dev))

        table.insert(t, "")
        if settings.appSettings.avwxtoken == "" then
            table.insert(t, "##FF0000FF") -- change color
            table.insert(t, "AVWX is not configured: updated METARs not available")
            table.insert(t, "#" .. definitions.textColorHtml) -- change color
        else
            if P.METAR.values[ofpData.origin.icao_code] ~= nil then
                table.insert(t, string.format("%s", P.METAR.values[ofpData.origin.icao_code]))
            else
                table.insert(t, string.format("Fetching %s METAR...", ofpData.origin.icao_code))
            end
            if P.METAR.values[ofpData.destination.icao_code] ~= nil then
                table.insert(t, string.format("%s", P.METAR.values[ofpData.destination.icao_code]))
            else
                table.insert(t, string.format("Fetching %s METAR...", ofpData.destination.icao_code))
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
        helpers.cp_file(inFilePath, xmlFilePath)

        -- local fmsFileUrl = P.OFP.values.OFP.fms_downloads.directory .. P.OFP.values.OFP.fms_downloads.xpe.link
        local fmsFileUrl = "https://www.simbrief.com/system/briefing.fmsdl.php?formatget=flightplans/" .. P.OFP.values.OFP.fms_downloads.xpe.link
        sasl.net.downloadFileAsync(fmsFileUrl, definitions.XPFMSPATH .. xmlFile .. ".fms", fetchfmsFile)

        P.fetchMetar(P.OFP.values.OFP.origin.icao_code)
        P.fetchMetar(P.OFP.values.OFP.destination.icao_code)

        formatOFPDisplay(P.OFP.values.OFP)
        fmc.uploadToZiboFMC(P.OFP.values.OFP)
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
        sasl.net.downloadFileAsync(url, definitions.XPOUTPUTPATH .. definitions.APPNAMEPREFIX .. "_ofp.tmp", fetchOFP)
    end
end

local function fetchMetar(inUrl, inFilePath, inIsOk, inError)
    if onContentsDownloaded(inUrl, inFilePath, inIsOk, inError) then
        local values = sasl.readConfig(inFilePath, "xml")
        if values ~= nil then
            local icao_code = string.sub(values.AVWX.raw, 1, 4)
            P.METAR.values[icao_code] = values.AVWX.raw
            formatOFPDisplay(P.OFP.values.OFP)
        end
    end
    P.METAR.status = 2
end

function P.fetchMetar(airport)
    local token = settings.appSettings.avwxtoken
    if string.len(airport) and string.len(token) then
        local url = string.format(definitions.AWVXURL, airport, token)
        P.METAR.status = 1
        P.METAR.values[airport] = nil
        formatOFPDisplay(P.OFP.values.OFP)
        sasl.net.downloadFileAsync(url, definitions.XPOUTPUTPATH .. definitions.APPNAMEPREFIX .. "_" .. airport .. "_metar.tmp", fetchMetar)
    end
end

function P.checkForUpdate()
    local url = definitions.GITHUBURL
    local updateAvailable = false
    local newVersion = ""
    downloadResult, contents = sasl.net.downloadFileContentsSync(url)
    if downloadResult then -- ... process data
        for i = 1, string.len(contents), 1 do
            -- ugly filtering
            if string.byte(string.sub(contents, i, i)) > 32 then
                newVersion = newVersion .. string.sub(contents, i, i)
            end
        end
        sasl.logInfo(string.format("checkForUpdate: current version: %s, available version %s", definitions.VERSION, newVersion))
        if (newVersion) ~= (definitions.VERSION) then
            updateAvailable = true
            sasl.logInfo(string.format("checkForUpdate: New version available: %s", newVersion))
        end
    else
        sasl.logInfo("checkForUpdate FAILED")
    end
    return updateAvailable, newVersion
end

return queries
