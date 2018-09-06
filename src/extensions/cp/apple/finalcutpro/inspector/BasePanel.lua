--- === cp.apple.finalcutpro.inspector.BasePanel ===
---
--- A base class for the different panels in the [Inspector](cp.apple.finalcutpro.inspector.Inspector.md).
---
--- Extends [Element](cp.ui.Element.md).

local axutils                       = require("cp.ui.axutils")
local Element                       = require("cp.ui.Element")

local If                            = require("cp.rx.go.If")

local cache                         = axutils.cache

local BasePanel = Element:subclass("cp.apple.finalcutpro.inspector.BasePanel")

--- cp.apple.finalcutpro.inspector.BasePanel(parent, panelType) -> BasePanel
--- Constructor
--- Constructs the panel, initialising the parent and the [UI](cp.ui.Element.md#UI).
---
--- Parameters:
--- * parent        - The parent [Element](cp.ui.Element.md).
--- * panelType     - The panel type string, as defined in [Inspector.INSPECTOR_TABS](cp.apple.finalcutpro.inspector.Inspector.md#INSPECTOR_TABS).
---
--- Returns:
--- * The new `BasePanel` instance.
function BasePanel:initialize(parent, panelType)
    local UI = parent.panelUI:mutate(function(original)
        return cache(self, "_ui",
            function()
                local ui = original()
                return self.class.matches(ui) and ui or nil
            end,
            self.class.matches
        )
    end)
    Element.initialize(self, parent, UI)

    self._panelType = panelType
end

--- cp.apple.finalcutpro.inspector.BasePanel:panelType() -> string
--- Method
--- Gets the type of panel this is.
---
--- Returns:
--- * The panel type identifier.
function BasePanel:panelType()
    return self._panelType
end

--- cp.apple.finalcutpro.inspector.BasePanel:show() -> none
--- Method
--- Shows the panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function BasePanel:show()
    if not self:isShowing() then
        self:parent():selectTab(self:panelType())
    end
    return self
end

--- cp.apple.finalcutpro.inspector.BasePanel:doShow() -> cp.rx.go.Statment
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful and sending an error if not.
function BasePanel.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doSelectTab("Info")
    ):Otherwise(true)
    :Label(self:panelType() .. ":doShow")
end

--- cp.apple.finalcutpro.inspector.BasePanel:hide() -> none
--- Method
--- Hides the panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function BasePanel:hide()
    if self:isShowing() then
        self:parent():hide()
    end
    return self
end

--- cp.apple.finalcutpro.inspector.BasePanel:doShow() -> cp.rx.go.Statment
--- Method
--- A [Statement](cp.rx.go.Statement.md) that hides the panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful and sending an error if not.
function BasePanel.lazy.method:doHide()
    return If(self.isShowing)
    :Then(
        self:parent():doHide()
    )
    :Label(self:panelType() .. ":doHide")
end

return BasePanel