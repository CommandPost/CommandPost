local fcp			= require("hs.finalcutpro")
local settings		= require("hs.settings")
local dialog		= require("hs.fcpxhacks.modules.dialog")

local PRIORITY = 1000

--------------------------------------------------------------------------------
-- DISPLAY A LIST OF ALL SHORTCUTS:
--------------------------------------------------------------------------------
local function displayShortcutList()

	local whatMessage = [[The default FCPX Hacks Shortcut Keys are:

---------------------------------
CONTROL+OPTION+COMMAND:
---------------------------------
L = Launch Final Cut Pro (System Wide)

A = Toggle HUD
Z = Toggle Touch Bar

W = Toggle Scrolling Timeline

H = Highlight Browser Playhead
F = Reveal in Browser & Highlight
S = Single Match Frame & Highlight

D = Reveal Multicam in Browser & Highlight
G = Reveal Multicam in Angle Editor & Highlight

E = Batch Export from Browser

B = Change Backup Interval

T = Toggle Timecode Overlays
Y = Toggle Moving Markers
P = Toggle Rendering During Playback

M = Select Color Board Puck 1
, = Select Color Board Puck 2
. = Select Color Board Puck 3
/ = Select Color Board Puck 4

1-9 = Restore Keyword Preset

+ = Increase Timeline Clip Height
- = Decrease Timeline Clip Height

Left Arrow = Select All Clips to Left
Right Arrow = Select All Clips to Right

-----------------------------------------
CONTROL+OPTION+COMMAND+SHIFT:
-----------------------------------------
1-9 = Save Keyword Preset

-----------------------------------------
CONTROL+SHIFT:
-----------------------------------------
1-5 = Apply Effect]]

	dialog.displayMessage(whatMessage)
end

local function createMenuItem()
	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local hacksInFcpx = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false
	
	if not hacksInFcpx then
		return { title = i18n("displayKeyboardShortcuts"), fn = displayShortcutList }
	else
		return nil
	end
end

local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.top"] = "top"
}

function plugin.init(deps)
	local top = deps.top
	
	top:addItem(PRIORITY, createMenuItem)
	
	return module
end

return plugin