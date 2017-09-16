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
--- This function will load all enabled plugins in the specified 'parent' folders. For example:
---
--- ```lua
--- local plugins = require("cp.plugins")
--- plugins.init("~/Library/Application Support/CommandPost/Plugins")
--- ```
---
--- This will load all plugins in the current user's `Library/Application Support/CommandPost/Plugins` folder.
--- 
--- ### `cp.plugins.getPluginModule(id)`
---
--- Once the plugins have been loaded, the module can be accessed by their ID via the `getPluginModule(id)` function. It will return the module returned by the plugin's `init` function. This can also be done via the default function for the library. Eg:
---
--- ```lua
--- plugins("my.plugin.id").doSomething()
--- ```
---
--- ## Plugin Modules
---
--- Plugins typically have two parts:
--- 1. The plugin table, which defines details about the plugin, and
--- 2. The module, or result, which could be anything, which is returned from the `init` function.
--- 
--- 
--- A plugin file should return a `plugin` table that allows the plugin to be initialised. The table will look something like this:
---
--- ```lua
--- local module = {}
--- 
--- local module.init(otherPlugin)
---     -- do stuff with otherPlugin here
--- end
---
--- local plugin = {
---     id = "my.plugin.id",
---     group = "foo",
---     dependencies = {
---         ["some.other.plugin"] = "otherPlugin",
---     },
--- }
---
--- function plugin.init(dependencies)
---    -- do stuff to initialise the module here
---    module.init(dependencies.otherPlugin)
---    return module
--- }
--- 
--- function plugin.postInit(dependencies)
---    -- do stuff that will happen after all plugins have been initialised.
--- end
--- ```
---
--- As you can see above, plugin module can have a few simple functions and properties. The key ones are:
---
--- ### `plugin.id`
--- This is a unique ID for the plugin. It is used to load the plugin externally, as well as to define dependencies between plugins.
---
--- ### `plugin.group`
--- This is the group ID for the plugin. This is used to group plugins visually in the Properties panel for Plugins.
---
--- ### `plugin.required`
--- This optional property can be specified for plugins which should never be disabled. This should only be set for plugins which will break the application if disabled.
--- 
--- ### `plugin.dependencies`
---
--- This is a table with the list of other plugins that this plugin requires to be loaded prior to this plugin. Be careful of creating infinite loops of dependencies - we don't check for them currently!
---
--- It is defined like so:
---
--- ```lua
--- plugin.dependencies = {
--- 	"cp.plugins.myplugin",
--- 	["cp.plugins.otherplugin"] = "otherPlugin"
--- }
---
--- As you can see, there are two ways of declaring a dependency. The first is with just the plugin ID, the second has an alias.
---
--- These can be accessed in the `init` and `postInit` functions like so:
---
--- ```lua
--- function plugin.init(dependencies)
---    local myPlugin = dependencies["cp.plugins.myplugin"]
---    local otherPlugin = dependencies.otherPlugin -- or dependencies["cp.plugins.otherplugin"]
--- end
--- ```
---
--- A plugin will only have its `init` function called after its dependencies have successfully had their `init` functions called. Additionally, if a plugin has a `postInit`, all declared `postInits` for dependencies will have been called prior to the plugin's `postInit` function.
---
--- ### `function plugin.init(dependencies[, environment]) -> module`
---
--- This function is basically required. It will be executed when the plugin is initialised. The `dependencies` parameter is a table containing the list of dependencies that the plugin defined via the `dependencies` property. The `environment` provides access to resources such as images, HTML files, or other lua modules that are bundled with the plugin. See `Simple vs Complex Plugins` below.
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
---
--- ## Simple vs Complex Plugins
---
--- There are two types of plugin structures supported. The Simple version is a single `.lua` file that matches the above format for `plugin`. The Complex version is a folder containing an `init.lua` file that matches the above format.
---
--- The key advantage of Complex Plugins is that the folder can contain other resources, such as images, HTML templates, or other `.lua` files - including 3rd-party libraries if desired. These can be accessed via two main mechanisms:
---
--- 1. The second `environment` parameter in the `init` function. This is a [cp.plugins.env](cp.plugins.env.md) table, which provides access to files and templates inside the plugin folder. See the [documentation](cp.plugins.env.md) for details.
--- 2. The standard `require` method will allow loading of `*.lua` files inside the plugin from the `init.lua`.
---
--- For example, if you have a file called `foo.lua` in your folder, it can be `required` like so:
---
--- ```lua
--- local foo = require("foo")
--- ```
---
--- You do not have to know anything about where the plugin folder is stored, or use the plugin ID. Just use the local file path within the plugin. If you have another file in a `foo` folder called `bar.lua`, it can be loaded via:
--- 
--- ```lua
--- local fooBar = require("foo.bar")
--- ```
---
--- These modules will not be accessible to other plugins or to the main application. They are only available to code inside the plugin.

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
local timer							= require("hs.timer")

local config						= require("cp.config")
local tools							= require("cp.tools")

local plugin						= require("cp.plugins.plugin")
local env							= require("cp.plugins.env")

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

local function cachePlugin(id, pluginTable, status, scriptFile)
	local existing = mod.getPluginModule(id)
	if not existing then
		local thePlugin = plugin.init(pluginTable, status, scriptFile)
		mod.CACHE[id] = thePlugin
		mod.IDS[#mod.IDS + 1] = id

		-- log.df("Loaded plugin: %s", thePlugin.id)
		return thePlugin
	else
		log.df([[Duplicate plugin with ID of '%s':
				 			 existing: %s
							duplicate: %s]],
				id, existing.scriptFile, scriptFile)
		return nil
	end
end

--- cp.plugins.getPluginModule(id) -> value
--- Function
--- Returns an initialised plugin result with the specified `id`.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * the result of the plugin's `init(...)` function call.
---
function mod.getPluginModule(id)
	local plugin = mod.getPlugin(id)
	return plugin and plugin:getModule()
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

function mod.getPlugin(id)
	return mod.CACHE[id]
end

--- cp.plugins.getPlugins() -> table
--- Function
--- Retrieves an array of details about the set of loaded plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the list of plugins.
---
function mod.getPlugins()
	local pluginList = {}
	for _,plugin in pairs(mod.CACHE) do
		pluginList[#pluginList+1] = plugin
	end
	return pluginList
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

--- cp.plugins.initPlugin(id) -> module
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

	local plugin = mod.getPlugin(id)
	if not plugin then
		log.ef("Attempted to initialise non-existent plugin: %s", id)
		return nil
	end

	if plugin:getStatus() ~= mod.status.loaded or plugin:getModule() ~= nil then
		-- we've already loaded it. Return the cache's module.
		return plugin:getModule()
	end

	-- First, check the plugin is not disabled:
	if mod.isDisabled(id) then
		log.df("Plugin disabled: '%s'", id)
		plugin:setStatus(mod.status.disabled)
		return nil
	end

	-- Ensure all dependencies are loaded
	local dependencies = mod.loadDependencies(plugin)
	if not dependencies then
		plugin:setStatus(mod.status.error)
		return nil
	end

	plugin:setDependencies(dependencies)

	-- initialise the plugin module
	-- log.df("Initialising plugin '%s'.", id)
	local module = nil

	if plugin.init then
		local ok, result = xpcall(function()
			return plugin.init(dependencies, env.new(plugin:getRootPath()))
		end, debug.traceback)

		if ok then
			module = result
		else
			log.ef("Error while initialising plugin '%s':\n%s", id, result)
			return nil
		end
	else
		log.wf("No init function for plugin: %s", id)
	end

	-- Default the return value to 'true'
	if module == nil then
		module = true
	end

	-- cache it
	plugin:setModule(module)
	plugin:setStatus(mod.status.initialized)

	-- return the module
	-- log.df("Initialised plugin: %s", id)
	return module
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
				mod.addDependent(path, plugin)
			else
				-- unable to load the dependency. Fail!
				log.ef("Unable to load dependency for plugin '%s': %s", plugin.id, path)
				return nil
			end
		end
	end
	return dependencies
end

--- cp.plugins.addDependent(id) -> nothing
--- Function
--- Adds the `dependentPlugin` as a dependent of the plugin with the specified id.
---
--- Parameters:
---  * `id`					- The plugin package ID.
---  * `dependentPlugin`	- The plugin which is a dependent
---
--- Returns:
---  * nothing
---
function mod.addDependent(id, dependentPlugin)
	local plugin = mod.getPlugin(id)
	if plugin then
		plugin.addDependent(dependentPlugin)
	end
end

--- cp.plugins.getDependents(pluginId)
--- Function
--- Retrieves the list of dependent plugins for the specified plugin id.
---
--- Parameters:
--- * `id`		- The plugin ID.
---
--- Returns:
---  * The table of dependents.
function mod.getDependents(id)
	local plugin = mod.getPlugin(id)
	return plugin and plugin:getDependents()
end

--- cp.plugins.disable(id) -> nothing
--- Function
--- Disabled the plugin with the specified ID and reloads the application.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin was disabled, or `false` if it could not be disabled.
function mod.disable(id)
	local plugin = mod.getPlugin(id)
	if plugin and not plugin.required then
		-- first check with the plugin, if relevant
		if type(plugin.disable) == "function" then
			if not plugin.disable(plugin:getDependencies(), env.new(plugin:getRootPath())) then
				return false
			end
		end
		local disabled = config.get(mod.SETTINGS_DISABLED, {})
		disabled[id] = true
		config.set(mod.SETTINGS_DISABLED, disabled)
		console.clearConsole()
		-- reload CP after returning `true`
		timer.doAfter(0.001, function() hs.reload() end)
		return true
	end
	return false
end

--- cp.plugins.enable(id) -> nothing
--- Function
--- Enables the plugin with the specified ID, and reloads the application.
---
--- Parameters:
---  * `id` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin had been disabled and is now enabled.
function mod.enable(id)
	local disabled = config.get(mod.SETTINGS_DISABLED, {})
	if disabled[id] then
		disabled[id] = false
		config.set(mod.SETTINGS_DISABLED, disabled)
		console.clearConsole()
		timer.doAfter(0.001, function() hs.reload() end)
		return true
	end
	return false
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
	-- log.df("Post-initialising plugin: %s", id)
	local plugin = mod.getPlugin(id)
	if not plugin then
		log.ef("Unable to post-initialise '%s': plugin not loaded", id)
		return false
	end

	-- Check it exists and is initialized and ready to post-init
	if plugin:getStatus() == mod.status.active then
		-- already post-intialised successfully
		return true
	elseif plugin:getStatus() == mod.status.initialized then
		if plugin.postInit then
			local dependencies = plugin:getDependencies()
			-- ensure dependecies are post-initialised first
			if plugin.dependencies then
				for key,value in pairs(plugin.dependencies) do
					local depId = key
					if type(key) == "number" then
						depId = value
					end
					if not mod.postInitPlugin(depId) then
						log.ef("Unable to post-initialise '%s': dependency failed to post-init: %s", id, depId)
						plugin:setStatus(mod.status.error)
						return false
					end
				end
			end

			plugin.postInit(dependencies, env.new(plugin:getRootPath()))
		end
		plugin:setStatus(mod.status.active)
		return true
	elseif plugin:getStatus() ~= mod.status.disabled then
		log.ef("Unable to post-initialise '%s': expected status of %s but is %s", id, inspect(mod.status.initialized), inspect(plugin:getStatus()))
		plugin:setStatus(mod.status.error)
		return false
	end
	return true
end

--- cp.plugins.init(paths) -> cp.plugins
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
---  * `paths` - An array of paths to search for plugins in.
---
--- Returns:
---  * `cp.plugins` - The module.
function mod.init(paths)

	mod.paths = fnutils.copy(paths)

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
---  * `path` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin ias successfully post-initialised.
---
function mod.loadSimplePlugin(path)
	-- load the plugin file, catching any errors
	local ok, result = xpcall(function() return dofile(path) end, debug.traceback)
	if ok then
		local plugin = result
		if plugin == nil or type(plugin) ~= "table" then
			log.ef("Unable to load plugin '%s'.", path)
			return nil
		else
			if not plugin.id then
				log.ef("The plugin at '%s' does not have an ID.", path)
				return nil
			else
				return cachePlugin(plugin.id, plugin, mod.status.loaded, path)
			end
		end
	else
		log.ef("Unable to load plugin '%s' due to the following error:\n\n%s", path, result)
		return nil
	end
end

--- cp.plugins.loadComplexPlugin(path) -> plugin
--- Function
--- Loads a 'complex' plugin, which is a folder containing an `init.lua` file.
--- Complex plugins can also have other resources, accessible via an `cp.plugins.env` parameter
--- passed to the `init()` function. For example, an image stored in the `images` folder
--- inside the plugin can be accessed via:
--- 
--- ```lua
--- function plugin.init(dependencies, env)
--- 	local imagePath = env:pathToAbsolute("image/example.jpg")
--- end
--- ```
---
--- Parameters:
---  * `path` - The plugin package ID.
---
--- Returns:
---  * `true` if the plugin ias successfully post-initialised.
---
function mod.loadComplexPlugin(path)
	local initFile = fs.pathToAbsolute(path .. "/init.lua")
	if not initFile then
		log.ef("Unable to load the plugin '%s': Missing 'init.lua'", path)
		return false
	end

	-- Local reference to 'require' function
	local globalRequire = require

	-- Stores cached modules from the plugin
	local cache = {}
	local searchPath = path .. "/?.lua;" .. path .. "/?/init.lua"

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
		result:setRootPath(path)
	end

	-- Reset 'require' to the global require
	require = globalRequire

	return result
end

setmetatable(mod, {__call = function(_, ...) return mod.getPluginModule(...) end})

return mod