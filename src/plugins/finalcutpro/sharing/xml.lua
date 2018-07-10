--- === plugins.finalcutpro.sharing.xml ===
---
--- Shared XML Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("sharingxml")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                                        = require("hs.fs")
local host                                      = require("hs.host")
local notify                                    = require("hs.notify")
local pathwatcher                               = require("hs.pathwatcher")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY                                  = 4000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.mousezoom.enabled <cp.prop: boolean>
--- Variable
--- Is the module enabled?
mod.enabled = config.prop("enableXMLSharing", false)

--- plugins.finalcutpro.timeline.mousezoom.enabled <cp.prop: string>
--- Variable
--- Shared XML Path
mod.sharingPath = config.prop("xmlSharingPath")

--- plugins.finalcutpro.sharing.xml.clearSharedFiles() -> none
--- Function
--- Clear shared files list.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clearSharedFiles()
    local xmlSharingPath = mod.sharingPath()
    for folder in fs.dir(xmlSharingPath) do
        if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then
            for file in fs.dir(xmlSharingPath .. "/" .. folder) do
                if file:sub(-7) == ".fcpxml" then
                    os.remove(xmlSharingPath .. folder .. "/" .. file)
                end
            end
        end
    end
    --------------------------------------------------------------------------------
    -- Reset Cache:
    --------------------------------------------------------------------------------
    mod._filesMenuCache = nil
end

--- plugins.finalcutpro.sharing.xml.listFilesMenu() -> none
--- Function
--- List files menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.listFilesMenu()
    if not mod.enabled() then
        return nil
    end

    if mod._filesMenuCache ~= nil then
        --log.df("Using XML Sharing Menu Cache")
        return mod._filesMenuCache
    else
        --------------------------------------------------------------------------------
        -- Shared XML Menu:
        --------------------------------------------------------------------------------
        local menu = {}
        --------------------------------------------------------------------------------
        -- Get list of files:
        --------------------------------------------------------------------------------
        local emptySharedXMLFiles = true
        local xmlSharingPath = mod.sharingPath()

        --------------------------------------------------------------------------------
        -- If the XML Sharing Path Exists:
        --------------------------------------------------------------------------------
        if xmlSharingPath and tools.doesDirectoryExist(xmlSharingPath) then

            local fcpxRunning = fcp:isRunning()

            for folder in fs.dir(xmlSharingPath) do

                if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) and folder ~= "." and folder ~= ".." then

                    local submenu = {}
                    for file in fs.dir(xmlSharingPath .. "/" .. folder) do
                        if file:sub(-7) == ".fcpxml" then
                            emptySharedXMLFiles = false
                            local xmlPath = xmlSharingPath .. folder .. "/" .. file

                            local attributes = fs.attributes(xmlPath)
                            local creation
                            if attributes then
                                creation = attributes["creation"]
                            end
                            table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp:importXML(xmlPath) end, disabled = not fcpxRunning, creation = creation})
                        end
                    end
                    --------------------------------------------------------------------------------
                    -- Sort table by creation date:
                    --------------------------------------------------------------------------------
                    table.sort(submenu, function(a, b) return a.creation > b.creation end)

                    if next(submenu) ~= nil then
                        table.insert(menu, {title = folder, menu = submenu})
                    end
                end
            end

        end

        --------------------------------------------------------------------------------
        -- Sort table by title:
        --------------------------------------------------------------------------------
        table.sort(menu, function(a, b) return a.title < b.title end)

        if emptySharedXMLFiles then
            --------------------------------------------------------------------------------
            -- Nothing in the Shared Pasteboard:
            --------------------------------------------------------------------------------
            table.insert(menu, { title = "Empty", disabled = true })
        else
            --------------------------------------------------------------------------------
            -- Something in the Shared Pasteboard:
            --------------------------------------------------------------------------------
            table.insert(menu, { title = "-" })
            table.insert(menu, { title = "Clear Shared XML Files", fn = mod.clearSharedFiles })
        end
        mod._filesMenuCache = menu
        return menu
    end
end

-- sharedXMLFileWatcher(files) -> none
-- Function
-- The watcher file processor.
--
-- Parameters:
--  * files - A table of files
--
-- Returns:
--  * None
local function sharedXMLFileWatcher(files)
    --log.d("Refreshing Shared XML Folder.")
    for _,file in ipairs(files) do
        if file:sub(-7) == ".fcpxml" then
            local testFile = io.open(file, "r")
            if testFile ~= nil then
                testFile:close()

                local editorName = string.reverse(string.sub(string.reverse(file), string.find(string.reverse(file), "/", 1) + 1, string.find(string.reverse(file), "/", string.find(string.reverse(file), "/", 1) + 1) - 1))

                if host.localizedName() ~= editorName then
                    local xmlSharingPath = mod.sharingPath()
                    notify.new(function() fcp:importXML(file) end)
                        --:setIdImage(image.imageFromPath(config.iconPath))
                        :title("Shared XML File Received")
                        :subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
                        --:informativeText(config.appName .. " has received a new XML file.")
                        :hasActionButton(true)
                        :actionButtonTitle("Import XML")
                        :withdrawAfter(0)
                        :send()
                end

                -- Update Cache:
                mod._filesMenuCache = nil
                mod.listFilesMenu()

            end
        end
    end
end

--- plugins.finalcutpro.sharing.xml.update() -> none
--- Function
--- Starts or stops the watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    local enabled = mod.enabled()

    if enabled then
        --log.d("Enabling XML Sharing")
        local sharingPath = mod.sharingPath()
        if sharingPath == nil then
            sharingPath = dialog.displayChooseFolder(i18n("xmlSharingWhichFolder"))

            if sharingPath ~= false then
                mod.sharingPath(sharingPath)
            else
                mod.enabled(false)
                return
            end
        end

        -- Ensure the directory actually exists.
        if not tools.doesDirectoryExist(sharingPath) then
            mod.enabled(false)
            return
        end

        --------------------------------------------------------------------------------
        -- Watch for Shared XML Folder Changes:
        --------------------------------------------------------------------------------
        if not mod._watcher then
            log.df("Starting Shared XML Watcher")
            mod._watcher = pathwatcher.new(sharingPath, sharedXMLFileWatcher):start()
        end
    else
        --log.d("Disabling XML Sharing")
        --------------------------------------------------------------------------------
        -- Stop Watchers:
        --------------------------------------------------------------------------------
        if mod._watcher then
            mod._watcher:stop()
            mod._watcher = nil
        end

        --------------------------------------------------------------------------------
        -- Clear Settings:
        --------------------------------------------------------------------------------
        mod.sharingPath:clear()
    end
end

--------------------------------------------------------------------------------
-- WATCH EVENTS:
--------------------------------------------------------------------------------
function mod:watch(events)
    if not self.watchers then
        self.watchers = {}
    end
    self.watchers[#self.watchers + 1] = events
end

--------------------------------------------------------------------------------
-- NOTIFY WATCHERS:
--------------------------------------------------------------------------------
function mod:_notify(type, ...)
    if self.watchers then
        for _,watcher in ipairs(self.watchers) do
            if watcher[type] then
                watcher[type](...)
            end
        end
    end
end

--- plugins.finalcutpro.sharing.xml.shareXML() -> none
--- Function
--- Share XML
---
--- Parameters:
---  * incomingXML - XML data as string
---  * noErrors - Prevents error messages from being displayed.
---
--- Returns:
---  * None
function mod.shareXML(incomingXML, noErrors)

    local enableXMLSharing = mod.enabled()

    if enableXMLSharing then

        --------------------------------------------------------------------------------
        -- Get Settings:
        --------------------------------------------------------------------------------
        local xmlSharingPath = mod.sharingPath()

        --------------------------------------------------------------------------------
        -- Get only the needed XML content:
        --------------------------------------------------------------------------------
        -- TODO: Replace this with a proper DOM validation:
        local startOfXML = string.find(incomingXML, "<?xml version=")
        local endOfXML = string.find(incomingXML, "</fcpxml>")

        --------------------------------------------------------------------------------
        -- Error Detection:
        --------------------------------------------------------------------------------
        if not noErrors then
            if startOfXML == nil or endOfXML == nil then
                dialog.displayErrorMessage(i18n("sharedXMLError"))
                if incomingXML ~= nil then
                    log.d("Start of incomingXML.")
                    log.d(incomingXML)
                    log.d("End of incomingXML.")
                else
                    log.e("incomingXML is nil.")
                end
                return "fail"
            end
        end

        --------------------------------------------------------------------------------
        -- New XML:
        --------------------------------------------------------------------------------
        local newXML = string.sub(incomingXML, startOfXML - 2, endOfXML + 8)

        --------------------------------------------------------------------------------
        -- Display Text Box:
        --------------------------------------------------------------------------------
        local textboxResult = dialog.displayTextBoxMessage(i18n("hudXMLNameDialog"), i18n("hudXMLNameError"), "")

        if textboxResult then
            --------------------------------------------------------------------------------
            -- Save the XML content to the Shared XML Folder:
            --------------------------------------------------------------------------------
            local newXMLPath = xmlSharingPath .. host.localizedName() .. "/"

            if not tools.doesDirectoryExist(newXMLPath) then
                fs.mkdir(newXMLPath)
            end

            local file = io.open(newXMLPath .. textboxResult .. ".fcpxml", "w")
            file:write(newXML)
            file:close()
        end

    else
        if not noErrors then
            dialog.displayMessage(i18n("hudXMLSharingDisabled"))
        end
    end

end

--- plugins.finalcutpro.sharing.xml.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    --------------------------------------------------------------------------------
    -- Ensures that mod.update is called whenever enabled changes:
    --------------------------------------------------------------------------------
    mod.enabled:watch(mod.update)

    --------------------------------------------------------------------------------
    -- Pre-generate the menu:
    --------------------------------------------------------------------------------
    mod.listFilesMenu()

    --------------------------------------------------------------------------------
    -- Start the watchers if required:
    --------------------------------------------------------------------------------
    mod.update()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.sharing.xml",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.tools"]          = "menu",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Generate Files Menu for Cache:
    --------------------------------------------------------------------------------
    mod.init()

    --------------------------------------------------------------------------------
    -- Tools Menus:
    --------------------------------------------------------------------------------
    deps.menu:addMenu(PRIORITY, function() return i18n("sharedXMLFiles") end)

        :addItem(1, function()
            return { title = i18n("enableXMLSharing"),  fn = function() mod.enabled:toggle() end,   checked = mod.enabled()}
        end)
        :addSeparator(2)
        :addItems(3, mod.listFilesMenu)

    --------------------------------------------------------------------------------
    -- Trigger for when something is dropped from FCPX to Dock Icon:
    --------------------------------------------------------------------------------
    config.textDroppedToDockIconCallback:new("sharedXML", function(value) mod.shareXML(value, true) end)

    return mod
end

return plugin
