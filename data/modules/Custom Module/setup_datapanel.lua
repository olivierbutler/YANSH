-- interactive_datpanel.lua
-- 2021-08-08  Steve Wilson
-- Code example for SASL3
require("definitions")
require("windows")
require("settings")
require("messages")

defineProperty(size, {200, 200})

size = get(size)

wSize = size[1]
hSize = size[2]

local wTitle = string.format("%s - " .. messages.translation['SETUP'], definitions.APPNAMEPREFIXLONG)

wdef = {
    mainWindow = {
        w = wSize,
        h = hSize,
        wtitle = wTitle
    },
    closeButton = {
        t = "x",
        x = wSize - definitions.closeXWidth,
        y = hSize - definitions.closeXHeight,
        w = definitions.closeXWidth,
        h = definitions.closeXHeight,
        withBorder = false
    },
    debugMode = {
        t = messages.translation['DEBUGMODE'],
        value = false,
        x = 10,
        y = hSize - 270,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    displayBorder = {
        t = messages.translation['DISPLAYBORDER'],
        value = settings.appSettings.displayBorder,
        x = 10,
        y = hSize - 240,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    magicLeftClick = {
        t = messages.translation['MAGICLEFTCLICK'],
        value = settings.appSettings.magicLeftClick,
        x = 10,
        y = hSize - 210,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    hideMagicSquare = {
        t = messages.translation['HIDEMSQUARE'],
        value = settings.appSettings.hideMagicSquare,
        x = 10,
        y = hSize - 180,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    ziboReserveFuelDisable = {
        t = messages.translation['DISABLERESERVEFUEL'],
        value = settings.appSettings.ziboReserveFuelDisable,
        x = 10,
        y = hSize - 150,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    ziboFmc = {
        t = messages.translation['UPLINKZIBO'],
        value = settings.appSettings.upload2FMC,
        x = 10,
        y = hSize - 120,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight
    },
    sbUser = {
        t = messages.translation['SBUSERNAME'],
        value = settings.appSettings.sbuser,
        x = 10,
        y = hSize - 60,
        w = 200,
        h = definitions.lineHeight * 1.5,
        isFocused = false
    },
    sbUserPaste = {
        t = messages.translation['PASTE'],
        x = 400,
        y = hSize - 60,
        w = 120,
        h = definitions.buttonHeight
    }
}

components = {interactive {
    position = {wdef.ziboFmc.x, wdef.ziboFmc.y, wdef.ziboFmc.w, wdef.ziboFmc.h}, -- FMC uplink auto FMC
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.appSettings.upload2FMC = not settings.appSettings.upload2FMC
        settings.writeSettings(settings.appSettings)
        wdef.ziboFmc.value = settings.appSettings.upload2FMC
    end
},interactive {
    position = {wdef.hideMagicSquare.x, wdef.hideMagicSquare.y, wdef.hideMagicSquare.w, wdef.hideMagicSquare.h}, -- Hide Magic square
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.appSettings.hideMagicSquare = not settings.appSettings.hideMagicSquare
        settings.writeSettings(settings.appSettings)
        show_hide_magic_square(not settings.appSettings.hideMagicSquare)
        wdef.hideMagicSquare.value = settings.appSettings.hideMagicSquare
    end
},interactive {
    position = {wdef.ziboReserveFuelDisable.x, wdef.ziboReserveFuelDisable.y, wdef.ziboReserveFuelDisable.w, wdef.ziboReserveFuelDisable.h}, -- Disable FMC Reserve
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.appSettings.ziboReserveFuelDisable = not settings.appSettings.ziboReserveFuelDisable
        settings.writeSettings(settings.appSettings)
        wdef.ziboReserveFuelDisable.value = settings.appSettings.ziboReserveFuelDisable
    end
},interactive {
    position = {wdef.debugMode.x, wdef.debugMode.y, wdef.debugMode.w, wdef.debugMode.h}, -- Debug Mode
    cursor = definitions.cursor,
    onMouseDown = function()
        wdef.debugMode.value = not wdef.debugMode.value
        if wdef.debugMode.value then 
            sasl.setLogLevel(LOG_DEBUG)
            sasl.logDebug("log mode set to DEBUG")
        else
            sasl.setLogLevel(LOG_INFO)
            sasl.logInfo("log mode set to INFO")
        end
    end
},interactive {
    position = {wdef.displayBorder.x, wdef.displayBorder.y, wdef.displayBorder.w, wdef.displayBorder.h}, -- display borders
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.appSettings.displayBorder = not settings.appSettings.displayBorder
        settings.writeSettings(settings.appSettings)
        wdef.displayBorder.value = settings.appSettings.displayBorder
        sasl.scheduleProjectReboot()
    end
},interactive {
    position = {wdef.magicLeftClick.x, wdef.magicLeftClick.y, wdef.magicLeftClick.w, wdef.magicLeftClick.h}, -- Magic left click
    cursor = definitions.cursor,
    onMouseDown = function()
        settings.appSettings.magicLeftClick = not settings.appSettings.magicLeftClick
        settings.writeSettings(settings.appSettings)
        wdef.magicLeftClick.value = settings.appSettings.magicLeftClick
    end
}, interactive {
    position = {wdef.closeButton.x, wdef.closeButton.y, wdef.closeButton.w, wdef.closeButton.h}, -- Close the window
    cursor = definitions.cursor,
    onMouseDown = function()
        interactive_datapanel:setIsVisible(true)
        setup_datapanel:setIsVisible(false)
    end
}}

function update()

    -- If any value changes that affects either drawing or perhaps one of the interactive functions, you must
    -- get and evaluate it each flight loop in order to remain current with the state of the simulation.
    -- There are lots of ways to write this sort of thing.  The important thing is to write it in a way that
    -- you can easily understand later.  (Don't forget comments)

end

function draw()

    windows.drawWindowTemplate(wdef.mainWindow)
    windows.drawButton(wdef.closeButton, true)
    windows.drawButton(wdef.sbUserPaste, true)

    windows.inputTextBox(wdef.sbUser)

    windows.drawCheckBox(wdef.ziboFmc)
    windows.drawCheckBox(wdef.debugMode)
    windows.drawCheckBox(wdef.hideMagicSquare)
    windows.drawCheckBox(wdef.ziboReserveFuelDisable)
    windows.drawCheckBox(wdef.displayBorder)
    windows.drawCheckBox(wdef.magicLeftClick) 

    drawAll(components) -- This line is not always necessary for drawing, but if you want to see your click zones, in X-Plane 
    -- include it at the end of your draw function	

end
