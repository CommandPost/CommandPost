--- === cp.highland2 ===
---
--- Highland 2 support.

local require                                   = require

local class                                     = require "middleclass"
local lazy                                      = require "cp.lazy"
local delegator                                 = require "cp.delegator"
local tools                                     = require "cp.tools"

local app                                       = require "cp.highland2.app"
local Document                                  = require "cp.highland2.Document"

local tableFilter                               = tools.tableFilter

local highland2 = class("cp.highland2")
    :include(lazy)
    :include(delegator)
    :delegateTo("app", "menu")

function highland2.lazy.value.app()
    return app
end

--- cp.highland2.focusedDocument <cp.prop: cp.highland2.Document>
--- Field
--- The currently-focused [Document](cp.highland2.Document.md), if applicable.
function highland2.lazy.prop:focusedDocument()
     return self.app.focusedWindow:mutate(function(original)
        local window = original()
        if window and window:isInstanceOf(Document) then
            return window
        end
    end)
end

function highland2.lazy.prop:documents()
    return self.app.windows:mutate(function(original)
        local windows = original()
        if windows then
            tableFilter(windows, function(t, i)
                return t[i]:isInstanceOf(Document)
            end)
        end
        return windows
    end)
end

return highland2()