# Manipulated UI (MUI)
Manipulated UI is a mod that allows compatible mods to be shown and used in the Matter Manipulator Upgrade window. The mod is not meant to be used on it's own, as it will offer no content in-game unless interface mods are installed that utilized Manipulated UI.


## Table of Contents
- [Adding Interfaces](#adding-interfaces)
 - [Load order](#load-order)
 - [Configuration patch](#configuration-patch)
 - [Main menu listing](#main-menu-listing)
 - [Interface widgets](#interface-widgets)
 - [Package configuration](#package-configuration)
 - [Widget callbacks](#widget-callbacks)
 - [Script](#script)
 - [Additional script functions](#additional-script-functions)

## Adding Interfaces

### Load order
Any MUI interface mod requires the Manipulated UI mod to be loaded first. This requires an addition to your modinfo file:

```javascript
"requires" : [
  "Manipulated UI"
]
```

### Configuration patch
The `mmupgradegui.config`, located in `/interface/scripted/mmupgrade/`, contains both gui data and package data used to define and identify your interface's configuration.
To add your own interface, you must patch this file by creating a new file in your mod: `/interface/scripted/mmupgrade/mmupgradegui.config.patch`. It is recommended to take a look at [Kawa's Starbound JSON Lab](http://helmet.kafuka.org/sbmods/json/) if you're unfamiliar with the JSON patch format.

#### Main menu listing
For your interface to be activatable through the MUI main menu, you need to add your own button. The position of this button will be ignored, as packages are automatically aligned depending on the amount of installed packages.
This button requires two additional parameters:
* "data" : "tableName" // The name of your script's Lua table. This should match the `name` parameter in your package configuration. This value is used to identify which interface should be loaded when this button is pressed.
* "callback" : "showInterface" // This callback function will tell MUI to load the interface bound to this button by reading the `data` parameter.

It is recommended to first use and adjust the existing template for package listings. The below sample shows a patch operation that adds a button labelled 'Open Sample Interface' to the main menu of MUI.
```javascript
{
  "op" : "add",
  "path" : "/gui/btnMUISample",
  "value" : {
    "type" : "button",
    "base" : "/resources/UIActivator.png",
    "hover" : "/resources/UIActivator.png?brightness=60",
    "caption" : "Open Sample\n Interface",
    "fontSize" : 7,
    "wrapWidth" : 80,
    "hAnchor" : "mid",
    "pressedOffset" : [0, -1],
    "position" : [102, 103],

    "data" : "muiSample",
    "callback" : "showInterface"
  }
}
```

#### Interface widgets
Nothing special here. Simply add your own GUI elements to the config (`"/gui/<elementName>"`). Every control should either be hidden by default (`"visible" : false`) or added to the package configuration described further down below.

* If your GUI widgets do not show up, they might be hidden behind other widgets. Adjust the `zlevel` parameter accordingly.
* It's highly recommended to add a prefix to each of your controls, to prevent duplicate names. This is especially important to prevent issues when users install multiple MUI-compatible interface mods.
* The position `[1, 22]` aligns elements with the bottom left corner of the inner (gray) body. This inner body is `335x197` in size. Although you can position elements outside of it, it is recommended to place your widgets inside of this area.

An example of a patch operation for an image widget can be viewed below.
```javascript
{
  "op": "add",
  "path": "/gui/sampleImg",
  "value": {
    "type" : "image",
    "zlevel" : 13,
    "visible" : false,
    "file" : "/interface/scripted/mmupgrade/modules.png",
    "position" : [103, 82]
  }
}
```

#### Package configuration
MUI has to know what elements you wish to show and hide when opening or closing your interface, and what table name contains the init, update and uninit functions for your interface.
This data is stored in the package table, which mean you'll need to add a new entry for your interface:
```javascript
{
  "op": "add",
  "path": "/packages/-",
  "value": {
		"activator" : "btnMUISample", // The button name used to show this interface, see chapter 'Main Menu Listing'.
		"show" : [ "SampleLblTest","SampleBtnTest","SampleImgTest" ], // An array of widget names to show when this interface is opened. These widgets will automatically be hidden when the interface is closed.
		"hide" : [], // An array of widet names to hide when this interface is opened. These widgets will automatically be shown when the interface is closed.
		"update" : { "bgb" : "/interface/scripted/mmupgrade/body.png" }, // Object with keys representing widget names of images and values representing the new image to apply when this interface is opened. This can, for example, be used to change the MUI background body ('bgb').
		"settingsEnabled": true, // Value indicating whether to enable (true) or disable (false) the settings menu for this interface, accessed by pressing the cog while the interface is open.
		"settingControls" : [], // An array of widget names to show when the settings menu is opened while this interface is open. This will hide the interface widgets as defined in 'show', until the settings menu is closed again.
		"name" : "muiSample", // The name of of the script's table, which should also match the 'data' parameter on the main menu listing button (see chapter Main Menu Listing).
		"script" : "/scripts/muiSample.lua" // Script loaded when this interface is opened. It should contain a table <name>, optionally containing the functions <name>.init(), <name>.update(dt) and <name>.uninit().
	}
}
```
When set up properly, MUI will take care of showing and hiding elements when selecting your interface or returning to the main menu.

#### Widget callbacks
 Any new callbacks have to be added to the string array "/scriptWidgetCallbacks". Callbacks referring to functions found inside your script are supported, as long as the script parameter of the package is valid.
 An example of a patch operation that adds a callback for the function `muiSample.test` can be viewed below.
```javascript
{
  "op": "add",
  "path": "/scriptWidgetCallbacks/-",
  "value": "muiSample.test"
}
```

### Script
The script, as defined in the package configuration, will be loaded on initialization. It is expected that this script contains a table using the same name as the data parameter of the main menu button, as well as the package name parameter.
If the functions `init()`, `update(dt)` and/or `uninit` are defined, they will be called by MUI when opening the interface, while the interface is opened or when closing the interface respectively.
If the functions `settingsOpened()` and `settingsClosed()` are defined, they will be called by MUI when opening or closing the settings menu. This only applies to the interface that's currently opened.
Callback functions defined in this script can be used in widgets, as long as they are added to `/scriptWidgetCallbacks`.

#### Additional script functions
* `mui.back()`  
Returns the user to the main menu. This will uninitialize your interface.
* `mui.setTitle(title, subtitle)`  
Sets the title and subtitle of the window. This will revert when closing your interface.
* `mui.setIcon(path)`  
Sets the top left icon of the window. The icon used should be 24x24 pixels. This will revert when closing your interface. 
