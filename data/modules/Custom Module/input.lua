-- input.lua
defineProperty(bg, {1,1,1,1})

local fnt =  sasl.gl.loadFont(getXPlanePath() .. "Resources/fonts/DejaVuSansMono.ttf")
local last_char = " "

function draw()
	drawRectangle(0, 0, 100, 100, get(bg))
	drawText(fnt, 50, 25, last_char, 15, false, false, TEXT_ALIGN_CENTER, {0,0,0,1})
end

local function process_key(char, vkey, shift, ctrl, alt, event)
	if event == KB_DOWN_EVENT then
		if char == SASL_KEY_ESCAPE or char == SASL_KEY_RETURN then
			last_char = " "
			return true
		end
		last_char = last_char..string.char(char)
	end
	return false
end

function onMouseDown() register_handler(process_key) return true end

function update()
  
	-- If any value changes that affects either drawing or perhaps one of the interactive functions, you must
	-- get and evaluate it each flight loop in order to remain current with the state of the simulation.
	-- There are lots of ways to write this sort of thing.  The important thing is to write it in a way that
	-- you can easily understand later.  (Don't forget comments)
	
  end