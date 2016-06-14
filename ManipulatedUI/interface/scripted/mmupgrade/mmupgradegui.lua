require "/scripts/util.lua"
mmupgrade = {}

function mmupgrade.init()
  self.currentUpgrades = {}
  self.upgradeConfig = config.getParameter("upgrades")
  self.buttonStateImages = config.getParameter("buttonStateImages")
  self.overlayStateImages = config.getParameter("overlayStateImages")
  self.highlightImages = config.getParameter("highlightImages")
  self.selectionOffset = config.getParameter("selectionOffset")
  self.defaultDescription = config.getParameter("defaultDescription")
  self.autoRefreshRate = config.getParameter("autoRefreshRate")
  self.autoRefreshTimer = self.autoRefreshRate

  self.highlightPulseTimer = 0

  updateGui()
end

function mmupgrade.update(dt)
  self.autoRefreshTimer = math.max(0, self.autoRefreshTimer - dt)
  if self.autoRefreshTimer == 0 then
    updateGui()
    self.autoRefreshTimer = self.autoRefreshRate
  end

  if self.highlightImage then
    self.highlightPulseTimer = self.highlightPulseTimer + dt
    local highlightDirectives = string.format("?multiply=FFFFFF%2x", math.floor((math.cos(self.highlightPulseTimer * 8) * 0.5 + 0.5) * 255))
    widget.setImage("imgHighlight", self.highlightImage .. highlightDirectives)
  end
end

function selectUpgrade(widgetName, widgetData)
  for k, v in pairs(self.upgradeConfig) do
    if v.button == widgetName then
      self.selectedUpgrade = k
      self.highlightPulseTimer = 0
    end
  end
  updateGui()
end

function performUpgrade(widgetName, widgetData)
  if selectedUpgradeAvailable() then
    local upgrade = self.upgradeConfig[self.selectedUpgrade]
    if player.consumeItem({name = "manipulatormodule", count = upgrade.moduleCost}) then
      if upgrade.setItem then
        player.giveEssentialItem(upgrade.essentialSlot, upgrade.setItem)
      end

      if upgrade.setItemParameters then
        local item = player.essentialItem(upgrade.essentialSlot)
        util.mergeTable(item.parameters, upgrade.setItemParameters)
        player.giveEssentialItem(upgrade.essentialSlot, item)
      end

      if upgrade.setStatusProperties then
        for k, v in pairs(upgrade.setStatusProperties) do
          status.setStatusProperty(k, v)
        end
      end

      local mm = player.essentialItem("beamaxe")
      mm.parameters.upgrades = mm.parameters.upgrades or {}
      table.insert(mm.parameters.upgrades, self.selectedUpgrade)
      player.giveEssentialItem("beamaxe", mm)

      updateGui()
    end
  end
end

function updateGui()
  updateCurrentUpgrades()

  for k, v in pairs(self.upgradeConfig) do
    if self.currentUpgrades[k] then
      widget.setButtonImages(v.button, self.buttonStateImages.complete)
      widget.setButtonOverlayImage(v.button, self.overlayStateImages.complete)
    elseif hasPrereqs(v.prerequisites) then
      widget.setButtonImages(v.button, self.buttonStateImages.available)
      widget.setButtonOverlayImage(v.button, v.icon)
    else
      widget.setButtonImages(v.button, self.buttonStateImages.locked)
      widget.setButtonOverlayImage(v.button, self.overlayStateImages.locked)
    end
  end

  local playerModuleCount = player.hasCountOfItem("manipulatormodule")
  if self.selectedUpgrade then
    local upgrade = self.upgradeConfig[self.selectedUpgrade]
    widget.setVisible("imgSelection", true)
    local buttonPosition = widget.getPosition(upgrade.button)
    widget.setPosition("imgSelection", {buttonPosition[1] + self.selectionOffset[1], buttonPosition[2] + self.selectionOffset[2]})
    widget.setVisible("imgHighlight", true)
    self.highlightImage = self.highlightImages[upgrade.highlight] or ""
    widget.setText("lblUpgradeDescription", upgrade.description)
    widget.setText("lblModuleCount", string.format("%s / %s", playerModuleCount, upgrade.moduleCost))
    widget.setButtonEnabled("btnUpgrade", selectedUpgradeAvailable())
  else
    widget.setVisible("imgSelection", false)
    widget.setVisible("imgHighlight", false)
    self.highlightImage = nil
    widget.setText("lblUpgradeDescription", self.defaultDescription)
    widget.setText("lblModuleCount", string.format("%s / --", playerModuleCount))
    widget.setButtonEnabled("btnUpgrade", false)
  end
end

function updateCurrentUpgrades()
  self.currentUpgrades = {}

  local mm = player.essentialItem("beamaxe") or {}
  local currentUpgrades = mm.parameters.upgrades or {}

  for i, v in ipairs(currentUpgrades) do
    self.currentUpgrades[v] = true
  end
end

function hasPrereqs(prereqs)
  for i, v in ipairs(prereqs) do
    if not self.currentUpgrades[v] then
      return false
    end
  end

  return true
end

function selectedUpgradeAvailable()
  return self.selectedUpgrade
     and not self.currentUpgrades[self.selectedUpgrade]
     and hasPrereqs(self.upgradeConfig[self.selectedUpgrade].prerequisites)
     and (player.hasCountOfItem("manipulatormodule") >= self.upgradeConfig[self.selectedUpgrade].moduleCost)
end

function addItemParameters(slot, parameters)
  local item = player.essentialItem(slot)
  util.mergeTable(item.parameters, parameters)
  player.giveEssentialItem(slot, item)
end

function resetTools()
  player.giveEssentialItem("beamaxe", "beamaxe")
  player.removeEssentialItem("wiretool")
  player.removeEssentialItem("painttool")
  status.setStatusProperty("bonusBeamGunRadius", 0)
  updateGui()
end
