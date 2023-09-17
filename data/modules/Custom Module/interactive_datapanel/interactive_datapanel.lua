-- interactive_datpanel.lua
-- 2021-08-08  Steve Wilson
-- Code example for SASL3
require("definitions")
require("windows")

defineProperty(size, {200,200})

size = get(size)

wSize = size[1]
hSize = size[2]


local wTitle = string.format("%s (%s)", definitions.APPNAMEPREFIXLONG, definitions.VERSION)
if updateAvailable then
    wTitle = wTitle .. " update available v" .. newVersion
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
        y = hSize - definitions.bannerHeight - 25,
        w = 100,
        h = definitions.buttonHeight,
    },
    metarButton = {
        t = "Refresh Metar",
        x = 120,
        y = hSize - definitions.bannerHeight - 25,
        w = 120,
        h = definitions.buttonHeight,
    },
    closeButton = {
        t = "x",
        x = wSize - definitions.closeXWidth,
        y = hSize - definitions.closeXHeight,
        w = definitions.closeXWidth,
        h = definitions.closeXHeight,
    },
    ofpText = {
        x = 10,
        y = hSize - definitions.bannerHeight - 50,
        w = 0,
        h = 0,
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
    position = {wdef.metarButton.x, wdef.metarButton.y, wdef.metarButton.w, wdef.metarButton.h}, -- FetchOFP
    cursor = definitions.cursor,
    onMouseDown = function()
        if qDatas.METAR.status ~= 1 and qDatas.OFP.status == 2 then
            qDatas.fetchMetar(qDatas.OFP.values.OFP.origin.icao_code)
            qDatas.fetchMetar(qDatas.OFP.values.OFP.destination.icao_code)
        end
    end
}, interactive {
    position = {wdef.closeButton.x, wdef.closeButton.y, wdef.closeButton.w, wdef.closeButton.h}, -- Close the window
    onMouseDown = function()
        interactive_datapanel:setIsVisible(false)
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
    windows.drawButton(wdef.fetchButton, qDatas.OFP.status ~= 1)
    if #qDatas.OFP.output > 1 then -- display Metar button only if OFP is displayed
        windows.drawButton(wdef.metarButton, qDatas.METAR.status ~= 1)
    end
    windows.drawBlockTexts(wdef.ofpText, qDatas.OFP.output)

    drawAll(components) -- This line is not always necessary for drawing, but if you want to see your click zones, in X-Plane 
    -- include it at the end of your draw function	

end
