local log                       = require "hs.logger" .new "LibrariesSidebar"

local axutils	                = require "cp.ui.axutils"
local ScrollArea	            = require "cp.ui.ScrollArea"
local Table2	                = require "cp.ui.Table2"

local cache, childMatching      = axutils.cache, axutils.childMatching

local LibrariesSidebar = ScrollArea:subclass("cp.apple.finalcutpro.main.LibrariesSidebar")

function LibrariesSidebar:initialize(parent)
    return ScrollArea.initialize(self, parent, parent.mainGroupUI:mutate(function(original)
        return childMatching(original(), LibrariesSidebar.matches)
    end))
end

function LibrariesSidebar.lazy.method:table()
    assert(type(Table2.matches) == "function")
    return Table2(self, self.UI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return childMatching(ui, Table2.matches)
        end, Table2.matches)
    end))
end

function LibrariesSidebar:selectLibrary(path)
    return self:table():selectRow(path)
end

return LibrariesSidebar