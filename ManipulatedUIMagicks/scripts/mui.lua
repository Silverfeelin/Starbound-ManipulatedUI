require'/scripts/vec2.lua'
mui = { packages = { }, active = '' }

function mui.getGridOffsets(n, padding)
  local offset = {102,103}
  if n == 1 then
    return {offset}
  else
    local grid = {}
    local top = 183
    local re = math.floor(n/2)
    local r = n % 2
    local m = (197 - (re+r) * 36) / (re+r+1)

    -- Even
    for i = 1,re do
      local y = top - m * i - 36 * (i - 1)
      table.insert(grid,vec2.add(offset,{-65 - padding, 0}))
      grid[#grid][2] = y
      table.insert(grid,vec2.add(offset,{65 + padding, 0}))
      grid[#grid][2] = y
    end

    -- Uneven
    if r == 1 then
      table.insert(grid, offset)
      grid[#grid][2] = top - m * (re+1) - 36 * re
    end

    return grid
  end
end

--[[
 Initialize function, called by the game's engine when MUI is opened (after this script is loaded).
 Obtains configuration details and positions main menu package controls.
]]
function init()
	mui.packages = config.getParameter'packages'
	mui.defaults = config.getParameter'defaults' 
	local grid = mui.getGridOffsets(#mui.packages,12)
	for i,data in ipairs(mui.packages) do
		widget.setPosition(data.activator,grid[i])
		if data.script then require(data.script) end
	end
	showInterface()

end

--[[
 Update function, called by the game's engine every tick while MUI is open.
 Runs the update function of the currently opened interface, if this function exists.
]]
function update(dt)
	if mui.active ~= '' then
		if _ENV[mui.active] then
			if type(_ENV[mui.active].update) == "function" then
				_ENV[mui.active].update(dt)
			end
		end
	end

end

--[[
  Hides the opened interface (if any), and shows the MUI main menu.
]]
function mui.back()
  showInterface()
end

--[[
 Button callback function that shows the interface bound to the pressed button.
 Can be used to return to the main menu by not passing any arguments.
 @param [widgetName] - Widget name of the button.
 @param [widgetData] - Widget data, which should be the table name as defined in the package.
]]
function showInterface(widgetName,widgetData)
	mui.active = widgetData or ''
	if mui.active ~= '' then
		for i,data in ipairs(mui.packages) do
			if data.name ~= mui.active then
				widget.setVisible(data.activator,false)
				for i,wid in ipairs(data.show) do widget.setVisible(wid,false) end	
			elseif data.name == mui.active then
				widget.setVisible(data.activator,false)
				for i,wid in ipairs(data.show) do widget.setVisible(wid,true) end
				for i,wid in ipairs(data.hide) do widget.setVisible(wid,false) end
				for name,image in pairs(data.update) do
					widget.setImage(name,image)			
				end
			end	
		end
		if _ENV[mui.active] then
			if type(_ENV[mui.active].init) == "function" then
				_ENV[mui.active].init()
			end
		end
	elseif mui.active == '' then
		for i,data in ipairs(mui.packages) do
			for i,wid in ipairs(data.show) do widget.setVisible(wid,false) end	
		end
		for wid,image in pairs(mui.defaults) do 
			widget.setVisible(wid,true)
			widget.setImage(wid,image) 
		end
		for i,data in ipairs(mui.packages) do widget.setVisible(data.activator,true) end
	end
end

