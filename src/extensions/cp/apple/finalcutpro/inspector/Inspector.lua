--- === cp.apple.finalcutpro.inspector.Inspector ===
---
--- Inspector

local require               = require

local log                   = require "hs.logger".new "inspector"

local axutils               = require "cp.ui.axutils"
local Element               = require "cp.ui.Element"
local prop                  = require "cp.prop"

local strings               = require "cp.apple.finalcutpro.strings"

local AudioInspector        = require "cp.apple.finalcutpro.inspector.audio.AudioInspector"
local ColorInspector        = require "cp.apple.finalcutpro.inspector.color.ColorInspector"
local GeneratorInspector    = require "cp.apple.finalcutpro.inspector.generator.GeneratorInspector"
local InfoInspector         = require "cp.apple.finalcutpro.inspector.info.InfoInspector"
local InfoProjectInspector  = require "cp.apple.finalcutpro.inspector.info.InfoProjectInspector"
local ShareInspector        = require "cp.apple.finalcutpro.inspector.share.ShareInspector"
local TextInspector         = require "cp.apple.finalcutpro.inspector.text.TextInspector"
local TitleInspector        = require "cp.apple.finalcutpro.inspector.title.TitleInspector"
local TransitionInspector   = require "cp.apple.finalcutpro.inspector.transition.TransitionInspector"
local VideoInspector        = require "cp.apple.finalcutpro.inspector.video.VideoInspector"

local go                    = require "cp.rx.go"

local If                    = go.If
local Do                    = go.Do
local WaitUntil             = go.WaitUntil
local List                  = go.List
local Throw                 = go.Throw
local Given                 = go.Given
local Done                  = go.Done

local Inspector = Element:subclass("cp.apple.finalcutpro.inspector.Inspector")

--- cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS -> table
--- Constant
--- Table of supported Inspector Tabs
Inspector.static.INSPECTOR_TABS = {
    ["Audio"]       = "FFInspectorTabAudio",
    ["Color"]       = "FFInspectorTabColor",
    ["Effect"]      = "FFInspectorTabMotionEffectEffect",
    ["Generator"]   = "FFInspectorTabGenerator",
    ["Info"]        = "FFInspectorTabMetadata",
    ["Share"]       = "FFInspectorTabShare",
    ["Text"]        = "FFInspectorTabMotionEffectText",
    ["Title"]       = "FFInspectorTabMotionEffectTitle",
    ["Transition"]  = "FFInspectorTabMotionEffectTransition",
    ["Video"]       = "FFInspectorTabMotionEffectVideo",
}

--- cp.apple.finalcutpro.inspector.Inspector.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - axuielementObject
---
--- Returns:
---  * `true` if matches otherwise `false`
function Inspector.static.matches(element)
    local children = axutils.children(element)
    local groups = axutils.childrenWith(element, "AXRole", "AXGroup")
    return (children and #children == 3 and groups and #groups == 3) -- is inspecting
        or axutils.childWith(element, "AXValue", strings:find("Nothing to Inspect")) ~= nil -- nothing to inspect
end

--- cp.apple.finalcutpro.inspector.Inspector(parent) -> Inspector
--- Constructor
--- Creates a new Inspector.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * The Inspector object.
function Inspector:initialize(parent)
    local UI = prop(function()
        return axutils.cache(self, "_ui",
        function()
            local ui = parent:rightGroupUI()
            if ui then
                -----------------------------------------------------------------------
                -- It's in the right panel (full-height):
                -----------------------------------------------------------------------
                if Inspector.matches(ui) then
                    return ui
                end
            else
                -----------------------------------------------------------------------
                -- It's in the top-right panel (half-height):
                -----------------------------------------------------------------------
                local top = parent:topGroupUI()
                if top then
                    for _,child in ipairs(top) do
                        if Inspector.matches(child) then
                            return child
                        end
                    end
                end
            end
            return nil
        end,
        Inspector.matches)
    end)

    Element.initialize(self, parent, UI)

    UI:preWatch(function()
        self:app():notifier():watchFor({"AXUIElementDestroyed", "AXValueChanged"}, function()
            UI:update()
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.topBarUI <cp.prop: hs.axuielement; read-only>
--- Field
--- Returns the "top bar" `axuielement` for the Inspector.
function Inspector.lazy.prop:topBarUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_topBar", function()
            local ui = original()
            return ui and #ui == 3 and axutils.childFromTop(ui, 1) or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.panelUI <cp.prop: hs.axuielement; read-only>
--- Field
--- Returns the central panel `axuielement` for the Inspector.
function Inspector.lazy.prop:panelUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_panel",
            function()
                local ui = original()
                if ui then
                    local groups = axutils.childrenWithRole(ui, "AXGroup")
                    if groups and #groups == 3 then
                        return axutils.childFromTop(groups, 2)
                    end
                end
                return nil
            end,
            function(element) return element:attributeValue("AXRole") == "AXGroup" end
        )
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.propertiesUI <cp.prop: hs.axuielement; read-only>
--- Field
--- Returns the properties `axuielement` for the Inspector. This contains the rows of property values.
function Inspector.lazy.prop:propertiesUI()
    return self.panelUI:mutate(function(original)
        return axutils.cache(self, "_properties", function()
            local ui = original()
            if ui then
                return (
                    axutils.childWithRole(ui, "AXScrollArea") -- 10.4+ Inspector
                    or nil -- not found
                )
            end
            return nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.bottomBarUI <cp.prop: hs.axuielement; read-only>
--- Field
--- Returns the bottom bar `axuielement` for the Inspector.
function Inspector.lazy.prop:bottomBarUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_bottomBar", function()
            local ui = original()
            return ui and #ui == 3 and axutils.childFromBottom(ui, 1) or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.labelUI <cp.prop: hs.axuielement; read-only>
--- Field
--- Returns the `axuielement` for text label at the top of the Inspector.
function Inspector.lazy.prop:labelUI()
    return self.topBarUI:mutate(function(original)
        local ui = original()
        return axutils.childWithRole(ui, "AXStaticText")
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the Inspector is showing otherwise `false`
function Inspector.lazy.prop:isShowing()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui ~= nil
    end)
end

--- cp.apple.finalcutpro.inspector.Inspector.isFullHeight <cp.prop: boolean>
--- Field
--- Returns `true` if the Inspector is full height.
function Inspector.lazy.prop:isFullHeight()
    return prop(
        function()
            return Inspector.matches(self:parent():rightGroupUI())
        end,
        function(newValue, _, thisProp)
            self:show()
            local currentValue = thisProp:get()
            if newValue ~= currentValue then
                self:app().menu:selectMenu({"View", "Toggle Inspector Height"})
            end
        end
    )
end

-----------------------------------------------------------------------
--
-- INSPECTOR UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:show([tab]) -> Inspector
--- Method
--- Shows the inspector.
---
--- Parameters:
---  * [tab] - A string from the `cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * The `Inspector` instance.
---
--- Notes:
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:show(tab)
    if tab and Inspector.INSPECTOR_TABS[tab] then
        self:selectTab(tab)
    else
        local parent = self:parent()
        -----------------------------------------------------------------------
        -- Show the parent:
        -----------------------------------------------------------------------
        if parent and parent:show() and parent:show():isShowing() and not self:isShowing() then
            local menuBar = self:app().menu
            -----------------------------------------------------------------------
            -- Enable it in the primary:
            -----------------------------------------------------------------------
            if menuBar then
                menuBar:selectMenu({"Window", "Show in Workspace", "Inspector"})
            end
        end
    end
    return self
end

--- cp.apple.finalcutpro.inspector.Inspector:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the `Inspector`.
---
--- Returns:
--- * The `Statement`, resolving to `true` if the Inspector was shown successfully, or an error if not.
function Inspector.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:parent():doShow())
    :Then(self:app().menu:doSelectMenu({"Window", "Show in Workspace", "Inspector"}))
    :Then(WaitUntil(self.isShowing):TimeoutAfter(5000))
    :Otherwise(true)
    :Label("Inspector:doShow")
end

--- cp.apple.finalcutpro.inspector.Inspector:hide() -> Inspector
--- Method
--- Hides the inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Inspector` instance.
function Inspector:hide()
    if self:isShowing() then
        local menuBar = self:app().menu
        -- Uncheck it from the primary workspace
        menuBar:selectMenu({"Window", "Show in Workspace", "Inspector"})
    end
    return self
end

--- cp.apple.finalcutpro.inspector.Inspector:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to hide the `Inspector`.
---
--- Returns:
--- * The `Statement`, resolving to `true` if the Inspector was hidden successfully, or an error if not.
function Inspector.lazy.method:doHide()
    return If(self.isShowing):Is(true)
    :Then(self:app().menu:doSelectMenu({"Window", "Show in Workspace", "Inspector"}))
    :Then(WaitUntil(self.isShowing:NOT()):TimeoutAfter(5000))
    :Otherwise(true)
    :Label("Inspector:doHide")
end

--- cp.apple.finalcutpro.inspector.Inspector:selectTab(tab) -> boolean
--- Method
--- Selects a tab in the inspector.
---
--- Parameters:
---  * tab - A string from the `cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if an error occurred.
---
--- Notes:
---  * This method will open the Inspector if it's closed, and leave it open.
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectTab(value)
    local code = Inspector.INSPECTOR_TABS[value]
    if not code then
        log.ef("selectTab requires a valid tab string: %s", value)
        return false
    end
    self:show()
    if not self.isShowing() then
        log.ef("Failed to open Inspector")
        return false
    end
    local ui = self:topBarUI()
    local valueTitle = strings:find(code)
    if not valueTitle then
        log.ef("Inspector:selectTab: unable to find string for tab code %q", code)
        return false
    end
    for _,subChild in ipairs(ui) do
        local title = subChild:attributeValue("AXTitle")
        if title == valueTitle then
            return subChild:performAction("AXPress")
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.Inspector:doFindTabButton(type) -> cp.rx.go.Statement
--- Method
--- Finds the named Inspector tab button, or sends an error if the type is unsupported.
---
--- Parameters:
--- * type - the type of the button to return. (e.g. "Video")
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) to execute.
---
--- Notes:
---  * Valid strings for `type` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
--- * Not all button types are available in all contexts.
function Inspector:doFindTabButton(type)
    local code = Inspector.INSPECTOR_TABS[type]
    if not code then
        return Throw("Invalid Inspector Tab: %s", type)
    end
    local localTitle = self:app():string(code)

    return Given(List(self.topBarUI))
    :Then(function(child)
        if child:attributeValue("AXTitle") == localTitle then
            return child
        end
        return Done()
    end)
    :Label("Inpector:doFindTabButton")
end

--- cp.apple.finalcutpro.inspector.Inspector:doSelectTab(title) -> cp.rx.go.Statement
--- Method
--- A Statement that selects the specified tab title.
---
--- Parameters:
--- * title     - The title of the tab to select.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function Inspector:doSelectTab(title)
    return Do(self:doShow())
    :Then(
        If(self:doFindTabButton(title))
        :Then(function(button)
            button:doAXPress()
            return true
        end)
        :Otherwise(false)
    )
    :Label("Inspector:doSelectTab")
end

--- cp.apple.finalcutpro.inspector.Inspector:tabAvailable(tab) -> boolean
--- Method
--- Checks to see if a tab is currently available in the Inspector.
---
--- Parameters:
---  * tab - A string from the `cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * `true` if available otherwise `false`.
---
--- Notes:
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:tabAvailable(value)
    local code = Inspector.INSPECTOR_TABS[value]
    if not code then
        log.ef("selectTab requires a valid tab string: %s", value)
        return false
    end
    self:show()
    if not self.isShowing() then
        log.ef("Failed to open Inspector")
        return false
    end
    local ui = self:topBarUI()
    local app = self:app()
    local valueTitle = app:string(code)
    for _,subChild in ipairs(ui) do
        local title = subChild:attributeValue("AXTitle")
        if title == valueTitle then
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.Inspector:selectedTab() -> string or nil
--- Method
--- Returns the name of the selected inspector tab otherwise `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if the Inspector is closed or an error occurred.
---
--- Notes:
---  * The tab strings can be:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectedTab()
    local ui = self:topBarUI()
    if ui then
        local app = self:app()
        for _,child in ipairs(ui) do
            if child:attributeValue("AXValue") == 1 then
                local title = child:attributeValue("AXTitle")
                if title then
                    for value,code in pairs(Inspector.INSPECTOR_TABS) do
                        local codeTitle = app:string(code)
                        if codeTitle == title then
                            return value
                        end
                    end
                end
            end
        end
    end
    return nil
end

-----------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.video <cp.apple.finalcutpro.inspector.VideoInspector>
--- Field
--- The [VideoInspector](cp.apple.finalcutpro.inspector.VideoInspector.md).
function Inspector.lazy.value:video()
    return VideoInspector(self)
end

-----------------------------------------------------------------------
--
-- GENERATOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.generator <cp.apple.finalcutpro.inspector.GeneratorInspector>
--- Field
--- The [GeneratorInspector](package.GeneratorInspector.md)
function Inspector.lazy.value:generator()
    return GeneratorInspector(self)
end

-----------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.info <cp.apple.finalcutpro.inspector.InfoInspector>
--- Field
--- The  [InfoInspector](cp.apple.finalcutpro.inspector.InfoInspector.md).
function Inspector.lazy.value:info()
    return InfoInspector(self)
end

--- cp.apple.finalcutpro.inspector.Inspector.projectInfo <cp.apple.finalcutpro.inspector.InfoProjectInspector>
--- Field
--- The  [InfoProjectInspector](cp.apple.finalcutpro.inspector.InfoProjectInspector.md).
function Inspector.lazy.value:projectInfo()
    return InfoProjectInspector(self)
end

-----------------------------------------------------------------------
--
-- TEXT INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.text <cp.apple.finalcutpro.inspector.TextInspector
--- Field
--- The [TextzInspector](cp.apple.finalcutpro.inspector.TextzInspector.md).
function Inspector.lazy.value:text()
    return TextInspector(self)
end

-----------------------------------------------------------------------
--
-- TITLE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.title <cp.apple.finalcutpro.inspector.TitleInspector>
--- Field
--- The [TitleInspector](cp.apple.finalcutpro.inspector.TitleInspector.md).
function Inspector.lazy.value:title()
    return TitleInspector(self)
end

-----------------------------------------------------------------------
--
-- TRANSITION INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.transition <cp.apple.finalcutpro.inspector.TransitionInspector>
--- Field
--- The [TransitionInspector](cp.apple.finalcutpro.inspector.TransitionInspector.md).
function Inspector.lazy.value:transition()
    return TransitionInspector(self)
end

-----------------------------------------------------------------------
--
-- AUDIO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.audio <cp.apple.finalcutpro.inspector.AudioInspector>
--- Field
--- The [AudioInspector](cp.apple.finalcutpro.inspector.AudioInspector.md).
function Inspector.lazy.value:audio()
    return AudioInspector(self)
end

-----------------------------------------------------------------------
--
-- SHARE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.share <cp.apple.finalcutpro.inspector.ShareInspector>
--- Field
--- The [ShareInspector](cp.apple.finalcutpro.inspector.ShareInspector.md).
function Inspector.lazy.value:share()
    return ShareInspector(self)
end

-----------------------------------------------------------------------
--
-- COLOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector.color <cp.apple.finalcutpro.inspector.ColorInspector>
--- Field
--- The [ColorInspector](cp.apple.finalcutpro.inspector.ColorInspector.md).
function Inspector.lazy.value:color()
    return ColorInspector(self)
end

return Inspector
