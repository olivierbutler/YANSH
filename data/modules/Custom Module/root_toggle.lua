-- root_toogle.lua
-- defineProperty(bg, {1,1,1,1})



function draw()
    drawRectangle(0, 0, 20, 20, get(bg))
    -- drawText(fnt, 50, 25, last_char, 15, false, false, TEXT_ALIGN_CENTER, {0,0,0,1})
end

function onMouseDown(component , x, y, button , parentX , parentY)
    if button == MB_RIGHT then
    show_hide()
    end
    return true
end
