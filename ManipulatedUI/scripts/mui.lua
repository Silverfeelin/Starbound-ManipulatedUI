require'/scripts/vec2.lua'
require'/scripts/util.lua'

mui = { packages = { }, active = '' }

--[[                            ]]--
--[[ Starbound Engine Callbacks ]]--
--[[                            ]]--

--[[
 	Initialize function, called by the game's engine when MUI is opened (after this script is loaded).
 	Obtains configuration details and positions main menu package controls.
]]
function init()
	mui.packages = config.getParameter('packages')
	mui.defaults = config.getParameter('settings.defaults')
  mui.settings = config.getParameter('settings.configuration')
  mui.maxPerPage = config.getParameter('settings.maxPerPage')
  mui.showingSettings = false
  -- Fix packages by allocating missing properties.
  for i,data in ipairs(mui.packages) do
    if not data.show then data.show = {} end
    if not data.hide then data.hide = {} end
    if not data.update then data.update = {} end
    if not data.priority then data.priority = 0 end
    if not data.settingControls then data.settingControls = {} end
  end

  mui.sortPackages(mui.packages)

  --Adds packages to partitions.
  mui.page = 1
  mui.maxPages = math.ceil(#mui.packages/mui.maxPerPage)
  mui.pages = mui:getPages(mui.maxPerPage)
	mui.loaded = mui.pages[mui.page]

	local grid = mui.getGridOffsets(#mui.loaded,12)
	for i,data in ipairs(mui.loaded) do
		widget.setPosition(data.activator,grid[i])
		if data.script then require(data.script) end
    if _ENV[data.name].settingsEnabled == nil then _ENV[data.name].settingsEnabled = data.settingsEnabled end
	end

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

--[[               ]]--
--[[ MUI Callbacks ]]--
--[[               ]]--

--[[
  Button callback function that shows the interface bound to the pressed button.
  Can be used to return to the main menu by not passing any arguments.
  @param [widgetName] - Widget name of the button.
  @param [widgetData] - Widget data, which should be the table name as defined in the package.
]]
function showInterface(widgetName,widgetData)
  -- Uninitialize previous package.
  mui.uninitInterface()

  mui.active = widgetData

  -- Show or hide activator (main menu) widgets.
  local show = mui.isInterfaceOpen()

  mui.showMainMenuWidgets(not show)
  mui.showInterfaceControls(mui.active)

  if show then
    local pkg = _ENV[mui.active]
    if type(pkg) == "table" and type(pkg.init) == "function" then
      pkg.init()
    end
  else
    -- Restore main menu / defaults
    mui.setTitle("Manipulated UI", "Manipulates more than the matter manipulator.")
    mui.setIcon("/interface/manipulatorupgradeicon.png")
    widget.setVisible("btnSettings", true)
    widget.setVisible("btnBack", true)
    widget.setVisible("close", true)

    for wid,image in pairs(mui.defaults) do
      widget.setVisible(wid,true)
      widget.setImage(wid,image)
    end

    for i,data in ipairs(mui.loaded) do widget.setVisible(data.activator,true) end
  end
end

--[[
  Button callback function to toggle between displaying the settings of the opened interface and the opened interface.
  Hides other widgets.
  @param [widgetName] - Widget name passed by the callback. Not used.
  @param [widgetData] - Widget data passed by the callback. Not used.
]]
function showSettings(widgetName,widgetData)
  mui.showingSettings = not mui.showingSettings

  if mui.active and _ENV[mui.active] and _ENV[mui.active].settingsEnabled ~= true then return end

  if mui.showingSettings then
    mui.showInterfaceControls("")
    mui.showSettingControls(mui.active)

    if mui.active then
      local pkg = _ENV[mui.active]
      if pkg and type(pkg.settingsOpened) == "function" then
        pkg.settingsOpened()
      end
    end
  else
    if mui.isInterfaceOpen() then
      mui.showInterfaceControls(mui.active)
      local pkg = _ENV[mui.active]
      if pkg and type(pkg.settingsClosed) == "function" then
        pkg.settingsClosed()
      end
    else
      showInterface()
    end
  end
end
--[[
  Button callback function to cycle through pages,
  will ensure that the new loaded packages are initialized.
  @param [widgetName] - Widget name passed by the callback. Not used.
  @param [widgetData] - is the page shift amount, it should be 1 or -1.

]]

function shiftPage(widgetName,widgetData)
  widgetData = type(widgetData) == "number" and widgetData or 0
  if widgetData == 0 then return end

  if not mui.isInterfaceOpen() then
    mui.showMainMenuWidgets(false)
    mui.page = util.wrap(mui.page+widgetData,1,#mui.pages)
    mui.loaded = mui.pages[mui.page]

    local grid = mui.getGridOffsets(#mui.loaded,12)
  	for i,data in ipairs(mui.loaded) do
  		widget.setPosition(data.activator,grid[i])
  		if data.script then require(data.script) end
      if _ENV[data.name].settingsEnabled == nil then _ENV[data.name].settingsEnabled = data.settingsEnabled end
  	end
    showInterface()
  end
end

--[[         ]]--
--[[ MUI API ]]--
--[[         ]]--

--[[
  For n amount of packages, calculate the position needed to place activators at.
  This assumes the default activator dimensions are used (130x36).
  @param n - Amount of packages. Should not exceed 10.
  @param padding - Amount of vertical space surrounding each activator. This means
  the distance of two activators will be padding * 2.
]]
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
  Returns a value indicating whether an interface is currently opened or not.
]]
function mui.isInterfaceOpen()
  return type(mui.active) == "string" and mui.active ~= '' and true or false
end

--[[
  Uninitializes the currently opened interface.
  Does not show or hide widgets.
]]
function mui.uninitInterface()
  mui.showingSettings = false
  if mui.isInterfaceOpen() then
    local pkg = _ENV[mui.active]
    if pkg and pkg.uninit then
      _ENV[mui.active].uninit()
    end
  end
end

--[[
  Shows or hide activator widgets (main menu interface buttons), depending on the given value.
  @param bool - Value indicating whether to show (true) or hide (false) the activator (main menu) widgets.
]]
function mui.showMainMenuWidgets(bool)
  local unloaded = copy(mui.pages)
  unloaded[mui.page] = nil
  for i,data in ipairs(mui.loaded) do
     widget.setVisible(data.activator, bool)
  end
  util.each(unloaded,function(k,v)
    for i,data in ipairs(v) do
       widget.setVisible(data.activator, false)
    end
  end)
  if #mui.pages > 1 then
    widget.setVisible('btnPageFwd',bool)
    widget.setVisible('btnPageBack',bool)
  else
    widget.setVisible('btnPageFwd',false)
    widget.setVisible('btnPageBack',false)
  end

end

--[[
  Shows the widgets of the given package, and hides widgets of other packages.
  The opposite is done for each package.hide table. All setting controls are hidden,
  and images in package.update are applied for the given package.
  @param pkg - Name of the package to show.
]]
function mui.showInterfaceControls(pkg)
  for i,data in ipairs(mui.packages) do
    local show = data.name == pkg

    for j,wid in ipairs(data.show) do widget.setVisible(wid, show) end
    for j,wid in ipairs(data.hide) do widget.setVisible(wid, not show) end
    for j,wid in ipairs(data.settingControls) do widget.setVisible(wid, false) end
    for j,wid in ipairs(mui.settings.show) do widget.setVisible(wid, false) end
    if show then
      for name,image in pairs(data.update) do
        widget.setImage(name,image)
      end
    end
  end
end

--[[
  Shows the setting widgets of the given package.
  If no package is given, the main (MUI) settings are shown instead.
  @param pkg - Package to show setting controls for. Nil or false will show the main (MUI) settings.
]]
function mui.showSettingControls(pkg)
  if not pkg then
		--[[ Currently disabled: main menu settings.
    mui.showMainMenuWidgets(false)
    for i,wid in ipairs(mui.settings.show) do widget.setVisible(wid, true) end
    for i,wid in ipairs(mui.settings.hide) do widget.setVisible(wid, false) end
		]]
  else
    -- Locate package, and load all relative setting controls.
    for i,pkg in pairs(mui.loaded) do
      if pkg.name == mui.active then
        for j,wid in ipairs(pkg.settingControls) do
          widget.setVisible(wid, true)
        end
        return
      end
    end
  end
end

--[[
  Allocates packages to partitions of size n.
  @param n - Number of packages per page.
]]
function mui:getPages(n)
  local new = {}
  for i=1,self.maxPages do
    new[i] = {}
    for j = 1,n do
      local pkgIndex = (i-1)*n + j
      new[i][j] = self.packages[pkgIndex]
    end
  end
  return new
end

--[[
  Sorts the given collection of packages. The given table is directly altered.
  Sorts by priority (lowest number first). Values with the same priority are sorted by name.
  @param pkgs - Array of MUI packages
  @return - Sorted collection. Return value can be ignored, as the source collection is sorted.
  @see mui.packages
]]
function mui.sortPackages(pkgs)
  table.sort(mui.packages, function(i,j)
    if i.priority ~= j.priority then
      return i.priority < j.priority
    end
    return i.name:lower() < j.name:lower()
  end)
end

--[[
  Gets the player's entity id; pane.sourceEntity() is broken.
  Returns the non-unique entity id for the player.
]]

function mui.playerId()
	local uid =  player.ownShipWorldId():match":(.+)"
	local pos =  world.findUniqueEntity(uid):result()
  if pos then
	  local id = world.entityQuery(pos,3,{order = "nearest",includedTypes = {"player"}})[1]
	  return id
  end
end
