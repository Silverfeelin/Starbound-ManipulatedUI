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
function update(dt)
	if mui.active ~= '' then
		if _ENV[mui.active] then
			if type(_ENV[mui.active].update) == "function" then
				_ENV[mui.active].update(dt)
			end
		end
	end

end
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

