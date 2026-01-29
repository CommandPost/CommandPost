--- === cp.apple.finalcutpro.main.CompoundClipSheet ===
---
--- Represents the `New Compound Clip` [Sheet](cp.ui.Sheet.md) in Final Cut Pro.
---
--- Extends: [cp.ui.Sheet](cp.ui.Sheet.md)
--- Delegates To: [children](#children)

local require               = require

-- local log                   = require("hs.logger").new("CompoundClipSheet")

local strings               = require "cp.apple.finalcutpro.strings"
local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Button                = require "cp.ui.Button"
local Sheet                 = require "cp.ui.Sheet"
local StaticText            = require "cp.ui.StaticText"
local TextField             = require "cp.ui.TextField"
local PopUpButton           = require "cp.ui.PopUpButton"

local has                   = require "cp.ui.has"

local go                    = require "cp.rx.go"

local If                    = go.If
local WaitUntil             = go.WaitUntil

local chain                 = fn.chain
local get                   = fn.table.get
local filter                = fn.value.filter

local alias, list           = has.alias, has.list

local CompoundClipSheet = Sheet:subclass("cp.apple.finalcutpro.main.CompoundClipSheet")
                                :delegateTo("children", "method")

local COMPOUND_CLIP_NAME_KEY = "FFAnchoredSequenceSettingsModule_compoundClipLabel"

local function isCompoundClipName(value)
    return value == strings:find(COMPOUND_CLIP_NAME_KEY)
end

--- cp.apple.finalcutpro.main.CompoundClipSheet.matches(element) -> boolean
--- Function
--- Checks if the element is a `CompoundClipSheet`.
---
--- Parameters:
---  * element - An `axuielement` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
CompoundClipSheet.static.matches = ax.matchesIf(
    Sheet.matches,
    chain // ax.childrenTopDown >> get(1)
        >> filter(StaticText.matches)
        >> get "AXValue" >> isCompoundClipName
)

--- cp.apple.finalcutpro.main.CompoundClipSheet.children <cp.ui.has.UIHandler>
--- Constant
--- UI Handler for the children of the `CompoundClipSheet`.
CompoundClipSheet.static.children = list {
    StaticText, alias "compoundClipName" { TextField },
    StaticText, alias "inEvent" { PopUpButton },
    alias "cancel" { Button },
    alias "ok" { Button },
    has.ended
}

function CompoundClipSheet:initialize(parent)
    local ui = parent.UI:mutate(ax.childMatching(CompoundClipSheet.matches))

    Sheet.initialize(self, parent, ui, CompoundClipSheet.children)
end

--- cp.apple.finalcutpro.main.CompoundClipSheet.compoundClipName <cp.ui.TextField>
--- Field
--- The `TextField` for the Compound Clip Name.

--- cp.apple.finalcutpro.main.CompoundClipSheet.clipName <cp.ui.TextField>
--- Field
--- The `TextField` for the Clip Name.
function CompoundClipSheet.lazy.value:clipName()
    return self.compoundClipName
end

--- cp.apple.finalcutpro.main.CompoundClipSheet.inEvent <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "In Event" setting.

--------------------------------------------------------------------------------
-- Standard buttons
--------------------------------------------------------------------------------

-- NOTE: Skipping the "Cancel" button because [Sheet](cp.ui.Sheet.md) already defines one.

--- cp.apple.finalcutpro.main.CompoundClipSheet.ok <cp.ui.Button>
--- Field
--- The `Button` for the "Ok" button.

--------------------------------------------------------------------------------
-- Other Functions
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.CompoundClipSheet:doShow() <cp.rx.go.Statement>
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempt to show the sheet.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` object.
function CompoundClipSheet.lazy.method:doShow()
    local app = self:app()
    return If(app:doLaunch())
    :Then(app.browser)
    :Then(
        app.menu:doSelectMenu({"File", "New", "Compound Clip…"})
    )
    :Then(
        WaitUntil(self.isShowing):TimeoutAfter(2000)
    )
    :Otherwise(false)
    :Label("CompoundClipSheet:doShow")
end

--- cp.apple.finalcutpro.main.CompoundClipSheet:doHide() <cp.rx.go.Statement>
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempt to hide the sheet, if it is visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` object.
function CompoundClipSheet.lazy.method:doHide()
    return If(self.isShowing):Is(true):Then(
        self.cancel:doPress()
    )
    :Label("CompoundClipSheet:doHide")
end

return CompoundClipSheet