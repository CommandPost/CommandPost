local log							= require("hs.logger").new("pluginenv")

local template						= require("resty.template")
local fs							= require("hs.fs")
local config						= require("cp.config")

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

return env