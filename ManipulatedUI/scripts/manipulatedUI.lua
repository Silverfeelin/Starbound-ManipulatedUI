--[[
  ManipulatedUI
  By Silverfeelin and Magicks

  For usage instructions, please refer to the included README.txt file.

  This work is licensed under a Creative Commons Attribution 3.0 Unported License.
  https://creativecommons.org/licenses/by/3.0/
]]

require "/scripts/vec2.lua"

---
-- Widget extension methods.

--[[
 Offsets the current position of a widget by a given point.
 @param widgetName - Widget name of the control to move.
 @param position - {x,y}, defining the offsets to apply to the widget's current position.
]]
function widget.adjustPosition(widgetName,position)
  widget.setPosition(widgetName,vec2.add(widget.getPosition(widgetName),position))
end

--[[
  Offsets the current position of each widget (key) by it's corresponding point.
  See widget.adjustPosition.
  @param map - Table with keys representing the widget name and values representing the offset.
    { ["myBtn"] = {10,10}, ["anotherBtn"] = {20,-10} }
]]
function widget.adjustPositions(map)
  for widgetName,position in pairs(map) do
    widget.adjustPosition(widgetName,position)
  end
end

mui = {}

--[[
 Initialize function, called at the end of this script.
 Obtains configuration details and positions main menu package controls.
 warns user which packages aren't being loaded if over 10 are present.
]]
function mui.init()
  mui.config = config.getParameter("mui")
  local offset = {1,14}
  local size = {335,197}
  mui.packages = config.getParameter("mui").packages

  while #mui.packages > 10 do
    table.remove(mui.packages, #mui.packages)
    sb.logInfo("MUI: Package %s has not been loaded. Over ten package are (currently) not supported.")
  end

  local offsets = mui.getGridOffsets(#mui.packages, 12)

  local i = 1
  for _,p in pairs(mui.packages) do

    if p.script and p.script ~= "" then require (p.script) end

    for key,v in pairs(p.muiControls) do
      widget.setPosition(key, offsets[i])
      widget.adjustPosition(key, v)
    end
    i = i + 1
  end

  mui.showInterface()
end

--[[
  Button callback function that brings the user back to the main menu.
]]
function mui.back()
  sb.logInfo("MUI: Returning to main menu!")
  mui.showInterface()
end

--[[
 Button callback function that shows the interface bound to the pressed button.
 Can be used to return to the main menu by not passing any arguments.
 @param [btn] - Widget name of the button.
]]
function mui.showInterface(btn)
  local returning = type(btn) ~= "string"

  -- Show or hide base controls
  for _,k in pairs(mui.config.base.show) do
    widget.setVisible(k, not returning)
  end
  for _,k in pairs(mui.config.base.hide) do
    widget.setVisible(k, returning)
  end

  for k,p in pairs(mui.config.packages) do
    -- Show or hide main menu controls
    for a,_ in pairs(p.muiControls) do
      widget.setVisible(a, returning) 
    end

    -- Show or hide this package
    local makeVisible = p.activator == btn
    for _,b in pairs(p.show) do
      widget.setVisible(b, makeVisible) 
    end
    for _,b in pairs(p.hide) do
      widget.setVisible(b, not makeVisible)
    end
  end
end

--[[
 Generates and returns a list of offsets to position n packages on the main menu.
 Packages will be evenly distributed using the default button size (130x36).
 Placing packages in the same row is prioritized over adding new rows. One row fits up to two packages.
 For an uneven amount of packages, the last one will be centered.
 @param n - Amount of packages to calculate offsets for.
 @param padding - Horizontal distance between the center and the side of the package for rows with two packages.
 @return - Table sized n containing offset points for every package.
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

mui.init()