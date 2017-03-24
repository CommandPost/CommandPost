--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       P L U G I N     L O A D E R                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("plugins")

local console						= require("hs.console")
local fs							= require("hs.fs")
local inspect						= require("hs.inspect")
local fnutils						= require("hs.fnutils")

local metadata						= require("cp.config")
local tools							= require("cp.tools")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	mod.CACHE = {}
	
	mod.status = {
		loaded				= 1,
		initialized			= 5,
		active				= 10,
		disabled			= 99,
		error				= 999,
	}

	mod.SETTINGS_DISABLED 	= "plugins.disabled"
	
	local function cachePlugin(id, plugin, status)
		if not mod.CACHE[id] then
			mod.CACHE[id] = {plugin = plugin, status = status or mod.status.loaded}
		end
		return plugin
	end

	--- cp.plugins.loadPackage(package) -> boolean
	--- Function
	--- Loads any plugins present in the specified package.
	--- Any `*.lua` file, or folder containing an `init.lua` file will automatically be
	--- loaded as a plugin.
	---
	--- Eg:
	---
	--- ```
	--- plugins.loadPackage("cp.plugins")
	--- ```
	---
	--- Parameters:
	---  * package - The LUA package to look in
	---
	--- Returns:
	---  * boolean - `true` if all plugins loaded successfully
	---
	function mod.loadPackage(package)

		if type(package) == "table" then
			if next(package) == nil then
				log.ef("Skipping: " .. inspect(package))
				return false
			end
		end

		local path = fs.pathToAbsolute(metadata.scriptPath .. "/" .. package:gsub("%.", "/"))
		if not path then
			log.ef("The provided path does not exist: '%s'", package)
			return false
		end

		local attrs = fs.attributes(path)
		if not attrs or attrs.mode ~= "directory" then
			log.ef("The provided path is not a directory: '%s'", package)
			return false
		end

		local files = tools.dirFiles(path)
		for i,file in ipairs(files) do
			if file ~= "." and file ~= ".." and file ~= "init.lua" then
				local filePath = path .. "/" .. file
				if fs.attributes(filePath).mode == "directory" then
					local attrs, err = fs.attributes(filePath .. "/init.lua")
					if attrs and attrs.mode == "file" then
						-- it's a plugin
						mod.load(package .. "." .. file)
					else
						-- it's a plain folder. Load it as a sub-package.
						mod.loadPackage(package .. "." .. file)
					end
				else
					local name = file:match("(.+)%.lua$")
					if name then
						mod.load(package .. "." .. name)
					end
				end
			end
		end

		return true
	end
	
	function mod.initPlugins()
		for id,_ in pairs(mod.CACHE) do
			mod.initPlugin(id)
		end
	end

	--- cp.plugins.load(package) -> boolean
	--- Function
	--- Loads a specific plugin with the specified path.
	--- The plugin will only be loaded once, and the result of its `init(...)` function
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

		local cache = mod.CACHE[pluginId]
		if not cache then
			log.ef("Attempted to initialise non-existent plugin: %s", pluginId)
			return nil
		end
		
		if cache.instance ~= nil then
			-- we've already loaded it. Return the cache's instance.
			return cache.instance
		end
		
		-- First, check the plugin is not disabled:
		if mod.isDisabled(pluginId) then
			log.df("Plugin disabled: '%s'", pluginId)
			cache.status = mod.status.disabled
			return nil
		end
		
		local plugin = cache.plugin

		-- Ensure all dependencies are loaded
		local dependencies = mod.loadDependencies(plugin)
		if not dependencies then
			log.ef("Unable to load all dependencies for plugin '%s'.", pluginId)
			cache.status = mod.status.error
			return nil
		end
		
		cache.dependencies = dependencies

		-- initialise the plugin instance
		-- log.df("Initialising plugin '%s'.", pluginPath)
		local instance = nil

		if plugin.init then
			local status, err = pcall(function()
				instance = plugin.init(dependencies)
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
		cache.instance = instance
		cache.status = mod.status.initialized
		
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
					log.ef("Unable to load dependency for plugin '%s': %s", pluginPath, path)
					return nil
				end
			end
		end
		return dependencies
	end

	function mod.disable(pluginPath)
		local disabled = metadata.get(mod.SETTINGS_DISABLED, {})
		disabled[pluginPath] = true
		metadata.set(mod.SETTINGS_DISABLED, disabled)
		console.clearConsole()
		hs.reload()
	end

	function mod.enable(pluginPath)
		local disabled = metadata.get(mod.SETTINGS_DISABLED, {})
		disabled[pluginPath] = false
		metadata.set(mod.SETTINGS_DISABLED, disabled)
		console.clearConsole()
		hs.reload()
	end

	function mod.isDisabled(pluginPath)
		local disabled = metadata.get(mod.SETTINGS_DISABLED, {})
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
	--- plugins.loadPackage("~/Library/Application Support/CommandPost/Plugins")
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
		for _,cached in pairs(mod.CACHE) do
			local plugin = cached.plugin
			if plugin.postInit then
				plugin.postInit(cached.dependencies)
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
			return mod.loadComplexPlugin(path) ~= nil
		end

		-- Ok, let's process the contents of the directory
		local files = tools.dirFiles(path)
		local success = true
		for i,file in ipairs(files) do
			if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
				local filePath = fs.pathToAbsolute(path .. "/" .. file)
				attrs = fs.attributes(filePath)
				
				if attrs.mode == "directory" then
					success = success and mod.scanDirectory(filePath)
				else
					success = success and mod.loadSimplePlugin(filePath) ~= nil
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
					log.ef("The plugin at '%s' does not have an ID.")
					return nil
				else
					log.df("Loaded plugin: %s", plugin.id)
					return cachePlugin(plugin.id, plugin, mod.status.loaded)
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
		
		-- Add the plugin path to the package.path for execution of local .lua files
		local oldPath = package.path
		package.path = pluginPath .. "/?.lua;" .. pluginPath .. "/?/init.lua;" ..package.path 
		
		local result = mod.loadSimplePlugin(initFile)
		
		package.path = oldPath
		
		return result
	end
	
	setmetatable(mod, {__call = function(_, ...) return mod.load(...) end})

return mod