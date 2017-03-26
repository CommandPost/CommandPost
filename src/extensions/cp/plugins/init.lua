--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       P L U G I N     L O A D E R                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins ===
---
--- Plugin Manager for CommandPost.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("plugins")

local console						= require("hs.console")
local fs							= require("hs.fs")
local inspect						= require("hs.inspect")
local fnutils						= require("hs.fnutils")

local config						= require("cp.config")
local tools							= require("cp.tools")

--------------------------------------------------------------------------------
-- ENVIRONMENT:
--------------------------------------------------------------------------------
local env = {}

function env.new(rootPath)
	local o = {
		rootPath = rootPath,
	}
	setmetatable(o, env)
	env.__index = env
	return o
end

function env:pathToAbsolute(resourcePath)
	local path = nil
	if self.rootPath then
		path = fs.pathToAbsolute(self.rootPath .. "/" .. resourcePath)
	end

	if path == nil then
		-- look in the assets path
		path = fs.pathToAbsolute(config.assetsPath .. "/" .. resourcePath)
	end

	return path
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.CACHE	= {}
mod.IDS		= {}

mod.status = {
	loaded				= "loaded",
	initialized			= "initialized",
	active				= "active",
	disabled			= "disabled",
	error				= "error",
}

mod.SETTINGS_DISABLED 	= "plugins.disabled"

local function cachePlugin(id, plugin, status)
	if not mod.CACHE[id] then
		local info = {plugin = plugin, status = status or mod.status.loaded}
		mod.CACHE[id] = info
		mod.IDS[#mod.IDS + 1] = id
		return info
	else
		return nil
	end
end

function mod.getPluginIds()
	return mod.IDS
end

function mod.getPluginGroup(id)
	local info = mod.CACHE[id]
	return info and info.plugin.group or nil
end

function mod.getPluginStatus(id)
	local info = mod.CACHE[id]
	return info and info.status
end

function mod.initPlugins()
	for _,id in ipairs(mod.IDS) do
		mod.initPlugin(id)
	end
end

--- cp.plugins.load(package) -> boolean
--- Function
--- Loads a specific plugin with the specified path.
---------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
-------------------------------------------------------------------------------- will only be loaded once, and the result of its `init(...)` function
--- will be cached for future calls.
---
--- Eg:
---
--- ```
--- plugins.load("cp.plugins.test.helloworld")
--- ```
---
--- Parameters:
---  * `pluginId` - The LUA package to look in
---
--- Returns:
---  * the result of the plugin's `init(...)` function call.
---
function mod.initPlugin(pluginId)
	-- log.df("Loading plugin '%s'", pluginId)

	local info = mod.CACHE[pluginId]
	if not info then
		log.ef("Attempted to initialise non-existent plugin: %s", pluginId)
		return nil
	end

	if info.status ~= mod.status.loaded or info.instance ~= nil then
		-- we've already loaded it. Return the cache's instance.
		return info.instance
	end

	-- First, check the plugin is not disabled:
	if mod.isDisabled(pluginId) then
		log.df("Plugin disabled: '%s'", pluginId)
		info.status = mod.status.disabled
		return nil
	end

	local plugin = info.plugin

	-- Ensure all dependencies are loaded
	local dependencies = mod.loadDependencies(plugin)
	if not dependencies then
		info.status = mod.status.error
		return nil
	end

	info.dependencies = dependencies

	-- initialise the plugin instance
	-- log.df("Initialising plugin '%s'.", pluginPath)
	local instance = nil

	if plugin.init then
		local status, err = pcall(function()
			instance = plugin.init(dependencies, env.new(info.rootPath))
		end)

		if not status then
			log.ef("Error while initialising plugin '%s': %s", pluginId, inspect(err))
			return nil
		end
	else
		log.wf("No init function for plugin: %s", pluginId)
	end

	-- Default the return value to 'true'
	if instance == nil then
		instance = true
	end

	-- cache it
	info.instance = instance
	info.status = mod.status.initialized

	-- return the instance
	log.df("Initialised plugin: %s", pluginId)
	return instance
end

function mod.loadDependencies(plugin)
	local dependencies = {}
	if plugin.dependencies then
		-- log.df("Processing dependencies for '%s'.", pluginPath)
		for path,alias in pairs(plugin.dependencies) do
			if type(path) == "number" then
				-- no alias
				path = alias
				alias = nil
			end

			local dependency = mod.initPlugin(path)
			if dependency then
				dependencies[path] = dependency
				if alias then
					dependencies[alias] = dependency
				end
			else
				-- unable to load the dependency. Fail!
				log.ef("Unable to load dependency for plugin '%s': %s", plugin.id, path)
				return nil
			end
		end
	end
	return dependencies
end

function mod.disable(pluginPath)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	disabled[pluginPath] = true
	config.set(mod.SETTINGS_DISABLED, disabled)
	console.clearConsole()
	hs.reload()
end

function mod.enable(pluginPath)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	disabled[pluginPath] = false
	config.set(mod.SETTINGS_DISABLED, disabled)
	console.clearConsole()
	hs.reload()
end

function mod.isDisabled(pluginPath)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	return disabled[pluginPath] == true
end

--- cp.plugins.init(pluginPaths) -> cp.plugins
--- Function
--- Initialises the plugin loader to look in the specified file paths for plugins.
--- Plugins in earlier packages will take precedence over those in later paths, if
--- there are duplicates.
---
--- Eg:
---
--- ```
--- plugins.init({"~/Library/Application Support/CommandPost/Plugins"})
--- ```
---
--- Parameters:
---  * `pluginPaths` - An array of paths to search for plugins in.
---
--- Returns:
---  * `cp.plugins` - The module.
function mod.init(pluginPaths)

	mod.paths = fnutils.copy(pluginPaths)

	-- First, scan all plugin paths
	for _,path in ipairs(mod.paths) do
		mod.scanDirectory(path)
	end

	-- notify them of an `init`
	mod.initPlugins()

	-- notify them of a `postInit`
	for _,info in pairs(mod.CACHE) do
		if info.status == mod.status.initialized then
			local plugin = info.plugin
			if plugin.postInit then
				plugin.postInit(info.dependencies, env.new(info.rootPath))
			end
			info.status = mod.status.active
		end
	end

	return mod
end

--- cp.plugins.scanDirectory(directoryPath) -> cp.plugins
--- Function
--- Scans the specified directory and loads any plugins in the directory,
--- along with any in sub-directories.
---
--- Plugins can be simple or complex. Simple plugins are a single `*.lua` file,
--- not named `init.lua`. Complex plugins are folders containing an `init.lua` file.
---
--- Parameters:
---  * `directoryPath` - The path to the directory to scan.
---
--- Returns:
---  * boolean - `true` if the path was loaded successfully, false if there were any issues.
function mod.scanDirectory(directoryPath)
	-- log.df("Scanning directory: %s", directoryPath)
	local path = fs.pathToAbsolute(directoryPath)
	if not path then
		log.wf("The provided path does not exist: '%s'", directoryPath)
		return false
	end

	local attrs = fs.attributes(path)
	if not attrs or attrs.mode ~= "directory" then
		log.ef("The provided path is not a directory: '%s'", directoryPath)
		return false
	end

	-- Check if it's a 'complex plugin' directory
	if fs.pathToAbsolute(path .. "/init.lua") then
		-- log.df("It's a complex plugin folder...")
		return mod.loadComplexPlugin(path) ~= nil
	end

	-- Ok, let's process the contents of the directory
	local files = tools.dirFiles(path)
	local success = true
	for i,file in ipairs(files) do
		if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
			local filePath = fs.pathToAbsolute(path .. "/" .. file)
			-- log.df("Checking '%s'...", filePath)

			attrs = fs.attributes(filePath)
			if attrs.mode == "directory" then
				-- log.df("It's a directory...")
				success = mod.scanDirectory(filePath) and success
			elseif filePath:sub(-4) == ".lua" then
				-- log.df("It's a file...")
				success = mod.loadSimplePlugin(filePath) ~= nil and success
			else
				-- log.df("It's something else. Ignoring it.")
			end
		end
	end
	return success
end

function mod.loadSimplePlugin(pluginPath)
	-- load the plugin file, catching any errors
	local ok, result = pcall(dofile, pluginPath)
	if ok then
		local plugin = result
		if plugin == nil or type(plugin) ~= "table" then
			log.ef("Unable to load plugin '%s'.", pluginPath)
			return nil
		else
			if not plugin.id then
				log.ef("The plugin at '%s' does not have an ID.", pluginPath)
				return nil
			else
				local info = cachePlugin(plugin.id, plugin, mod.status.loaded)
				if info then
					log.df("Loaded plugin: %s", plugin.id)
				else
					log.df("Duplicate plugin for '%s': %s", plugin.id, pluginPath)
				end
				return info
			end
		end
	else
		log.ef("Unable to load plugin '%s' due to the following error:\n\n%s", pluginPath, result)
		return nil
	end
end

function mod.loadComplexPlugin(pluginPath)
	local initFile = fs.pathToAbsolute(pluginPath .. "/init.lua")
	if not initFile then
		log.ef("Unable to load the plugin '%s': Missing 'init.lua'", pluginPath)
		return false
	end

	-- Local reference to 'require' function
	local globalRequire = require

	-- Stores cached modules from the plugin
	local cache = {}
	local searchPath = pluginPath .. "/?.lua;" .. pluginPath .. "/?/init.lua"

	-- Alternate 'require' function that caches plugin resources locally.
	local pluginRequire = function(name)
		if cache[name] then
			return cache[name]
		end
		local file = package.searchpath(name, searchPath)
		if file then
			local result = dofile(file)
			cache[name] = result
			return result
		end
		return globalRequire(name)
	end

	-- replace default 'require'
	require = pluginRequire

	-- load the plugin
	local result = mod.loadSimplePlugin(initFile)
	if result then
		result.rootPath = pluginPath
	end

	-- Reset 'require' to the global require
	require = globalRequire

	return result
end

setmetatable(mod, {__call = function(_, ...) return mod.load(...) end})

return mod