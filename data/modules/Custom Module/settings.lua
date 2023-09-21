local P = {}
settings = P -- package name

require("definitions")

local settingPath = definitions.XPOUTPUTPATH .. "preferences" .. definitions.OSSEPARATOR .. definitions.APPNAMEPREFIX .. ".prf"
local settingFormat = 'ini'
local settingLegacyPath = definitions.XPRESSOURCESPATH .. "plugins" .. definitions.OSSEPARATOR .. "FlyWithLua" .. definitions.OSSEPARATOR .. "Scripts" .. definitions.OSSEPARATOR ..
                              "simbrief_helper.ini"
local settingLegacyFormat = 'ini'

local defaultSetting = {
    sbuser = "",
    avwxtoken = "",
    upload2FMC = false,
    fov = {},
}

local p_fov = globalProperty("sim/graphics/view/field_of_view_deg")

local function migrateFovSettings(currentSettings)
    local fovPath = definitions.XPRESSOURCESPATH .. "plugins" .. definitions.OSSEPARATOR .. "FlyWithLua" .. definitions.OSSEPARATOR .. "Scripts" .. definitions.OSSEPARATOR
    local contents = sasl.listFiles(fovPath)
    local fov_value = nil
    currentSettings.fov = {}
    if #contents > 0 then
        for i = 1, #contents do
            local currentName = contents[i].name
            if contents[i].type == 'file' and string.find(currentName, "fov_keeper_") ~= nil and string.find(currentName, ".ini") ~= nil then
                currentName = string.gsub(currentName, "fov_keeper_", "")
                currentName = string.gsub(currentName, ".ini", "")
                local file = io.open(fovPath .. contents[i].name, "r")
                io.input(file)
                fov_value = io.read()
                currentSettings.fov[currentName] = fov_value
                io.close(file)
            end
        end
    end
    return currentSettings
end

-- return tableTocheck if valid
-- else the defaultSetting
local function checkSettings(tableTocheck)
    if tableTocheck == nil then
        return defaultSetting
    end
    for k, v in pairs(defaultSetting) do
        if tableTocheck[k] == nil then
            sasl.logWarning("Setting not found, using default")
            return defaultSetting
        end
    end
    return tableTocheck
end

function P.writeSettings(currentSetting)
    if sasl.writeConfig(settingPath, settingFormat, currentSetting) == false then
        sasl.logError("Unable to write settings to disk")
    end
end

function P.getSettings()
    local lSettings = sasl.readConfig(settingPath, settingFormat)
    if lSettings == nil then
        -- try the legacy file
        lSettings = sasl.readConfig(settingLegacyPath, settingLegacyFormat)
        if lSettings ~= nil then
            local importSettings = defaultSetting
            if lSettings.simbrief ~= nil then
                if lSettings.simbrief.username ~= nil then
                    importSettings.sbuser = lSettings.simbrief.username
                end
                if lSettings.simbrief.avwxtoken ~= nil then
                    importSettings.avwxtoken = lSettings.simbrief.avwxtoken
                end
                if lSettings.simbrief.upload2FMC ~= nil then
                    importSettings.upload2FMC = lSettings.simbrief.upload2FMC
                end
                importSettings = migrateFovSettings(importSettings)
                P.writeSettings(importSettings)
                return importSettings
            end
        end
    end
    local currentSetting = checkSettings(lSettings)
    if lSettings == nil then
        P.writeSettings(currentSetting)
    end
    return currentSetting
end

function P.getFov()
    return get(p_fov)
end

function P.setFov(newFov)
    set(p_fov, newFov)
end

function P.restoreFov()
    if P.appSettings.fov ~= nil then
        local my_aircraft = string.gsub(sasl.getAircraft(), ".acf", "")
        if #my_aircraft > 0 then
            local newFov = P.appSettings.fov[my_aircraft]
            if newFov ~= nil then
                sasl.logInfo(string.format("Restoring Fov %s for aircraft %s", newFov, my_aircraft))
                settings.setFov(newFov)
            else
                sasl.logInfo(string.format("Saving Fov %s for aircraft %s", P.getFov(), my_aircraft))
                P.savFov()
            end
        end
    end
end

function P.savFov()
    local my_aircraft = string.gsub(sasl.getAircraft(), ".acf", "")
    P.appSettings.fov[my_aircraft] = settings.getFov()
    P.writeSettings(P.appSettings)
end

function P.incFov(value)
    local currentFov = math.floor(P.getFov())
    currentFov = currentFov + value
    if currentFov >= 10 and currentFov <= 150 then
        P.setFov(currentFov)
        P.savFov()
    end

end

P.appSettings = P.getSettings()

return settings
