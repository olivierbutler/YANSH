-- keyboard_handler.lua

local handler

function register_handler(hdl)
	if handler then
		return false
	else
		handler = hdl
		return true
	end	
end

local function key_handler(char, vkey, shift, ctrl, alt, event)
	if handler then
		local release = handler(char, vkey, shift, ctrl, alt, event)
		if release then
			handler = false
		end
		return true
	end
	return false
end

registerGlobalKeyHandler(key_handler)

