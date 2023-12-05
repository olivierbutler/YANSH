local P = {}
settings = P -- package name

require("definitions")

local settingPath = definitions.XPOUTPUTPATH .. "preferences" .. definitions.OSSEPARATOR .. definitions.APPNAMEPREFIX .. ".prf"
local settingFormat = 'info'
local settingLegacyPath = definitions.XPRESSOURCESPATH .. "plugins" .. definitions.OSSEPARATOR .. "FlyWithLua" .. definitions.OSSEPARATOR .. "Scripts" .. definitions.OSSEPARATOR ..
                              "simbrief_helper.ini"
local settingLegacyFormat = 'ini'

local defaultSetting = {
    sbuser = "",
    avwxtoken = "",
    upload2FMC = false,
    acf = {},
}

local p_fov = globalProperty("sim/graphics/view/field_of_view_deg")

local function migrateFovSettings(currentSettings)
    local fovPath = definitions.XPRESSOURCESPATH .. "plugins" .. definitions.OSSEPARATOR .. "FlyWithLua" .. definitions.OSSEPARATOR .. "Scripts" .. definitions.OSSEPARATOR
    local contents = sasl.listFiles(fovPath)
    local fov_value = nil
    -- currentSettings.acf = {}
    if #contents > 0 then
        for i = 1, #contents do
            local currentName = contents[i].name
            if contents[i].type == 'file' and string.find(currentName, "fov_keeper_") ~= nil and string.find(currentName, ".ini") ~= nil then
                currentName = string.gsub(currentName, "fov_keeper_", "")
                currentName = string.gsub(currentName, ".ini", "")
                local file = io.open(fovPath .. contents[i].name, "r")
                io.input(file)
                fov_value = io.read()
                currentSettings.acf[currentName] = {}
                currentSettings.acf[currentName].fov = fov_value
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
        sasl.logWarning("Unable to write settings to disk")
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

    -- some init are not done well
    if type(currentSetting.sbuser) ~= 'string'  then 
        currentSetting.sbuser = ""
    end    
    if #currentSetting.sbuser == 0 then 
        currentSetting.sbuser = ""
    end    
    if type(currentSetting.avwxtoken) ~= 'string' then 
        currentSetting.avwxtoken = ""
    end    
    if #currentSetting.avwxtoken == 0 then 
        currentSetting.avwxtoken = ""
    end

    -- extra optional setting
    if currentSetting.hideMagicSquare == nil then
        currentSetting.hideMagicSquare = false
    else 
        if type(currentSetting.hideMagicSquare) ~= 'boolean' then
            currentSetting.hideMagicSquare = false
        end    
    end    

    -- extra optional setting
    if currentSetting.ziboReserveFuelDisable == nil then
        currentSetting.ziboReserveFuelDisable = false
    else 
        if type(currentSetting.ziboReserveFuelDisable) ~= 'boolean' then
            currentSetting.ziboReserveFuelDisable = false
        end    
    end    

    -- extra optional setting
    if currentSetting.displayBorder == nil then
        currentSetting.displayBorder = false
    else 
        if type(currentSetting.displayBorder) ~= 'boolean' then
            currentSetting.displayBorder = false
        end    
    end    

    -- extra optional setting
    if currentSetting.magicLeftClick == nil then
        currentSetting.magicLeftClick = false
    else 
        if type(currentSetting.magicLeftClick) ~= 'boolean' then
            currentSetting.magicLeftClick = false
        end    
    end    
    
    return currentSetting
end

function P.getFov()
    return math.floor(get(p_fov))
end

function P.setFov(newFov)
    set(p_fov, math.floor(newFov))
end

function P.restoreFov()
    if P.appSettings.acf ~= nil then
        local my_aircraft = string.gsub(sasl.getAircraft(), ".acf", "")
        if #my_aircraft > 0 then
            local newFov = P.appSettings.acf[my_aircraft]
            if newFov ~= nil then
                sasl.logInfo(string.format("Restoring Fov %s for aircraft %s", newFov.fov, my_aircraft))
                P.setFov(newFov.fov)
            else
                sasl.logInfo(string.format("Saving Fov %s for aircraft %s", P.getFov(), my_aircraft))
                P.savFov()
            end
        end
    end
end

function P.savFov()
    local my_aircraft = string.gsub(sasl.getAircraft(), ".acf", "")
    if P.appSettings.acf[my_aircraft] == nil then 
        P.appSettings.acf[my_aircraft] = {}
    end
    P.appSettings.acf[my_aircraft].fov = P.getFov()
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
