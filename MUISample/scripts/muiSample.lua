muiSample = {}

function muiSample.test()
  mui.back()
end

function muiSample.init()
  mui.setTitle("Sample opened!", "This title should change automatically!")
  mui.setIcon("/interface/techupgradeicon.png")
end

function muiSample.update(dt)

end

function muiSample.settingsOpened()
  mui.setTitle("Settings opened!", "This title should change automatically!")
end

function muiSample.settingsClosed()
  mui.setTitle("Settings closed!", "This title should change automatically!")
end