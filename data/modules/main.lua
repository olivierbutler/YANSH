--  TODO
-- finir l'affichage des infos // metar et ameliorer le decode xml
-- populate FMC
-- user setting windows

require("definitions")
require("settings")
qDatas = require("queries")

sasl.logInfo(string.format("Starting %s v%s", definitions.APPNAMEPREFIX, definitions.VERSION))

sasl.options.setAircraftPanelRendering(false)
sasl.options.set3DRendering(false)
sasl.options.setInteractivity(true)

updateAvailable, newVersion = qDatas.checkForUpdate()

include "keyboard_handler"

local xRoot, yRoot, wRoot, hRoot = sasl.windows.getMonitorBoundsOS(0)

local winRoot = contextWindow {
    noDecore = true,
    position = {xRoot + 10, yRoot + 10, 20, 20},
    visible = true,
    noResize = true,
    vrAuto = true,
    noBackground = true,
    -- layer       = SASL_CW_LAYER_MODAL,
    noMove = true,
    components = {root_toggle {
        position = {0, 0, 20, 20},
        bg = {0, 0, 0, 0.5},
        cursor = definitions.cursor,
    }}
}

local dp_height = 700
local dp_width = 700
local dp_x_org = xRoot + wRoot - dp_width
local dp_y_org = yRoot -- + hRoot  - dp_height
interactive_datapanel = contextWindow {
    name = "interactive_datapanel",
    position = {dp_x_org, dp_y_org, dp_width, dp_height},
    visible = true,
    noResize = true,
    vrAuto = true,
    noBackground = true,
    noDecore = true,
    proportional = true,
    components = {interactive_datapanel {
        position = {0, 0, dp_width, dp_height},
        size = {dp_width, dp_height}
    }}
}

interactive_datapanel:setMovable(true)

function show_hide()
    interactive_datapanel:setIsVisible(not interactive_datapanel:isVisible())
end

local status = true

-- will be called when clicking on the first menu
function change_menu()
    -- flip status
    status = not status
    -- update status of menu entry (normal or greyed)
    sasl.enableMenuItem(menu_main, menu_action, status and 1 or 0)
    -- change menu text accordingly
    sasl.setMenuItemName(menu_main, menu_option, status and "Disable show/hide" or "Enable show/hide")
    -- check menu if enabled
    sasl.setMenuItemState(menu_main, menu_option, status and MENU_CHECKED or MENU_UNCHECKED)
end

-- create our top level menu in plugins menu
menu_master = sasl.appendMenuItem(PLUGINS_MENU_ID, definitions.APPNAMEPREFIXLONG)
-- make our menu entry a submenu
menu_main = sasl.createMenu("", PLUGINS_MENU_ID, menu_master)
-- add menu entry
menu_action = sasl.appendMenuItem(menu_main, "Show/hide " .. definitions.APPNAMEPREFIX, show_hide)

settings.restoreFov()

function onAirportLoaded(flightNumber)
    sasl.logInfo("Starting Flight #" .. flightNumber .. " " .. sasl.getAircraftPath() .. " " .. sasl.getAircraft())
    settings.restoreFov()
end

