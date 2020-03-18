--- === hs._coresetup.loader ===
---
--- A dynamic extension loader.

local require       = require
local fs            = require "hs.fs"
local insert        = table.insert

local PATH = {}
local ID = {}

local loader = {}
loader.mt = {}

function loader.extend(value, id, path)
    value[ID] = id
    value[PATH] = path
    return setmetatable(value, loader.mt)
end

--- hs._coresetup.loader(id, path) -> hs._coresetup.loader
--- Constructor
--- Initialises the loader.
---
--- Parameters:
--- * id - The full extension id up to this value. Eg. "cp"
--- * path - The full path pointing to this extension to search for directories. Eg. "/Applications/CommandPost.app/Resources/extensions/cp".
function loader.new(id, path)
    return loader.extend({}, id, path)
end

--- hs._coresetup.loader.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `loader` instance.
---
--- Parameters:
--- * thing - The thing to check.
---
--- Returns:
--- * `true` if it is, `false` otherwise.
function loader.is(thing)
    return type(thing) == "table" and getmetatable(thing) == loader.mt
end

--- hs._coresetup.loader.availableExtensions(aLoader) -> table
--- Function
--- Returns the list of all extensions available under the given loader, even if they haven't been loaded yet, as a list of strings with values local to this loader.
--- This does **not** include the prefix of the loader itself. For example, if your module is `"foo"`, and there is an
--- extension called `"foo.bar"`, the table will be `{ "bar" }`, not `{ "foo.bar" }`.
---
--- Parameters:
--- * aLoader - the loader to check.
---
--- Returns:
--- * `table` with a list of strings of extensions under this loader.
function loader.availableExtensions(aLoader)
    assert(loader.is(aLoader), "Please provide a `loader` instance.")

    local loaderPath = aLoader[PATH]
    local result = {}

    for file in fs.dir(aLoader[PATH]) do
        local filePath = loaderPath .. "/" .. file
        local fileMode = fs.attributes(filePath, "mode")
        if fileMode == "directory" and file ~= "." and file ~= ".." then
            insert(result, file)
        elseif fileMode == "file" then
            local module = file:match("^(.*)%.lua$")
            if module then
                insert(result, module)
            end
        end
    end

    return result
end

function loader.mt:__index(key)
    local fullId = self[ID] .. "." .. key
    local idPath = package.searchpath(fullId, package.path)

    if idPath then -- there is an extension for it already.
        print("-- Loading extension: " .. fullId)
        rawset(self, key, require(fullId))
    else
        local keyPath = self[PATH] .. "/" .. key
        if fs.attributes(keyPath, "mode") == "directory" then
            -- it's a directory but not a module. Set up another loader.
            rawset(self, key, loader(fullId, keyPath))
        end
    end

    return rawget(self, key)
end

function loader.mt:__pairs()
    local available = loader.availableExtensions(self)
    table.sort(available)
    return pairs(available)
end

function loader.mt:__tostring()
    return "extension: " .. self[ID]
end

setmetatable(loader, {
    __call = function(self, ...)
        return self.new(...)
    end
})

return loader

