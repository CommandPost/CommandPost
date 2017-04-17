--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       P L U G I N     L O A D E R                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins ===
---
--- This is a simple plugin manager.
---
--- ## Functions
---
--- It has a few core functions:
---
--- ### `plugins.init(...)`
---
--- This function will load all enabled plugins in the specified 'parent' package. For example, the default plugin path for CommandPost is `cp.plugins`. This directory contains a collection of `*.lua` files or subdirectories. To initialse the system to load this path, you would call:
---
--- ```lua
--- local plugins = require("cp.modules.plugins")
--- plugins.init("cp.plugins")
--- ```
---
--- ### `plugins.loadPlugin(...)`
---
--- This function loads a plugin directly. If it has dependencies, the dependencies will also be loaded (if possible). If successful, the result of the plugin's `init(dependencies)` function will be returned.
---
--- ### `plugins.loadPackage(...)`
---
--- This function will load a package of plugins. If the package contains sub-packages, they will be loaded recursively.
---
--- ## Plugin Modules
---
--- A plugin file should return a `plugin` table that allows the plugin to be initialised.
---
--- A plugin module can have a few simple functions and properties. The key ones are:
---
--- ### `function plugin.init(dependencies)`
---
--- If the `init(dependencies)` function is present, it will be executed when the plugin is loaded. The `dependencies` parameter is a table containing the list of dependencies that the plugin defined
---
--- ### `plugin.dependencies` table
---
--- This is a table with the list of other plugins that this plugin requires to be loaded prior to this plugin. Be careful of creating infinite loops of dependencies - we don't check for them currently!
---
--- It is defined like so:
---
--- ```lua
--- plugin.dependencies = {
--- 	"cp.plugins.myplugin",
--- 	["cp.plugins.otherplugin"] = "otherplugin"
--- }
--- ```
---
--- As you may have noted, there are two ways to specify a plugin is required. Either by simply specifying it as an 'array' item (the first example) or as a key/value (the second example). Doing the later allows you to specify an alias for the dependency, which can be used in the `init(...)` function, like so:
---
--- ```lua
--- local plugin = {}
---
--- plugin.dependencies = {
--- 	"cp.plugins.myplugin",
--- 	["cp.plugins.otherplugin"] = "otherplugin"
--- }
---
--- function plugin.init(dependencies)
--- 	local myplugin = dependencies["cp.plugins.myplugin"]
--- 	local otherplugin = dependencies.otherplugin
---
--- 	-- do other stuff with the dependencies
---
--- 	return myinstance
--- end
---
--- return plugin
--- ```

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

local template						= require("resty.template")

-- Disable template caching
template.caching(false)

--------------------------------------------------------------------------------
-- ENVIRONMENT:
--------------------------------------------------------------------------------
local env = {}

function env.new(rootPath)
	local o = {
		rootPath = rootPath,
	}
	return setmetatable(o, { __index = env })
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

function env:pathToURL(resourcePath)
	local path = self:pathToAbsolute(resourcePath)
	if path then
		return "file://" .. path
	else
		return nil
	end
end

function env:readResource(resourcePath)
	local name = self:pathToAbsolute(resourcePath)
	if not name then
		return nil, ("Unable to read resource file: '%s'"):format(resourcePath)
	end

	local f, err = io.open(name, "rb")
	if not f then
	    return nil, err
	end
	local t = f:read("*all")
	f:close()
	return t
end

function env:compileTemplate(view, layout)
	-- replace the load function to allow loading from the plugin
	local oldLoader = template.load
	local load_plugin = function(path)
		local content, err = self:readResource(path)
		if err then
			log.df("Unable to load '%s': %s", path, err)
			return path
		else
			return content
		end
	end

	template.load = load_plugin
	local result, err = template.compile(view, layout)
	if err then
		log.ef("Error while compiling template at '%s':\n%s", view, err)
		return result, err
	end
	template.load = oldLoader

	-- replace the render function to replace the loader when rendering
	return function(...)
		local oldLoad = template.load
		template.load = load_plugin
		local content, err = result(...)
		template.load = oldLoad
		return content, err
	end
end

function env:renderTemplate(view, model, layout)
	return self:compileTemplate(view, layout)(model)
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.CACHE	= {}
mod.PLUGINS	= {}
mod.IDS		= {}

mod.status = {
	loaded				= "loaded",
	initialized			= "initialized",
	active				= "active",
	disabled			= "disabled",
	error				= "error",
}

mod.SETTINGS_DISABLED 	= "plugins.disabled"

local function cachePlugin(id, plugin, status, scriptFile)
	local existing = mod.CACHE[id]
	if not existing then
		local info = {
			plugin		= plugin,
			status		= status or mod.status.loaded,
			scriptFile	= scriptFile,
		}
		mod.CACHE[id] = info
		mod.PLUGINS[#mod.PLUGINS + 1] = plugin
		mod.IDS[#mod.IDS + 1] = id

		log.df("Loaded plugin: %s", plugin.id)
		return info
	else
		log.df([[Duplicate plugin with ID of '%s':
				 			 existing: %s
							duplicate: %s]],
				plugin.id, existing.scriptFile, scriptFile)
		return nil
	end
end

--- cp.plugins.getPlugin(id) -> value
--- Function
--- Returns an initialised plugin result with the specified `id`
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * the result of the plugin's `init(...)` function call.
---
function mod.getPlugin(id)
	local info = mod.CACHE[id]
	return info and info.instance
end

--- cp.plugins.getPluginIds() -> table
--- Function
--- Retrieves an array of the loaded plugin IDs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the list of plugin IDs.
---
function mod.getPluginIds()
	return mod.IDS
end

--- cp.plugins.getPluginInfos() -> table
--- Function
--- Retrieves an array of details about the set of loaded plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the list of plugin infos.
---
function mod.getPluginInfos()
	local infos = {}
	for _,info in pairs(mod.CACHE) do
		infos[#infos + 1] = info
	end
	return infos
end

--- cp.plugins.getPluginGroup(id) -> string
--- Function
--- Returns the group for the specifed plugin ID.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * the list of plugin IDs.
---
function mod.getPluginGroup(id)
	local info = mod.CACHE[id]
	return info and info.plugin.group or nil
end

--- cp.plugins.getPluginStatus(id) -> cp.plugins.status
--- Function
--- Returns the status for the specified plugin ID.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * the plugin status, or `nil` if the plugin has not been registered.
---
function mod.getPluginStatus(id)
	local info = mod.CACHE[id]
	return info and info.status
end

--- cp.plugins.initPlugins() -> nothing
--- Function
--- Initialises all registered plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
---
function mod.initPlugins()
	for _,id in ipairs(mod.IDS) do
		mod.initPlugin(id)
	end
end

--- cp.plugins.initPlugin(id) -> instance
--- Function
--- Initialises a specific plugin with the specified path.
--- The plugin will only be loaded once, and the result of its `init(...)` function
--- will be cached for future calls.
---
--- Eg:
---
--- ```
--- plugins.initPlugin("cp.plugins.test.helloworld")
--- ```
---
--- Parameters:
---  * `id` - The LUA package to look in
---
--- Returns:
---  * the result of the plugin's `init(...)` function call.
---
function mod.initPlugin(id)
	-- log.df("Loading plugin '%s'", id)

	local info = mod.CACHE[id]
	if not info then
		log.ef("Attempted to initialise non-existent plugin: %s", id)
		return nil
	end

	if info.status ~= mod.status.loaded or info.instance ~= nil then
		-- we've already loaded it. Return the cache's instance.
		return info.instance
	end

	-- First, check the plugin is not disabled:
	if mod.isDisabled(id) then
		log.df("Plugin disabled: '%s'", id)
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
	-- log.df("Initialising plugin '%s'.", id)
	local instance = nil

	if plugin.init then
		local status, err = pcall(function()
			instance = plugin.init(dependencies, env.new(info.rootPath))
		end)

		if not status then
			log.ef("Error while initialising plugin '%s': %s", id, inspect(err))
			return nil
		end
	else
		log.wf("No init function for plugin: %s", id)
	end

	-- Default the return value to 'true'
	if instance == nil then
		instance = true
	end

	-- cache it
	info.instance = instance
	info.status = mod.status.initialized

	-- return the instance
	log.df("Initialised plugin: %s", id)
	return instance
end

--- cp.plugins.loadDependencies(plugin) -> table
--- Function
--- Loads the list of dependencies for the provided plugin.
---
--- Parameters:
---  * `plugin` - The plugin object
---
--- Returns:
---  * an array of the dependencies required by the plugin, or `nil` if any could not be loaded.
---
function mod.loadDependencies(plugin)
	local dependencies = {}
	if plugin.dependencies then
		-- log.df("Processing dependencies for '%s'.", plugin.id)
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

--- cp.plugins.disable(id) -> nothing
--- Function
--- Disabled the plugin with the specified ID and reloads the application.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * nothing
---
function mod.disable(id)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	disabled[id] = true
	config.set(mod.SETTINGS_DISABLED, disabled)
	console.clearConsole()
	hs.reload()
end

--- cp.plugins.enable(id) -> nothing
--- Function
--- Enables the plugin with the specified ID, and reloads the application.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * nothing
---
function mod.enable(id)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	disabled[id] = false
	config.set(mod.SETTINGS_DISABLED, disabled)
	console.clearConsole()
	hs.reload()
end

--- cp.plugins.isDisabled(id) -> boolean
--- Function
--- Checks if the specified plugin ID is disabled.
--- Plugins are enabled by default.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin is disabled.
---
function mod.isDisabled(id)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	return disabled[id] == true
end

--- cp.plugins.postInitPlugins() -> nothing
--- Function
--- Performs any post-initialisation required for plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
---
function mod.postInitPlugins()
	for _,id in pairs(mod.IDS) do
		mod.postInitPlugin(id)
	end
end

--- cp.plugins.postInitPlugin(id) -> boolean
--- Function
--- Runs any post-initialisation functions declared for the specified plugin ID.
--- Any dependencies will be post-initialised prior to the plugin being post-initialised.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin ias successfully post-initialised.
---
function mod.postInitPlugin(id)
	local info = mod.CACHE[id]
	if not info then
		log.ef("Unable to post-initialise '%s': plugin not loaded", id)
		return false
	end

	-- Check it exists and is initialized and ready to post-init
	if info.status == mod.status.active then
		-- already post-intialised successfully
		return true
	elseif info.status == mod.status.initialized then
		local plugin = info.plugin
		if plugin.postInit then
			-- ensure dependecies are post-initialised first
			if plugin.dependencies then
				for key,value in pairs(plugin.dependencies) do
					local depId = key
					if type(key) == "number" then
						depId = value
					end
					if not mod.postInitPlugin(depId) then
						log.ef("Unable to post-initialise '%s': dependency failed to post-init: %s", id, depId)
						info.status = mod.status.error
						return false
					end
				end
			end

			plugin.postInit(info.dependencies, env.new(info.rootPath))
		end
		info.status = mod.status.active
		return true
	elseif info.status ~= mod.status.disabled then
		log.ef("Unable to post-initialise '%s': expected status of %s but is %s", id, inspect(mod.status.initialized), inspect(info.status))
		info.status = mod.status.error
		return false
	end
	return true
end

--- cp.plugins.init(ids) -> cp.plugins
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
---  * `ids` - An array of paths to search for plugins in.
---
--- Returns:
---  * `cp.plugins` - The module.
function mod.init(ids)

	mod.paths = fnutils.copy(ids)

	-- watch for future changes in the plugin paths.
	mod.watchPluginPaths()

	-- First, scan all plugin paths
	for _,path in ipairs(mod.paths) do
		mod.scanDirectory(path)
	end

	-- notify them of an `init`
	mod.initPlugins()

	-- notify them of a `postInit`
	mod.postInitPlugins()

	return mod
end

--- cp.plugins.watchPluginPaths() -> nothing
--- Function
--- Watches the plugin paths for changes and reloads the  application if any change.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
---
function mod.watchPluginPaths()
	--------------------------------------------------------------------------------
	-- Watch for Script Updates:
	--------------------------------------------------------------------------------
	for _,path in ipairs(mod.paths) do
		config.sourceWatcher:watchPath(path)
	end
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

--- cp.plugins.loadSimplePlugin(id) -> plugin
--- Function
--- Loads a 'simple' plugin, where it is defined by a single LUA script.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin ias successfully post-initialised.
---
function mod.loadSimplePlugin(id)
	-- load the plugin file, catching any errors
	local ok, result = pcall(dofile, id)
	if ok then
		local plugin = result
		if plugin == nil or type(plugin) ~= "table" then
			log.ef("Unable to load plugin '%s'.", id)
			return nil
		else
			if not plugin.id then
				log.ef("The plugin at '%s' does not have an ID.", id)
				return nil
			else
				local info = cachePlugin(plugin.id, plugin, mod.status.loaded, id)
				return info
			end
		end
	else
		log.ef("Unable to load plugin '%s' due to the following error:\n\n%s", id, result)
		return nil
	end
end

--- cp.plugins.loadComplexPlugin(id) -> plugin
--- Function
--- Loads a 'complex' plugin, which is a folder containing an `init.lua` file.
--- Complex plugins can also have other resources, accessible via an `env` parameter
--- passed to the `init()` function. Eg:
--- 
--- ```lua
--- function plugin.init(dependencies, env)
--- ```
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin ias successfully post-initialised.
---
function mod.loadComplexPlugin(id)
	local initFile = fs.pathToAbsolute(id .. "/init.lua")
	if not initFile then
		log.ef("Unable to load the plugin '%s': Missing 'init.lua'", id)
		return false
	end

	-- Local reference to 'require' function
	local globalRequire = require

	-- Stores cached modules from the plugin
	local cache = {}
	local searchPath = id .. "/?.lua;" .. id .. "/?/init.lua"

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
		result.rootPath = id
	end

	-- Reset 'require' to the global require
	require = globalRequire

	return result
end

setmetatable(mod, {__call = function(_, ...) return mod.getPlugin(...) end})

return mod