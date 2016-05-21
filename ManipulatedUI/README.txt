
=====
Manipulated UI (MUI)
 By Silverfeelin and Magicks

This work is licensed under a Creative Commons Attribution 3.0 Unported License.
https://creativecommons.org/licenses/by/3.0/
=====

There's three main steps required to add your own interface. Here both will be explained in detail.
If examples suit you better than explanations, we recommend you look at the files bundled with this mod, and other MUI interface mods. Do keep in mind the permissions for these mods, as some modders may not allow you to alter their code!

----------------
-- Load order --
----------------
Any MUI interface mod requires the ManipulatedUI mod to be loaded first. This requires an addition to your modinfo file:

"requires" : [
  "ManipulatedUI"
]

-------------------------
-- mmupgradegui.config --
-------------------------
This file contains all the GUI elements, as well as a list of callbacks and other configuration detail.
Package details are stored in this file, which allows you to add your own package through a JSON Patch.
/NEVER/ create your own mmupgradegui.config file, patch it instead!
File:
<mod>/interface/scripted/mmupgrade/mmupgradegui.config.patch
The files 'Patches for GUI.txt' and 'Patches for MUI.txt' show the patch operations required to add some controls and a package listing. Note that these patches would have to be concatenated into the patch file, and that they are just split into two files for readability.

We highly recommend using this patch tool set up by Kawa to preview the results, to avoid needless CTDs:
http://helmet.kafuka.org/sbmods/json/

----
-- Adding GUI elements for your interface
----
Nothing special here. Add your own controls to the "/gui" path. For the syntax or options, refer to interface configurations from the assets.

- MUI uses zlevels ranging from 10 to 15, which means hiding elements behind it requires values smaller than 10 and adding elements in front of it requires values bigger than 15.

- It's highly recommended to add a prefix to each of your controls, to prevent duplicate names. ManipulatedUI uses the prefix 'mui' for it's core controls.

- The position [1, 22] aligns elements with the bottom left corner of the inner body. This inner body is 335x197 in size. Although you can position elements outside of it, this can have some negative side effects.

----
-- Adding a MUI listing
----
For your interface to be activatable through the MUI main menu, you need to add your own controls. The position of these controls will be ignored, as packages are automatically aligned.
When set up properly, MUI will take care of showing and hiding elements when selecting your interface or returning to the main menu.
It is recommended to first use and adjust the existing template for package listings.

- Note: Widgets use a different format than JSON patches to identify gui elements.
The widget name for "myBtn" added to "/gui" is "myBtn".
The widget name for "myList" as part of "myScroll" added to "/gui" is "myScroll.myList"

- Below, each path used in the MUI configuration will be listed together with an explanation of what it's used for.
"/mui/base/show":
 Array of strings, each string representing a widget name to show whenever any interface is opened.
 These will be hidden when returning to the main menu.
"/mui/base/hide":
 Array of strings, each string representing a widget name to hide whenever any interface is opened.
 These will be shown when returning to the main menu.
"/mui/packages":
 Array of packages, you'll want to add your own JSON object to this array containing all the details listed below.

"<package>/activator":
 Widget name of a button that, when clicked, will open the interface of this package.
 This button, as defined in "/gui", requires the callback "mui.showInterface".

"<package>/script":
 Path to the script containing your interface logic. This will be 'require'd by MUI.

"<package>/muiControls":
 Object containing key value pairs, where each key represents a widget name that has to be present on the MUI main menu, and each value represents an offset to the automatically calculated position.
 These controls will be hidden automatically after opening any interface, and shown when returning to the main menu.

"<package>/show":
 Array of widget names that, when this interface is opened, will be shown. These widgets will be hidden when returning to the main menu.

"<package>/hide":
 Array of widget names that, when this interface is opened, will be hidden. These widgets will be shown when returning to the main menu.

---
-- Widget callbacks
 Any new callbacks have to be added to the string array "/scriptWidgetCallbacks". Callbacks referring to functions found inside "<package>/script" are supported.

------------
-- Script --
------------
The script, as defined in the mmupgrade config mui package, will be loaded on initialization.
Callback functions defined here can be used.

If you want to run a chunk of code every update, you can use the following code to inject it:
local oldUpdate = update
update = function(dt)
  oldUpdate(dt)

  --code
end

The manipulatedUI script also comes with some useful functions, you can access in your own script.
For more detailed information on these functions, view their documentation found inside the script.
mui.back() -- Return to main menu.
widget.adjustPosition(widgetName, position) -- Offset the current position of a widget.
widget.adjustPosition(map) -- Offset the current positions of multiple widgets.