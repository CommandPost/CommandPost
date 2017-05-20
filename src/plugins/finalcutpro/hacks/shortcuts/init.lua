--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                H A C K S     S H O R T C U T S     P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.shortcuts ===
---
--- Plugin that allows the user to customise the CommandPost shortcuts
--- via the Final Cut Pro Command Editor.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("shortcuts")
local inspect		= require("hs.inspect")

local fs			= require("hs.fs")

local commands		= require("cp.commands")
local config		= require("cp.config")
local dialog		= require("cp.dialog")
local fcp			= require("cp.apple.finalcutpro")
local tools			= require("cp.tools")
local prop			= require("cp.prop")

local v				= require("semver")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 		= 5
local CP_SHORTCUT   = "cpOpenCommandEditor"

local COMMANDS_FILE			= "NSProCommands.plist"
local COMMAND_GROUPS_FILE	= "NSProCommandGroups.plist"

local FCP_RESOURCES_PATH		= "/Contents/Resources/"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local private = {}

-- Returns the path to the specified resource inside FCPX, or `nil` if it cannot be found.
function private.resourcePath(resourceName)
	local fcpPath = fcp:getPath()
	if fcpPath then
		return fs.pathToAbsolute(fcpPath .. FCP_RESOURCES_PATH .. tostring(resourceName))
	else
		return nil
	end
end

-- Returns the path to the most recent version of the specified file inside the plugin, or `nil` if it can't be found.
function private.hacksPath(resourceName)
	assert(type(resourceName) == "string", "Expected argument #1 to be a string")
	if mod.commandSetsPath and fcp:isInstalled() then
		local ver = v(fcp:getVersion())
		local path = nil
		local target = string.format("%s/%s/%s", mod.commandSetsPath, ver, resourceName)
		return fs.pathToAbsolute(target)
	else
		return nil
	end
end

function private.hacksOriginalPath(resourceName)
	assert(type(resourceName) == "string", "Expected argument #1 to be a string")
	return private.hacksPath("original/"..resourceName)
end

function private.hacksModifiedPath(resourceName)
	assert(type(resourceName) == "string", "Expected argument #1 to be a string")
	return private.hacksPath("modified/"..resourceName)
end

function private.fileContentsMatch(path1, path2)
	
	-- Open the first path
	local file1 = io.open(path1, "rb")
	if err then log.wf("Unable to read file: %s", path1); return false; end

	-- Open the second path
	local file2, err = io.open(path2,"rb")
	if err then log.wf("Unable to read file: %s", path2); return false; end
	-- compare line by line

	local block = 100
	local matches = true
	
	while true do
		local bytes1 = file1:read(block)
		local bytes2 = file2:read(block)
		
		if not bytes1 then
			-- make sure file finished as well
			matches = not bytes2
			break
		elseif not bytes2 then
			-- file1 finished before file2
			matches = false
			break
		end
		
		if bytes1 ~= bytes2 then
			matches = false
			break
		end
	end

	file1:close()
	file2:close()
	
	return matches
end

-- Returns `true` if the files at the specified paths are the same.
function private.filesMatch(path1, path2)
	if path1 and path2 then
		local attr1, attr2 = fs.attributes(path1), fs.attributes(path2)
		if attr1 and attr2 and attr1.mode == attr2.mode then
			-- They are the same type and size. Now, we compare contents.
			if attr1.mode == "directory" then
				return private.directoriesMatch(path1, path2)
			elseif attr1.mode == "file" and attr1.size == attr2.size then
				return private.fileContentsMatch(path1, path2)
			end
		end
	end
	return false
end

-- Checks if all files contained in the source path match 
function private.directoriesMatch(sourcePath, targetPath)
	local sourceFiles = tools.dirFiles(sourcePath)

	for i,file in ipairs(sourceFiles) do
		if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
			local sourceFile = fs.pathToAbsolute(sourcePath .. "/" .. file)
			local targetFile = fs.pathToAbsolute(targetPath .. "/" .. file)
			
			if not sourceFile or not targetFile then -- A file is missing
				-- log.df("Missing file:\n\t%s", sourceFile or targetFile)
				return false
			end

			if not private.filesMatch(sourceFile, targetFile) then
				-- log.df("Mismatched file:\n\t%s", sourceFile)
				return false
			end
		end
	end
	
	return true
end

-- private.copyFiles(batch, sourcePath, targetPath) -> nil
-- Function
-- Adds commands to copy Hacks Shortcuts files into FCPX.
--
-- Parameters:
-- * `batch`		- The table of batch commands to be executed.
-- * `sourcePath`	- The source file.
-- * `targetPath`	- The target path.
function private.copyFiles(batch, sourcePath, targetPath)
	local copy = "cp -f '%s' '%s'"
	local mkdir = "mkdir '%s'"
	
	local sourceFiles = tools.dirFiles(sourcePath)

	for i,file in ipairs(sourceFiles) do
		if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
			local sourceFile = sourcePath .. "/" .. file
			local targetFile = targetPath .. "/" .. file
			
			local sourceAttr = fs.attributes(sourceFile)
			local targetAttr = fs.attributes(targetFile)
			
			if sourceAttr.mode == "directory" then
				if not targetAttr then
					-- The directory doesn't exist. Make it first.
					table.insert(batch, mkdir:format(targetFile))
				end
				private.copyFiles(batch, sourceFile, targetFile)
			elseif sourceAttr.mode == "file" then
				table.insert(batch, copy:format(sourceFile, targetFile))
			end
		end
	end
	
end

-- private.copyHacksFiles(batch, sourcePath) -> ni(""), private.resourcePath("")l
-- Function
-- Adds commands to copy Hacks Shortcuts files into FCPX.
--
-- Parameters:
-- * `batch`		- The table of batch commands to be executed.
-- * `sourcePath`	- A function that will return the absolute source path to copy from.
function private.copyHacksFiles(batch, sourcePath)
	
	local copy = "cp -f '%s' '%s'"
	local mkdir = "mkdir '%s'"

	table.insert(batch, copy:format( sourcePath(COMMAND_GROUPS_FILE), private.resourcePath(COMMAND_GROUPS_FILE) ) )
	table.insert(batch, copy:format( sourcePath(COMMANDS_FILE), private.resourcePath(COMMANDS_FILE) ) )

	local finalCutProLanguages = fcp:getSupportedLanguages()

	for _, whichLanguage in ipairs(finalCutProLanguages) do
		local langPath = whichLanguage .. ".lproj/"
		local whichDirectory = private.resourcePath(langPath)
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(batch, mkdir:format(whichDirectory))
		end

		table.insert(batch, copy:format(sourcePath(langPath .. "Default.commandset"), private.resourcePath(langPath .. "Default.commandset")))
		table.insert(batch, copy:format(sourcePath(langPath .. "NSProCommandDescriptions.strings"), private.resourcePath(langPath .. "NSProCommandDescriptions.strings")))
		table.insert(batch, copy:format(sourcePath(langPath .. "NSProCommandNames.strings"), private.resourcePath(langPath .. "NSProCommandNames.strings")))
	end	
end

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function private.updateHacksShortcuts(install)

	log.df("Updating Hacks Shortcuts...")

	if not mod.supported() then
		dialog.displayMessage("No supported versions of Final Cut Pro were detected.")
		return false
	end
	
	mod.working(true)

	local batch = {}

	--------------------------------------------------------------------------------
	-- Always copy the originals back into FCPX, just in case the user has
	-- previously removed them or used an old version of CommandPost or FCPX Hacks:
	--------------------------------------------------------------------------------
	
	private.copyFiles(batch, private.hacksOriginalPath(""), private.resourcePath(""))

	--------------------------------------------------------------------------------
	-- Only then do we copy the 'modified' files...
	--------------------------------------------------------------------------------
	if install then
		private.copyFiles(batch, private.hacksModifiedPath(""), private.resourcePath(""))
	end
	
	--------------------------------------------------------------------------------
	-- Execute the instructions.
	--------------------------------------------------------------------------------
	local result = tools.executeWithAdministratorPrivileges(batch, false)
	
	mod.working(false)

	mod.update()

	if result == false then
		-- Cancel button pressed:
		return false
	end

	if type(result) == "string" then
		log.ef("The following error(s) occurred: %s", result)
		return false
	end

	-- Success!
	return true

end

--------------------------------------------------------------------------------
-- UPDATE FINAL CUT PRO COMMANDS:
-- Switches to or from having CommandPost commands editible inside FCPX.
--------------------------------------------------------------------------------
function private.updateFCPXCommands(enable, silently)
	
	if enable == mod.installed() then
		return true
	end
	
	local running = fcp:isRunning()
	if not silently then
		--------------------------------------------------------------------------------
		-- Check if the user really wants to do this
		--------------------------------------------------------------------------------
		local prompt = enable and i18n("hacksEnabling") or i18n("hacksDisabling")

		if running then
			prompt = prompt .. " " .. i18n("hacksShortcutsRestart")
		else
			prompt = prompt .. " " .. i18n("hacksShortcutAdminPassword")
		end
	
		prompt = prompt .. " " .. i18n("doYouWantToContinue")
	
		if not dialog.displayYesNoQuestion(prompt) then
			return false
		end
	end

	--------------------------------------------------------------------------------
	-- Let's do it!
	--------------------------------------------------------------------------------
	if not private.updateHacksShortcuts(enable) then
		return false
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if running and not fcp:restart() then
		--------------------------------------------------------------------------------
		-- Failed to restart Final Cut Pro:
		--------------------------------------------------------------------------------
		dialog.displayErrorMessage(i18n("failedToRestart"))
	end

	return true
end

function private.applyShortcut(cmd)
	local shortcuts = fcp:getCommandShortcuts(id)
	if shortcuts ~= nil then
		cmd:setShortcuts(shortcuts)
	end
end

--------------------------------------------------------------------------------
-- APPLY SHORTCUTS:
--------------------------------------------------------------------------------
function private.applyShortcuts(commands)
	commands:deleteShortcuts()
	for id, cmd in pairs(commands:getAll()) do
		private.applyShortcut(cmd)
	end
end

--------------------------------------------------------------------------------
-- APPLY COMMAND SET SHORTCUTS:
--------------------------------------------------------------------------------
function private.applyCommandSetShortcuts()
	local commandSet = fcp:getActiveCommandSet(true)

	log.df("Applying FCPX Shortcuts to FCPX commands...")
	private.applyShortcuts(mod.fcpxCmds, commandSet)

	mod.fcpxCmds:watch({
		add		= function(cmd)	private.applyShortcut(cmd) end,
	})
	
	mod.fcpxCmds:isEditable(false)
end

--- plugins.finalcutpro.hacks.shortcuts.uninstall(silently) -> none
--- Function
--- Uninstalls the Hacks Shortcuts, if they have been installed
---
--- Parameters:
---  * `silently`	- (optional) If `true`, the user will not be prompted first.
---
--- Returns:
---  * `true` if successful.
---
--- Notes:
---  * Used by Trash Preferences menubar command.
function mod.uninstall(silently)
	return private.updateFCPXCommands(false, silently)
end

--- plugins.finalcutpro.hacks.shortcuts.install(silently) -> none
--- Function
--- Installs the Hacks Shortcuts.
---
--- Parameters:
---  * `silently`	- (optional) If `true`, the user will not be prompted first.
---
--- Returns:
---  * `true` if successful.
function mod.install(silently)
	return private.updateFCPXCommands(true, silently)
end

--- plugins.finalcutpro.hacks.shortcuts.editCommands() -> none
--- Function
--- Launch the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.editCommands()
	fcp:launch()
	fcp:commandEditor():show()
end

--- plugins.finalcutpro.hacks.shortcuts.update() -> none
--- Function
--- Read shortcut keys from the Final Cut Pro Preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	mod.installed:update()
	mod.uninstalled:update()
	mod.onboardingRequired:update()
end

--- plugins.finalcutpro.hacks.shortcuts.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps, env)
	mod.fcpxCmds	= deps.fcpxCmds

	mod.commandSetsPath = env:pathToAbsolute("/commandsets/")
	
	-- Unstall hacks if the app config is reset.
	config.watch({
		reset = function() mod.uninstall() end,
	})
	

--- plugins.finalcutpro.hacks.shortcuts.supported <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the a supported version of FCPX is installed.
	mod.supported = prop(function()
		return private.hacksModifiedPath("") ~= nil
	end)

--- plugins.finalcutpro.hacks.shortcuts.installed <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX Hacks Shortcuts are currently installed in FCPX.
	mod.installed = prop(function()
		return private.directoriesMatch(private.hacksModifiedPath(""), private.resourcePath(""))
	end)

--- plugins.finalcutpro.hacks.shortcuts.uninstalled <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX Hacks Shortcuts are currently installed in FCPX.
	mod.uninstalled = prop(function()
		return private.directoriesMatch(private.hacksOriginalPath(""), private.resourcePath(""))
	end)
	
--- plugins.finalcutpro.hacks.shortcuts.uninstalled <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if shortcuts is working on something.
	mod.working	= prop.FALSE()

--- plugins.finalcutpro.hacks.shortcuts.uninstalled <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the shortcuts are neither original or installed correctly.
	mod.outdated = mod.supported:AND(mod.working:NOT()):AND(mod.installed:NOT()):AND(mod.uninstalled:NOT())
	
--- plugins.finalcutpro.hacks.shortcuts.active <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX shortcuts are active.
	mod.active = prop.FALSE()

	-- Renders the Shortcut Editor Panel.
	local editorRenderer = env:compileTemplate("html/editor.html")

--- plugins.finalcutpro.hacks.shortcuts.requiresActivation <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the custom shortcuts are installed in FCPX but not active.
	mod.requiresActivation = mod.installed:AND(prop.NOT(mod.active)):watch(
		function(activate)
			if activate then
				private.applyCommandSetShortcuts()
				deps.shortcuts.setGroupEditor(mod.fcpxCmds:id(), editorRenderer)
				mod.active(true)
			end
		end
	)
	
--- plugins.finalcutpro.hacks.shortcuts.requiresDeactivation <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX shortcuts are active but shortcuts are not installed.
	mod.requiresDeactivation = prop.NOT(mod.installed):AND(mod.active):watch(
		function(deactivate)
			if deactivate then
				-- got to restart to reset shortcuts.
				mod.active(false)
				hs.reload()
			end
		end
	)
	
	-- Create the Setup Panel
	local setup = deps.setup
	local setupPanel = setup.panel.new("hacksShortcuts", 50)
		:addIcon(env:pathToAbsolute("images/fcp_icon.png"))
		:addParagraph(i18n("commandSetText"), true)
		:addButton({
			label		= i18n("commandSetUseFCPX"),
			onclick		= function()
				mod.install()
				mod.onboardingRequired(false)
				setup.nextPanel()
			end,
		})
		:addButton({
			label		= i18n("commandSetUseCP"),
			onclick		= function()
				mod.uninstall()
				mod.onboardingRequired(false)
				setup.nextPanel()
			end,
		})
	
--- plugins.finalcutpro.hacks.shortcuts.onboardingRequired <cp.prop: boolean>
--- Constant
--- If `true`, the initial setup has been completed.
	mod.onboardingRequired	= config.prop("hacksShortcutsOnboardingRequired", true)
	
--- plugins.finalcutpro.hacks.shortcuts.setupRequired <cp.prop: boolean; read-only>
--- Constant
--- If `true`, the user needs to configure Hacks Shortcuts.
	mod.setupRequired	= mod.supported:AND(mod.onboardingRequired:OR(mod.outdated)):watch(function(required)
		if required then
			setup.addPanel(setupPanel).show()
		end
	end, true)

	mod.update()
	
	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hacks.shortcuts",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.top"] 									= "top",
		["finalcutpro.commands"]							= "fcpxCmds",
		["finalcutpro.preferences.app"]						= "prefs",
		["core.setup"] 										= "setup",
		["core.preferences.panels.shortcuts"]				= "shortcuts",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Add the menu item to the top section:
	--------------------------------------------------------------------------------
	deps.top:addItem(PRIORITY, function()
		if fcp:isInstalled()  then
			return { title = i18n("openCommandEditor"), fn = mod.editCommands, disabled = not fcp:isRunning() }
		end
	end)

	--------------------------------------------------------------------------------
	-- Add Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpOpenCommandEditor")
		:titled(i18n("openCommandEditor"))
		:whenActivated(mod.editCommands)

	--------------------------------------------------------------------------------
	-- Add Preferences:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel:addHeading(50, i18n("keyboardShortcuts"))

		:addCheckbox(51,
			{
				label		= i18n("enableHacksShortcuts"),
				onchange	= function(_,params)
					if params.checked then
						mod.install()
					else
						mod.uninstall()
					end
				end,
				checked=function() return mod.active() end
			}
		)
	end
	
	return mod.init(deps, env)
end

function plugin.disable()
	return mod.uninstall()
end

return plugin