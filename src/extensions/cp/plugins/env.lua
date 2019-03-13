--- === cp.plugins.env ===
---
--- Provides access to resources in the plugin environment. In generally, this will be files stored in a Complex Plugin's folder.

local require = require

local log							    = require("hs.logger").new("pluginenv")

local fs							    = require("hs.fs")

local config						  = require("cp.config")

local template						= require("resty.template")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local env = {}

-- Disable template caching
template.caching(false)

--- cp.plugins.env.new(rootPath) -> cp.plugins.env
--- Constructor
--- Creates a new `env` pointing at the specified root folder path.
---
--- Parameters:
--- * `rootPath` the path to the plugin's root folder.
---
--- Returns:
--- * The new `env` instance.
function env.new(rootPath)
    local o = {
        rootPath = rootPath,
    }
    return setmetatable(o, { __index = env })
end

--- cp.plugins.env:pathToAbsolute(resourcePath) -> string
--- Method
--- Returns the absolute path to the file referred to by the relative resource path. If an image is stored as `images/my.jpg` in the plugin, the resource path will be `"images/my.jpg"`. The result will be the full path to that file. If the file cannot be found in the plugin, it will look in the `cp/resources/assets` folder for globally-shared resources.
---
--- Parameters:
--- * `resourcePath`	- The local path to the resource inside the plugin.
---
--- Returns:
--- * The absolute path to the resource, or `nil` if it does not exist.
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

--- cp.plugins.env:pathToURL(resourcePath) -> string
--- Method
--- Returns an absolute `file://` URL to the file referred to by the relative resource path. If an image is stored as `images/my.jpg` in the plugin, the resource path will be `"images/my.jpg"`. The result will be a URL to that file. If the file cannot be found in the plugin, it will look in the `cp/resources/assets` folder for globally-shared resources.
---
--- Parameters:
--- * `resourcePath`	- The local path to the resource inside the plugin.
---
--- Returns:
--- * The absolute URL to the resource, or `nil` if it does not exist.
function env:pathToURL(resourcePath)
    local path = self:pathToAbsolute(resourcePath)
    if path then
        return "file://" .. path
    else
        return nil
    end
end

--- cp.plugins.env:readResource(resourcePath) -> string
--- Method
--- Reads the contents of the resource at the specified resource path. This is returned as a string of data (which may or may not be an actual readable string, depending on the source content).
---
--- Parameters:
--- * `resourcePath`	- The local path to the resource inside the plugin.
---
--- Returns:
--- * The contents of the resouce, or `nil` if the file does not exist.
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

--- cp.plugins.env:compileTemplate(view[, layout]) -> function
--- Method
--- Compiles a Resty Template within the context of the plugin. The `view` may be a resource path pointing at a template file in the plugin, or may be raw template markup. The `layout` is an optional path/template for a layout template. See the [Resty Template](https://github.com/bungle/lua-resty-template) documentation for details.
---
--- It returns a function which can have a `model` table passed in which will provide variables/functions/etc that the template can access while rendering. The function can be reused multiple times with different context values.
---
--- Parameters:
--- * `view`	- The local path inside the plugin to the template file, or raw template markup.
--- * `layout`	- The local path inside the plugin to the layout file.
---
--- Returns:
--- * A function which will render the template.
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
        local content, e = result(...)
        template.load = oldLoad
        return content, e
    end
end

--- cp.plugins.env:renderTemplate(view[, model[, layout]]) -> string
--- Method
--- Renders a Resty Template within the context of the plugin. The `view` may be a resource path pointing at a template file in the plugin, or may be raw template markup. The `layout` is an optional path/template for a layout template. See the [Resty Template](https://github.com/bungle/lua-resty-template) documentation for details.
---
--- The `model` is a table which will provide variables/functions/etc that the template can access while rendering.
---
--- Parameters:
--- * `view`	- The local path inside the plugin to the template file, or raw template markup.
--- * `model`	- The model which provides variables/functions/etc to the template.
--- * `layout`	- The local path inside the plugin to the layout file.
---
--- Returns:
--- * A function which will render the template.
function env:renderTemplate(view, model, layout)
    return self:compileTemplate(view, layout)(model)
end

return env
