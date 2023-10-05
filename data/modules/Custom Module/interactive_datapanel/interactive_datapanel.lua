-- interactive_datpanel.lua
-- 2021-08-08  Steve Wilson
-- Code example for SASL3
require("definitions")
require("windows")
require("fmc")
require("messages")

defineProperty(size, {200, 200})

size = get(size)

wSize = size[1]
hSize = size[2]

local TTimer = sasl.createTimer()
local T200msTimer = 50 * 1000 -- 200 ms
sasl.startTimer(TTimer)
local wTitle = string.format("%s (%s)", definitions.APPNAMEPREFIXLONG, definitions.VERSION)
if updateAvailable then
    wTitle = wTitle .. " " .. messages.translation['UPDATEAVAILABLE'] .. " v" .. newVersion
end

wdef = {
    mainWindow = {
        w = wSize,
        h = hSize,
        wtitle = wTitle
    },
    fetchButton = {
        t = "Fetch OFP",
        x = 10,
        y = hSize - definitions.bannerHeight - 40,
        w = 100,
        h = definitions.buttonHeight
    },
    metarButton = {
        t = "Refresh Metar",
        x = 120,
        y = hSize - definitions.bannerHeight - 40,
        w = 120,
        h = definitions.buttonHeight
    },
    uplinkFMC = {
        t = "uplink to FMC",
        x = 330,
        y = hSize - definitions.bannerHeight - 40,
        w = 120,
        h = definitions.buttonHeight
    },
    setupButton = {
        t = messages.translation['SETUP'],
        x = wSize - 130,
        y = hSize - definitions.bannerHeight - 40,
        w = 120,
        h = definitions.buttonHeight
    },
    closeButton = {
        t = "x",
        x = wSize - definitions.closeXWidth,
        y = hSize - definitions.closeXHeight,
        w = definitions.closeXWidth,
        h = definitions.closeXHeight,
        withBorder = false
    },
    fovMinus = {
        t = "-",
        x = 5,
        y = hSize - definitions.closeXHeight,
        w = definitions.closeXWidth,
        h = definitions.closeXHeight,
        withBorder = false
    },
    fovPlus = {
        t = "+",
        x = 5 + 25 + definitions.closeXWidth,
        y = hSize - definitions.closeXHeight,
        w = definitions.closeXWidth,
        h = definitions.closeXHeight,
        withBorder = false
    },
    fovText = {
        x = 5 + definitions.closeXHeight + 5,
        y = hSize - definitions.bannerHeight + definitions.linePaddingBottom,
        w = 0,
        h = 0
    },
    ofpText = {
        x = 10,
        y = hSize - definitions.bannerHeight - 70,
        w = 0,
        h = 0
    }

}

components = {interactive {
    position = {wdef.fetchButton.x, wdef.fetchButton.y, wdef.fetchButton.w, wdef.fetchButton.h}, -- FetchOFP
    cursor = definitions.cursor,
    onMouseDown = function()
        if qDatas.OFP.status ~= 1 then
            qDatas.fechOFP()
        end
    end
}, interactive {
    position = {wdef.uplinkFMC.x, wdef.uplinkFMC.y, wdef.uplinkFMC.w, wdef.uplinkFMC.h}, -- uplinkFMC
    cursor = definitions.cursor,
    onMouseDown = function()
        if fmc.isOnGround() and fmc.isFMConPower() and (#fmc.fmcKeyQueue == 0) then
            fmc.uploadToZiboFMC(qDatas.OFP.values.OFP)
        end
    end

}, interactive {
    position = {wdef.metarButton.x, wdef.metarButton.y, wdef.metarButton.w, wdef.metarButton.h}, -- MetarOFP
    cursor = definitions.cursor,
    onMouseDown = function()
        if qDatas.METAR.status ~= 1 and qDatas.OFP.status == 2 and #settings.appSettings.avwxtoken then
            qDatas.fetchMetar(qDatas.OFP.values.OFP.origin.icao_code)
            qDatas.fetchMetar(qDatas.OFP.values.OFP.destination.icao_code)
        end
    end
}, interactive {
    position = {wdef.closeButton.x, wdef.closeButton.y, wdef.closeButton.w, wdef.closeButton.h}, -- Close the window
    cursor = definitions.cursor,
    onMouseDown = function()
        interactive_datapanel:setIsVisible(false)
    end
}, interactive {
    position = {wdef.setupButton.x, wdef.setupButton.y, wdef.setupButton.w, wdef.setupButton.h}, -- Setup button
    cursor = definitions.cursor,
    onMouseDown = function()
        interactive_datapanel:setIsVisible(false)
        setup_datapanel:setIsVisible(true)
    end
}, interactive {
    position = {wdef.fovPlus.x, wdef.fovPlus.y, wdef.fovPlus.w, wdef.fovPlus.h}, -- Fov + button
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.incFov(1)
    end
}, interactive {
    position = {wdef.fovMinus.x, wdef.fovMinus.y, wdef.fovMinus.w, wdef.fovMinus.h}, -- Fov - button
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.incFov(-1)
    end
}}

function update()

    -- If any value changes that affects either drawing or perhaps one of the interactive functions, you must
    -- get and evaluate it each flight loop in order to remain current with the state of the simulation.
    -- There are lots of ways to write this sort of thing.  The important thing is to write it in a way that
    -- you can easily understand later.  (Don't forget comments)

    --   fmc.initTailNum()
    if fmc.isZibo then
        if sasl.getElapsedMicroseconds(TTimer) > T200msTimer then
            sasl.resetTimer(TTimer)
            sasl.startTimer(TTimer)
            sasl.logDebug("Timer reach " .. T200msTimer .. " uS")
            fmc.pushKeyToFMC()
        end
    end

end

function draw()

    windows.drawWindowTemplate(wdef.mainWindow)
    windows.drawButton(wdef.closeButton, true)
    windows.drawButton(wdef.fovMinus, true)
    windows.drawButton(wdef.fovPlus, true)
    windows.drawBlockTexts(wdef.fovText, {settings.getFov()})
    windows.drawButton(wdef.setupButton, true)

    windows.drawButton(wdef.fetchButton, qDatas.OFP.status ~= 1 and #settings.appSettings.sbuser and definitions.XPFMSPATHEXIST)
    if #settings.appSettings.sbuser == 0 or definitions.XPFMSPATHEXIST == false then
        local error_message = {}
        if #settings.appSettings.sbuser == 0 then
            table.insert(error_message, messages.translation['NOUSERNAME'])
        end
        if definitions.XPFMSPATHEXIST == false then
            table.insert(error_message, messages.translation['NOFMSFOLDER'])
        end
        windows.drawBlockTexts(wdef.ofpText, error_message)
    else
        windows.drawBlockTexts(wdef.ofpText, qDatas.OFP.output)
    end
    if #qDatas.OFP.output > 1 and #settings.appSettings.avwxtoken then -- display Metar button only if OFP is displayed and avwxtoken defined
        windows.drawButton(wdef.metarButton, qDatas.METAR.status ~= 1)

        if fmc.isZibo then
            windows.drawButton(wdef.uplinkFMC, fmc.isOnGround() and fmc.isFMConPower() and (#fmc.fmcKeyQueue == 0))
        end
    end
    windows.drawBlockTexts(wdef.ofpText, qDatas.OFP.output)

    drawAll(components) -- This line is not always necessary for drawing, but if you want to see your click zones, in X-Plane 
    -- include it at the end of your draw function	

end
