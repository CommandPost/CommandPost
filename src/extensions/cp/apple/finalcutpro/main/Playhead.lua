--- === cp.apple.finalcutpro.main.Playhead ===
---
--- Playhead Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("fcpPlayhead")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap                          = require("hs.eventtap")
local geometry                          = require("hs.geometry")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local just                              = require("cp.just")
local prop                              = require("cp.prop")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Playhead = {}

--- cp.apple.finalcutpro.main.Playhead.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Playhead or not
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the Playhead otherwise `false`
function Playhead.matches(element)
    return element and element:attributeValue("AXRole") == "AXValueIndicator"
end

--- cp.apple.finalcutpro.main.Playhead.find(containerUI, skimming) -> hs._asm.axuielement object | nil
--- Function
--- Finds the playhead (either persistent or skimming) in the specified container. Defaults to persistent.
---
--- Parameters:
---  * `containerUI` - The container UI
---  * `skimming` - Whether or not you want the skimming playhead as boolean.
---
--- Returns:
---  * The playhead `hs._asm.axuielement` object or `nil` if not found.
function Playhead.find(containerUI, skimming)
    local ui = containerUI
    if ui and #ui > 0 then
        --------------------------------------------------------------------------------
        -- The playhead is typically one of the last two children:
        --------------------------------------------------------------------------------
        local persistentPlayhead = ui[#ui-1]
        local skimmingPlayhead = ui[#ui]
        if not Playhead.matches(persistentPlayhead) then
            persistentPlayhead = skimmingPlayhead
            skimmingPlayhead = nil
            if Playhead.matches(skimmingPlayhead) then
                persistentPlayhead = nil
            end
        end
        if skimming then
            return skimmingPlayhead
        else
            return persistentPlayhead
        end
    end
    return nil
end

--- cp.apple.finalcutpro.main.Playhead.new(parent, skimming, containerFn) -> Playhead
--- Constructor
--- Constructs a new Playhead
---
--- Parameters:
---  * parent        - The parent object
---  * skimming      - (optional) if `true`, this links to the 'skimming' playhead created under the mouse, if present.
---  * containerFn   - (optional) a function which returns the container axuielement which contains the playheads. If not present, it will use the parent's UI element.
---
--- Returns:
---  * The new `Playhead` instance.
function Playhead.new(parent, skimming, containerFn)
    local o = {_parent = parent, _skimming = skimming, containerUI = containerFn}
    return prop.extend(o, Playhead)
end

--- cp.apple.finalcutpro.main.Playhead:parent() -> table
--- Method
--- Returns the Playhead's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function Playhead:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.Playhead:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function Playhead:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Playhead:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function Playhead:UI()
    return axutils.cache(self, "_ui", function()
        local ui = self.containerUI and self:containerUI() or self:parent():UI()
        return Playhead.find(ui, self:isSkimming())
    end,
    Playhead.matches)
end

--- cp.apple.finalcutpro.main.Playhead.isPersistent <cp.prop: boolean>
--- Field
--- Is the playhead persistent?
Playhead.isPersistent = prop.new(function(self)
    return not self._skimming
end):bind(Playhead)

--- cp.apple.finalcutpro.main.Playhead.isSkimming <cp.prop: boolean>
--- Field
--- Is the playhead skimming?
Playhead.isSkimming = prop.new(function(self)
    return self._skimming == true
end):bind(Playhead)

--- cp.apple.finalcutpro.main.Playhead.isShowing <cp.prop: boolean>
--- Field
--- Is the playhead showing?
Playhead.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(Playhead)

--- cp.apple.finalcutpro.main.Playhead:show() -> Playhead object
--- Method
--- Shows the Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * Playhead object
function Playhead:show()
    local parent = self:parent()
    -----------------------------------------------------------------------
    -- Show the parent:
    -----------------------------------------------------------------------
    if parent:show():isShowing() then
        -----------------------------------------------------------------------
        -- Ensure the playhead is visible:
        -----------------------------------------------------------------------
        if parent.viewFrame then
            local viewFrame = parent:viewFrame()
            local position = self:getPosition()
            if position < viewFrame.x or position > (viewFrame.x + viewFrame.w) then
                -----------------------------------------------------------------------
                -- Need to move the scrollbar:
                -----------------------------------------------------------------------
                local timelineFrame = parent:timelineFrame()
                local scrollWidth = timelineFrame.w - viewFrame.w
                local scrollPoint = position - viewFrame.w/2 - timelineFrame.x
                local scrollTarget = scrollPoint/scrollWidth
                parent:scrollHorizontalTo(scrollTarget)
            end
        end
    end
    return self
end

--- cp.apple.finalcutpro.main.Playhead:hide() -> Playhead object
--- Method
--- Hides the Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * Playhead object
function Playhead:hide()
    self:parent():hide()
    return self
end

--- cp.apple.finalcutpro.main.Playhead:getTimecode() -> string
--- Method
--- Gets the timecode of the current playhead position.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Timecode value as string.
function Playhead:getTimecode()
    local ui = self:UI()
    return ui and ui:attributeValue("AXValue")
end

--- cp.apple.finalcutpro.main.Playhead:setTimecode(timecode) -> Playhead object | nil
--- Method
--- Moves the playhead to a specific timecode value.
---
--- Parameters:
---  * timecode - The timecode value you want to move to as a string in the following format: "hh:mm:ss:ff" or "hh:mm:ss;ff" (i.e. "01:00:00:00").
---
--- Returns:
---  * Playhead object is successful otherwise `nil`
function Playhead:setTimecode(timecode)
    if timecode and (string.find(timecode, "%d%d:%d%d:%d%d:%d%d") or string.find(timecode, "%d%d:%d%d:%d%d;%d%d")) then
        timecode = string.gsub(timecode, ":", "")
        timecode = string.gsub(timecode, ";", "")
        local app = self:app()
        local viewer = app:viewer()
        local bottomToolbarUI = viewer:bottomToolbarUI()
        if bottomToolbarUI then
            local buttons = axutils.childrenWithRole(bottomToolbarUI, "AXButton")
            if buttons then
                local movePlayheadButton = buttons[1]
                if movePlayheadButton then
                    local frame = movePlayheadButton:attributeValue("AXFrame")
                    if frame then
                        local centre = geometry(frame).center
                        if centre then
                            --------------------------------------------------------------------------------
                            -- Double click the timecode value in the Viewer:
                            --------------------------------------------------------------------------------
                            tools.ninjaMouseClick(centre)

                            --------------------------------------------------------------------------------
                            -- Wait until the click has been registered (give it 3 seconds):
                            --------------------------------------------------------------------------------
                            local result = just.doUntil(function()
                                local timecodeText = axutils.childrenWithRole(bottomToolbarUI, "AXStaticText")
                                if timecodeText and timecodeText[1] and timecodeText[1]:attributeValue("AXValue") and (timecodeText[1]:attributeValue("AXValue") == "00:00:00:00" or timecodeText[1]:attributeValue("AXValue") == "00:00:00;00") then
                                    return true
                                else
                                    return false
                                end
                            end, 3)
                            if result then
                                --------------------------------------------------------------------------------
                                -- Type in Original Timecode & Press Return Key:
                                --------------------------------------------------------------------------------
                                eventtap.keyStrokes(timecode)
                                eventtap.keyStroke({}, 'return')
                                return self
                            end
                        end
                    end
                end
            end
        end
    else
        log.ef("Timecode value is invalid: %s", timecode)
    end
    return nil
end

--- cp.apple.finalcutpro.main.Playhead:getX() -> number
--- Method
--- Gets the `x` position of the playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `x` position as number.
function Playhead:getX()
    local ui = self:UI()
    return ui and ui:position().x
end

--- cp.apple.finalcutpro.main.Playhead:getFrame() -> hs.geometry.frame
--- Method
--- Gets the frame of the playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The playhead frame.
function Playhead:getFrame()
    local ui = self:UI()
    return ui and ui:frame()
end

--- cp.apple.finalcutpro.main.Playhead:getPosition() -> number
--- Method
--- Gets the position of the playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The playhead position as a number.
function Playhead:getPosition()
    local frame = self:getFrame()
    return frame and (frame.x + frame.w/2 + 1.0)
end

--- cp.apple.finalcutpro.main.Playhead:getCenter() -> hs.geometry.point
--- Method
--- Gets the centre of the playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The playhead centre position as a `hs.geometry.point`.
function Playhead:getCenter()
    local frame = self:getFrame()
    return frame and geometry.rect(frame).center
end

return Playhead
