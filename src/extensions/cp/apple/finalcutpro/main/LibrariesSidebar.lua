local log                       = require "hs.logger" .new "LibrariesSidebar"

local axutils	                = require "cp.ui.axutils"
local ScrollArea	            = require "cp.ui.ScrollArea"
local Table2	                = require "cp.ui.Table2"

local cache, childMatching      = axutils.cache, axutils.childMatching

local LibrariesSidebar = ScrollArea:subclass("cp.apple.finalcutpro.main.LibrariesSidebar")

function LibrariesSidebar.lazy.method:table()
    assert(type(Table2.matches) == "function")
    return Table2(self, self.UI:mutate(function(original)
        return cache(self, "_ui", function()
            log.df("table: Table2.matches type = %s", type(Table2.matches))
            return childMatching(original(), Table2.matches)
        end, Table2.matches)
    end))
end

function LibrariesSidebar:selectLibrary(path)
    return self:table():selectRow(path)
end

return LibrariesSidebar