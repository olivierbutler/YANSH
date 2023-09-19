-- interactive_datpanel.lua
-- 2021-08-08  Steve Wilson
-- Code example for SASL3
require("definitions")
require("windows")
require("settings")

defineProperty(size, {200, 200})

size = get(size)

wSize = size[1]
hSize = size[2]

local wTitle = string.format("%s - Setup", definitions.APPNAMEPREFIXLONG)

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
        h = definitions.closeXHeight
    },
    ziboFmc = {
        t = "Upload the 737's FMC automaticaly after fetching the OFP (Zibo B737 only)",
        x = 5,
        y = hSize - 100,
        w = definitions.checkBoxWidth,
        h = definitions.checkBoxHeight,
    }
}

components = {interactive {
    position = {wdef.ziboFmc.x, wdef.ziboFmc.y, wdef.ziboFmc.w, wdef.ziboFmc.h}, -- FetchOFP
    cursor = definitions.cursor,
    onMouseDown = function()
       settings.appSettings.upload2FMC = not settings.appSettings.upload2FMC
       settings.writeSettings(settings.appSettings)
    end
}, interactive {
    position = {wdef.closeButton.x, wdef.closeButton.y, wdef.closeButton.w, wdef.closeButton.h}, -- Close the window
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

    windows.drawCheckBox(wdef.ziboFmc, settings.appSettings.upload2FMC)

    drawAll(components) -- This line is not always necessary for drawing, but if you want to see your click zones, in X-Plane 
    -- include it at the end of your draw function	

end
