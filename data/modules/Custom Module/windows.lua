local P = {}
windows = P -- package name

require("definitions")

--[[
    strColor format: like htmlCode #RRGGBB (only R,G,B)  or #RRGGBBAA ( R,G,B, and alpha)
    return table { rvalue, gvalue, bvalue, avalue}
    avalue = 1 if strColor is not given with AA 
]]
local function htmlColorToSasl(strColor)
    if string.sub(strColor, 1, 1) == '#' then
        local R = tonumber(string.sub(strColor, 2, 3), 16) / 255
        local G = tonumber(string.sub(strColor, 4, 5), 16) / 255
        local B = tonumber(string.sub(strColor, 6, 7), 16) / 255
        local A = tonumber(string.sub(strColor, 8, 9), 16)
        if A == nil then
            A = 1
        else
            A = A / 255
        end
        return {R, G, B, A}
    end
    return {0, 0, 0, 1}
end

--[[
button definition 
{   t = button caption / optional (no text if omitted)
    x = button x origin / mandatory
    y = button y origin / mandatory
    w = button width / mandatory
    h = button height / mandatory
    bg = button background color / optional ( definitions.buttonColor if omitted)
    acolor = active button text color / optional ( definitions.activeButtonColor if omitted)
    dcolor = disable button text color / optional ( definitions.disableButtonColor if omitted)
    linePadding = button text bottom padding color / optional ( definitions.linePaddingBottom if omitted)
    font = button text font / optional ( definitions.wFont if omitted)
}
-- ]]
function P.drawButton(button, active)
    local t = button.t
    if t == nil then
        t = ""
    end
    local bg = button.bg
    if bg == nil then
        bg = definitions.buttonColor
    end
    local linePadding = button.linePadding
    if linePadding == nil then
        linePadding = definitions.linePaddingBottom
    end

    local dcolor = button.dcolor
    if dcolor == nil then
        dcolor = definitions.disableButtonColor
    end

    local acolor = button.acolor
    if acolor == nil then
        acolor = definitions.activeButtonColor
    end

    local font = button.font
    if font == nil then
        font = definitions.wFont
    end

    local color = dcolor
    if active then
        color = acolor
    end

    drawRectangle(button.x, button.y, button.w, button.h, bg)
    sasl.gl.drawTextI(font, button.x + button.w / 2, button.y + linePadding, t, TEXT_ALIGN_CENTER, color)
end

--[[
blockText definition 
    x = blockText x origin / mandatory
    y = blockText y origin / mandatory
    w = blockText width / mandatory
    h = blockText height / mandatory
    bg = button background color / optional ( definitions.buttonColor if omitted)
    acolor = active button text color / optional ( definitions.activeButtonColor if omitted)
    dcolor = disable button text color / optional ( definitions.disableButtonColor if omitted)
    lh = blockText line height / optional ( definitions.lineHeight if omitted)
    font = blockText text font / optional ( definitions.wFont if omitted)
}
-- ]]
function P.drawBlockTexts(sBlock, sTable)

    local bg = sBlock.bg
    if bg == nil then
        bg = definitions.buttonColor
    end
    local dcolor = sBlock.dcolor
    if dcolor == nil then
        dcolor = definitions.disableButtonColor
    end

    local acolor = sBlock.acolor
    if acolor == nil then
        acolor = definitions.textColor
    end

    local font = sBlock.font
    if font == nil then
        font = definitions.wFont
    end

    local lh = sBlock.lh
    if lh == nil then
        lh = definitions.lineHeight
    end

    local y = sBlock.y
    for i = 1, #sTable, 1 do
        if string.sub(sTable[i], 1, 2) == "##" then
            -- string starting with ## if considerered as changing color tag
            -- i.e ##346578DD , the next lines will be displayed with the html color  #34657823 ( R,G,B,A ) alpha can be omitted
            acolor = htmlColorToSasl(string.sub(sTable[i], 2))
        else
            sasl.gl.drawTextI(font, sBlock.x, y, sTable[i], TEXT_ALIGN_LEFT, acolor)
            y = y - lh
        end
    end
end

--[[
window definition 
    w = window width / mandatory
    h = window height / mandatory
    wtitle = window title / mandatory
    bg = window background color / optional ( definitions.backgroundColor if omitted)
    bannerheight = banner height / optional ( definitions.bannerHeight if omitted)
    closewidth = close button width / optional ( definitions.closeXWidth if omitted)
    bannerbg = banner background color / optional ( definitions.bannerBackgroundColor
     if omitted)
    linePadding = text bottom padding / optional ( definitions.linePaddingBottom if omitted)
    font =  text font / optional ( definitions.wFont if omitted)
    fontSize = text font size / optional ( definitions.wFontSize if omitted)
}
-- ]]
function P.drawWindowTemplate(windowDefinition)

    local bg = windowDefinition.bg
    if bg == nil then
        bg = definitions.backgroundColor
    end

    local bannerbg = windowDefinition.bannerbg
    if bannerbg == nil then
        bannerbg = definitions.bannerBackgroundColor
    end

    local bcolor = windowDefinition.bannerTextColor
    if bcolor == nil then
        bcolor = definitions.bannerTextColor
    end

    local bannerheight = windowDefinition.bannerheight
    if bannerheight == nil then
        bannerheight = definitions.bannerHeight
    end

    local closewidth = windowDefinition.closewidth
    if closewidth == nil then
        closewidth = definitions.closeXWidth
    end

    local font = windowDefinition.font
    if font == nil then
        font = definitions.wFont
    end

    local fontSize = windowDefinition.fontSize
    if fontSize == nil then
        fontSize = definitions.wFontSize
    end

    local linePadding = windowDefinition.linePadding
    if linePadding == nil then
        linePadding = definitions.linePaddingBottom
    end

    drawRectangle(0, 0, windowDefinition.w, windowDefinition.h, bg)
    drawRectangle(0, windowDefinition.h - bannerheight, windowDefinition.w - closewidth, windowDefinition.w, bannerbg)

    sasl.gl.setFontSize(font, fontSize)
    sasl.gl.drawTextI(font, windowDefinition.w / 2, windowDefinition.h - bannerheight + linePadding, windowDefinition.wtitle, TEXT_ALIGN_CENTER, bcolor)

end

return windows
