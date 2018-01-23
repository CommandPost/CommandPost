--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.KeywordEditor ===
---
--- Keyword Editor Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("keywordEditor")

local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local KeywordEditor = {}

--- cp.apple.finalcutpro.main.KeywordEditor:new(parent) -> KeywordEditor object
--- Method
--- Creates a new KeywordEditor object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A KeywordEditor object
function KeywordEditor:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, KeywordEditor)
end

--- cp.apple.finalcutpro.main.KeywordEditor:parent() -> table
--- Method
--- Returns the KeywordEditor's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function KeywordEditor:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.KeywordEditor:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function KeywordEditor:app()
	return self:parent():app()
end

function KeywordEditor:toolbarCheckBoxUI()
    return axutils.cache(self, "_toolbarCheckBoxUI", function()
        local primaryWindowUI = self:parent():primaryWindow():UI()
        if not primaryWindowUI then return nil end

        local toolbar = axutils.childWithRole(primaryWindowUI, "AXToolbar")
        if not toolbar then return nil end

        local group = axutils.childWithRole(toolbar, "AXGroup")
        if not group then return nil end

        local checkBox = axutils.childWithRole(group, "AXCheckBox")
        return checkBox
    end)
end

function KeywordEditor.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValueCount("AXChildren") == 6 or element:attributeValueCount("AXChildren") == 26
    end
	return false
end

function KeywordEditor:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:parent():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	KeywordEditor.matches)
end

function KeywordEditor:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if KeywordEditor.matches(window) then return window end
	end
	return nil
end

function KeywordEditor:isShowing()
    local checkBox = self:toolbarCheckBoxUI()
    return checkBox and checkBox:attributeValue("AXValue") == 1
end

function KeywordEditor:show()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 0 then
        checkBox:performAction("AXPress")
    end
end

function KeywordEditor:hide()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 1 then
        checkBox:performAction("AXPress")
    end
end

function KeywordEditor:keyword(value)
    local ui = self:UI()
    if type(value) == "nil" then
        --------------------------------------------------------------------------------
        -- Getter:
        --------------------------------------------------------------------------------
        local result = {}
        if ui and ui[1] and #ui[1]:attributeValue("AXChildren") > 0 then
            local children = ui[1]:attributeValue("AXChildren")
            for _, child in ipairs(children) do
                table.insert(result, child:attributeValue("AXValue"))
            end
            return result
        else
            log.ef("Could not get Keyword.")
            return nil
        end
    else
        --------------------------------------------------------------------------------
        -- Setter:
        --------------------------------------------------------------------------------
        if ui and ui[1] then
            ui[1]:setAttributeValue("AXValue", value)
            ui[1]:performAction("AXConfirm")
            return value
        else
            log.ef("Could not set Keyword.")
            return nil
        end
    end
end

--------------------------------------------------------------------------------
--
-- KEYBOARD SHORTCUTS:
--
--------------------------------------------------------------------------------
local KeyboardShortcuts = {}

function KeywordEditor:keyboardShortcuts()
    return KeyboardShortcuts:new(self)
end

function KeyboardShortcuts:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, KeyboardShortcuts)
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:parent() -> table
--- Method
--- Returns the KeywordShortcuts's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function KeyboardShortcuts:parent()
	return self._parent
end

function KeyboardShortcuts:isShowing()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    return disclosureTriangle and disclosureTriangle:attributeValue("AXValue") == 1
end

function KeyboardShortcuts:show()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    if disclosureTriangle:attributeValue("AXValue") == 0 then
        disclosureTriangle:performAction("AXPress")
    end
end

function KeyboardShortcuts:hide()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    if disclosureTriangle:attributeValue("AXValue") == 1 then
        disclosureTriangle:performAction("AXPress")
    end
end

function KeyboardShortcuts:keyword(item, value)
    if not item or type(item) ~= "number" or item <= 0 or item > 9 then
        log.ef("The keyboard shortcuts item must be between 1 and 9.")
        return nil
    end
    item = item + 1
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local textfields = axutils.childrenWith(ui, "AXRole", "AXTextField")
        if textfields and #textfields == 10 then
            if type(value) == "nil" then
                --------------------------------------------------------------------------------
                -- Getter:
                --------------------------------------------------------------------------------
                local result = {}
                if #textfields[item]:attributeValue("AXChildren") > 0 then
                    local children = textfields[item]:attributeValue("AXChildren")
                    for _, child in ipairs(children) do
                        table.insert(result, child:attributeValue("AXValue"))
                    end
                    return result
                else
                    log.ef("Could not get Keyword for Keyboard Shortcut %s", item)
                    return nil
                end
            else
                --------------------------------------------------------------------------------
                -- Setter:
                --------------------------------------------------------------------------------
                textfields[item]:attributeValue("AXValue", value)
                textfields[item]:performAction("AXConfirm")
            end
        end
    end
    return nil
end

function KeyboardShortcuts:apply(item)
    if not item or type(item) ~= "number" or item <= 0 or item > 9 then
        log.ef("The keyboard shortcuts item must be between 1 and 9.")
        return nil
    end
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local buttons = axutils.childrenWith(ui, "AXRole", "AXButton")
        if buttons and #buttons == 11 then
            buttons[item]:performAction("AXPress")
        else
            log.ef("Could not apply keywords.")
        end
    end
end

function KeyboardShortcuts:removeAllKeywords()
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local buttons = axutils.childrenWith(ui, "AXRole", "AXButton")
        if buttons and #buttons == 11 then
            buttons[10]:performAction("AXPress")
        else
            log.ef("Could not remove all keywords.")
        end
    end
end

return KeywordEditor