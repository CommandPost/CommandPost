--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              P L U G I N     L O A D E R     L I B R A R Y                 --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by David Peterson (https://github.com/randomeizer).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local settings						= require("hs.settings")
local fs							= require("hs.fs")

local log							= require("hs.logger").new("plugins")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local mod = {}

mod.CACHE = {}

mod.SETTINGS_DISABLED = "fcpxHacks.plugins.disabled"

--- hs.fcpxhacks.modules.plugins.loadPackage(package) -> boolean
--- Function
--- Loads any plugins present in the specified package. 
--- Any `*.lua` file, or folder containing an `init.lua` file will automatically be
--- loaded as a plugin.
---
--- Eg:
---
--- ```
--- plugins.loadPlugins("hs.fcpxhacks.plugins")
--- ```
---
--- Parameters:
---  * package - The LUA package to look in
---
--- Returns:
---  * boolean - `true` if all plugins loaded successfully
---
function mod.loadPackage(package)
	local path = fs.pathToAbsolute("~/.hammerspoon/" .. package:gsub("%.", "/"))
	if not path then
		log.ef("The provided path does not exist: '%s'", package)
		return false
	end
	
	local attrs = fs.attributes(path)
	if not attrs or attrs.mode ~= "directory" then
		log.ef("The provided path is not a directory: '%s'", package)
		return false
	end
	
	local contents, data = fs.dir(path)
	for file in function() return contents(data) end do
		if file ~= "." and file ~= ".." then
			local filePath = path .. "/" .. file
			if fs.attributes(filePath).mode == "directory" then
				local attrs, err = fs.attributes(filePath .. "/init.lua")
				if attrs and attrs.mode == "file" then
					-- it's a plugin
					mod.loadPlugin(package .. "." .. file)
				else
					-- it's a plain folder. Load it as a sub-package.
					mod.loadPackage(package .. "." .. file)
				end
			else
				local name = file:match("(.+)%.lua$")
				if name then
					mod.loadPlugin(package .. "." .. name)
				end
			end
		end
	end
	
	return true
end

--- hs.fcpxhacks.modules.plugins.loadPackage(package) -> boolean
--- Function
--- Loads any plugins present in the specified package. 
--- Any `*.lua` file, or folder containing an `init.lua` file will automatically be
--- loaded as a plugin.
---
--- Eg:
---
--- ```
--- plugins.loadPlugins("hs.fcpxhacks.plugins")
--- ```
---
--- Parameters:
---  * package - The LUA package to look in
---
--- Returns:
---  * table
---
function mod.loadPlugin(pluginPath)
	log.df("Loading plugin '%s'", pluginPath)
	
	-- First, check the plugin is not disabled:
	if mod.isPluginDisabled(pluginPath) then
		log.df("Plugin disabled: '%s'", pluginPath)
		return nil
	end
	
	local cache = mod.CACHE[pluginPath]
	if cache ~= nil then
		-- we've already loaded it
		return cache.instance
	end
	
	local plugin = require(pluginPath)
	if not plugin then
		log.ef("Unable to load plugin '%s'.", pluginPath)
		return nil
	end
	
	local dependencies = {}
	if plugin.dependencies then
		for path,alias in pairs(plugin.dependencies) do
			if type(path) == "number" then
				-- no alias
				path = alias
				alias = nil
			end
			
			local dependency = mod.loadPlugin(path)
			if dependency then
				dependencies[path] = dependency
				if alias then
					dependencies[alias] = dependency
				end
			else
				-- unable to load the dependency. Fail!
				log.ef("Unable to load dependency for plugin '%s': %s", pluginPath, d)
				return nil
			end
		end
	end
	
	-- initialise the plugin instance
	local instance = plugin.init(dependencies)
	-- cache it
	mod.CACHE[pluginPath] = {plugin = plugin, instance = instance}
	-- return the instance
	return instance
end

function mod.disablePlugin(pluginPath)
	local disabled = settings.get(mod.SETTINGS_DISABLED) or {}
	disabled[pluginPath] = true
	settings.set(mod.SETTINGS_DISABLED, disabled)
	hs.reload()
end

function mod.enablePlugin(pluginPath)
	local disabled = settings.get(mod.SETTINGS_DISABLED) or {}
	disabled[pluginPath] = false
	settings.set(mod.SETTINGS_DISABLED, disabled)
	hs.reload()
end

function mod.isPluginDisabled(pluginPath)
	local disabled = settings.get(mod.SETTINGS_DISABLED) or {}
	return disabled[pluginPath] == true
end

function mod.init(...)
	for i=1,select('#', ...) do
		package = select(i, ...)
		mod.loadPackage(package)
	end
end

return mod