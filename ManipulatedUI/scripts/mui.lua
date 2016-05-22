require'/scripts/vec2.lua'
require'/scripts/util.lua'
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
	Allocates/decides which packages to load. Packages with the value mustLoad are considered first.
	The ones loaded can be selected from the settings menu later.
]]
function mui.allocate(packageList)
	packageList = copy(packageList)
	list = {}
	if #packageList <= 10 then return packageList end
	for i,data in ipairs(packageList) do
			if data.mustLoad and #list < 10 then
				table.insert(list,data)
				list[i].loaded = true
			end
	end
	packageList = util.filter(packageList, function(a) if contains(list,a) then return false end return true end )
	if #list < 10 then
		for i,data in ipairs(packageList) do
			if #list < 10 then
				data.loaded = true
				table.insert(list,data)
			end
		end
	end
	return list

end

--[[
 	Initialize function, called by the game's engine when MUI is opened (after this script is loaded).
 	Obtains configuration details and positions main menu package controls.
]]
function init()
	mui.packages = config.getParameter('packages')
	mui.settings = config.getParameter('settings.configuration') 
	mui.defaults = config.getParameter('settings.defaults') 

	mui.loaded = mui.allocate(mui.packages)

	local grid = mui.getGridOffsets(#mui.packages,12)
	for i,data in ipairs(mui.loaded) do
		widget.setPosition(data.activator,grid[i])
		if data.script then require(data.script) end
	end
	require(mui.settings.script)
	showInterface()

end

--[[
 Update function, called by the game's engine every tick while MUI is open.
 Runs the update function of the currently opened interface, if this function exists.
]]
function update(dt)
  if mui.active ~= '' then
    local pkg = _ENV[mui.active]
    if type(pkg) == "table" and type(pkg.update) == "function" then pkg.update(dt) end
  end
end

--[[
  Uninitialize function, called by the game's engine when MUI is closed.
  Runs the uninitialize function of the currently opened interface, if this function exists.
]]
function uninit()
  if mui.active ~= '' then
    local pkg = _ENV[mui.active]
    if type(pkg) == "table" and type(pkg.uninit) == "function" then pkg.uninit() end
  end
end

--[[
  Hides the opened interface (if any), and shows the MUI main menu.
]]
function mui.back()
  showInterface()
end

--[[
  Sets the interface icon to the given path.
  This change is undone when going back to the main menu.
  @param path - String value representing the asset path to the image.
]]
function mui.setIcon(path)
  widget.setImage("imgTitleIcon", path)
end

--[[
  Sets the interface title text.
  This change is undone when going back to the main menu.
  @parm [title] - Window title, only set when a non-nil value is given.
  @param [subtitle] - Window subtitle, only set when a non-nil value is given.
]]
function mui.setTitle(title, subtitle)
  if title then widget.setText("lblTitle", title) end
  if subtitle then widget.setText("lblSubtitle", "^gray;" .. subtitle) end
end

--[[
 Button callback function that shows the interface bound to the pressed button.
 Can be used to return to the main menu by not passing any arguments.
 @param [widgetName] - Widget name of the button.
 @param [widgetData] - Widget data, which should be the table name as defined in the package.
]]
function showInterface(widgetName,widgetData)
  -- Uninitialize previous package.
  if mui.active ~= '' and _ENV[mui.active] and _ENV[mui.active].uninit then _ENV[mui.active].uninit() end
  
  mui.active = widgetData or ''
  if mui.active ~= '' and mui.active ~= 'muisettings' then
    for i,data in ipairs(mui.loaded) do
    	 widget.setVisible(data.activator,false)
      if data.name ~= mui.active then
        for i,wid in ipairs(data.show) do widget.setVisible(wid,false) end	
      elseif data.name == mui.active then
        for i,wid in ipairs(data.show) do widget.setVisible(wid,true) end
        for i,wid in ipairs(data.hide) do widget.setVisible(wid,false) end
        for name,image in pairs(data.update) do
          widget.setImage(name,image)			
        end
      end	
    end
    
    local pkg = _ENV[mui.active]
    if type(pkg) == "table" and type(pkg.init) == "function" then
      pkg.init()
    end
  elseif mui.active == 'muisettings' then
  	for i,data in ipairs(mui.loaded) do
    	 widget.setVisible(data.activator,false)
       for i,wid in ipairs(data.show) do widget.setVisible(wid,false) end	
    end
    for i,wid in ipairs(mui.settings.show) do widget.setVisible(wid,true) end
    for i,wid in ipairs(mui.settings.hide) do widget.setVisible(wid,false) end
    for name,image in pairs(mui.settings.update) do
      widget.setImage(name,image)	
    end		
    local pkg = _ENV[mui.active]
    if type(pkg) == "table" and type(pkg.init) == "function" then
      pkg.init()
    end
  elseif mui.active == '' then
    mui.setTitle("Manipulated UI", "Manipulates more than the matter manipulator.")
    mui.setIcon("/interface/manipulatorupgradeicon.png")

    for i,data in ipairs(mui.packages) do
      for i,wid in ipairs(data.show) do widget.setVisible(wid,false) end	
    end
    for i,wid in ipairs(mui.settings.show) do widget.setVisible(wid,false) end	
    for wid,image in pairs(mui.defaults) do 
      widget.setVisible(wid,true)
      widget.setImage(wid,image) 
    end
    for i,data in ipairs(mui.loaded) do widget.setVisible(data.activator,true) end
  end
end
function showSettings(widgetName,widgetData)
	showInterface(nil,"muisettings")
end


