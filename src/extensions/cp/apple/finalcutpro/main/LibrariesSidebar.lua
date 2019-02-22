-- local log                       = require "hs.logger" .new "LibrariesSidebar"

local axutils	                = require "cp.ui.axutils"
local ScrollArea	            = require "cp.ui.ScrollArea"
local Outline	                = require "cp.ui.Outline"

local cache, childMatching      = axutils.cache, axutils.childMatching

local LibrariesSidebar = ScrollArea:subclass("cp.apple.finalcutpro.main.LibrariesSidebar")

function LibrariesSidebar:initialize(parent)
    return ScrollArea.initialize(self, parent, parent.mainGroupUI:mutate(function(original)
        return childMatching(original(), LibrariesSidebar.matches)
    end))
end

function LibrariesSidebar.lazy.method:contents()
    return Outline(self, self.UI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return childMatching(ui, Outline.matches)
        end, Outline.matches)
    end))
end

function LibrariesSidebar:selectLibrary(path)
    return self:table():selectRow(path)
end

function LibrariesSidebar:selectedRowsUI()
    return self:table():selectedRowsUI()
end

return LibrariesSidebar