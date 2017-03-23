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

local metadata						= require("cp.metadata")
local tools							= require("cp.tools")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	mod.CACHE = {}

	mod.SETTINGS_DISABLED 	= "plugins.disabled"

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
	---  * package - The LUA package to look in
	---
	--- Returns:
	---  * the result of the plugin's `init(...)` function call.
	---
	function mod.load(pluginPath)
		-- log.df("Loading plugin '%s'", pluginPath)

		-- First, check the plugin is not disabled:
		if mod.isDisabled(pluginPath) then
			log.df("Plugin disabled: '%s'", pluginPath)
			return nil
		end

		local cache = mod.CACHE[pluginPath]
		if cache ~= nil then
			-- we've already loaded it
			return cache.instance
		end

		local status, err = pcall(require, pluginPath)
		local plugin = nil
		if status then
			plugin = require(pluginPath)
			if plugin == nil or type(plugin) ~= "table" then
				log.ef("Unable to load plugin '%s'.", pluginPath)
				return nil
			end
		else
			failedPlugins[#failedPlugins + 1] = pluginPath
			log.ef("Unable to load plugin '%s' due to the following error:\n\n%s", pluginPath, err)
			return nil
		end

		local dependencies = mod.loadDependencies(plugin)

		-- initialise the plugin instance
		-- log.df("Initialising plugin '%s'.", pluginPath)
		local instance = nil

		if plugin.init then
			local status, err = pcall(function()
				instance = plugin.init(dependencies)
			end)

			if not status then
				failedPlugins[#failedPlugins + 1] = pluginPath
				log.ef("Error while initialising plugin '%s': %s", pluginPath, inspect(err))
				return nil
			end
		else
			log.wf("No init function for plugin: %s", pluginPath)
		end

		-- Default the return value to 'true'
		if instance == nil then
			instance = true
		end

		-- cache it
		mod.CACHE[pluginPath] = {plugin = plugin, instance = instance}
		-- return the instance
		log.df("Loaded plugin '%s'", pluginPath)
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

				local dependency = mod.load(path)
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

	function mod.init(...)

		-- Global Variable for Storing Failed Plugins:
		failedPlugins = {}

		-- load the plugins
		for i=1,select('#', ...) do
			package = select(i, ...)
			log.df("Loading plugin package '%s'", package)
			local status, err = pcall(function()
				mod.loadPackage(package)
			end)

			if not status then
				log.ef("Error while loading package '%s':\n%s", package, inspect(err))
			end
		end

		-- notify them of a `postInit`
		for _,cached in pairs(mod.CACHE) do
			local plugin = cached.plugin
			if plugin.postInit then
				local dependencies = mod.loadDependencies(plugin)
				plugin.postInit(dependencies)
			end
		end

		return mod
	end

	setmetatable(mod, {__call = function(_, ...) return mod.load(...) end})

return mod