--- === plugins.finalcutpro.toolbox.titlestokeywords ===
---
--- Converts Titles to Keywords

local require                   = require

local hs                        = _G.hs

local log                       = require "hs.logger".new "titlestokeywords"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local fcpxml                    = require "cp.apple.fcpxml"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local csv                       = require "csv"
local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local dirFiles                  = tools.dirFiles
local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local getFilenameFromPath       = tools.getFilenameFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableCount                = tools.tableCount
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local err
        mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
        if err then
            error(err)
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()
    local context = {
        i18n = i18n,
    }
    return renderPanel(context)
end

-- processFCPXML(path) -> none
-- Function
-- Process a FCPXML file
--
-- Parameters:
--  * path - The path to the FCPXML file.
--
-- Returns:
--  * None
local function processFCPXML(path)
    --------------------------------------------------------------------------------
    -- This is where we'll store the Titles metadata:
    --------------------------------------------------------------------------------
    local titles = {}
    local titleCount = 1

    --------------------------------------------------------------------------------
    -- Open the FCPXML document:
    --------------------------------------------------------------------------------
    local fcpxmlPath = fcpxml.valid(path)
    local document = fcpxmlPath and xml.open(fcpxmlPath)

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML is not valid:
    --------------------------------------------------------------------------------
    if not document then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"), i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Access the "Event > Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    local spine = document:XPathQuery("/fcpxml[1]/event[1]/project[1]/sequence[1]/spine[1]")
    local spineChildren = spine and spine[1] and spine[1]:children()

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML doesn't contain "Event > Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    if not spineChildren then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, "Invalid Data Detected.", "Please make sure you drag in an Event which contains a single Project. Do not drag in a Project or a Library.", i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Iterate all the spine children:
    --------------------------------------------------------------------------------
    for _, node in pairs(spineChildren) do
        local clipType = node:name()
        if clipType == "asset-clip" or clipType == "mc-clip" or clipType == "sync-clip" then
            --------------------------------------------------------------------------------
            -- A normal clip, Multi-cam or Synchronised Clip on the Primary Storyline:
            --
            -- EXAMPLE:
            -- <asset-clip ref="r2" offset="0s" name="Red 25fps 10sec" duration="10s" tcFormat="NDF">
            -- <mc-clip ref="r3" offset="10s" name="Multicam" duration="10s">
            -- <sync-clip offset="20s" name="Synchronized Clip" duration="10s" tcFormat="NDF">
            --------------------------------------------------------------------------------

            --------------------------------------------------------------------------------
            -- Save the "ref" of the clip for later:
            --------------------------------------------------------------------------------
            local currentRef
            if clipType == "sync-clip" then
                --------------------------------------------------------------------------------
                -- 'sync-clip' doesn't contain a 'ref' so we need to look for an 'asset-clip'
                -- inside first, before we look for titles:
                --------------------------------------------------------------------------------
                local syncClipNodes = node:children()
                for _, clipNode in pairs(syncClipNodes) do
                    local clipName = clipNode:name()
                    if clipName == "asset-clip" then
                        local syncClipAttributes = clipNode:rawAttributes()
                        for _, rawAttributeNode in pairs(syncClipAttributes) do
                            local rawAttributeNodeName = rawAttributeNode:name()
                            if rawAttributeNodeName == "ref" then
                                currentRef = rawAttributeNode:stringValue()
                            end
                        end
                    end
                end
            else
                --------------------------------------------------------------------------------
                -- "asset-clip" and "mc-clip" contain a 'ref':
                --------------------------------------------------------------------------------
                local clipRawAttributes = node:rawAttributes()
                for _, rawAttributeNode in pairs(clipRawAttributes) do
                    local rawAttributeNodeName = rawAttributeNode:name()
                    if rawAttributeNodeName == "ref" then
                        currentRef = rawAttributeNode:stringValue()
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Iterate all the nodes of the clip:
            --------------------------------------------------------------------------------
            local clipNodes = node:children()
            for _, clipNode in pairs(clipNodes) do
                local clipName = clipNode:name()
                if clipName == "title" then
                    --------------------------------------------------------------------------------
                    -- A title connected to a clip in the Primary Storyline:
                    --
                    -- EXAMPLE:
                    --
                    -- <title ref="r3" lane="1" offset="1s" name="One Second" start="3600s" duration="1s">
                    --------------------------------------------------------------------------------

                    --------------------------------------------------------------------------------
                    -- Save data found earlier:
                    --------------------------------------------------------------------------------
                    titles[titleCount] = {}
                    titles[titleCount]["clipType"] = clipType
                    titles[titleCount]["ref"] = currentRef

                    --------------------------------------------------------------------------------
                    -- Iterate the title node's attributes:
                    --------------------------------------------------------------------------------
                    local titleRawAttributes = clipNode:rawAttributes()
                    for _, rawAttributeNode in pairs(titleRawAttributes) do
                        local rawAttributeNodeName = rawAttributeNode:name()
                        if rawAttributeNodeName == "offset" then
                            titles[titleCount]["offset"] = rawAttributeNode:stringValue()
                        elseif rawAttributeNodeName == "name" then
                            titles[titleCount]["name"] = rawAttributeNode:stringValue()
                        elseif rawAttributeNodeName == "duration" then
                            titles[titleCount]["duration"] = rawAttributeNode:stringValue()
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Increment the title count:
                    --------------------------------------------------------------------------------
                    titleCount = titleCount + 1
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Abort - no Titles!
    --------------------------------------------------------------------------------
    if tableCount(titles) == 0 then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, "Invalid Data Detected.", "Please make sure you drag in an Event which contains a single Project, with Titles attached to clips in the Primary Storyline. Do not drag in a Project or a Library.", i18n("ok"), nil, "warning")
        end
        return
    end

    -- TODO: Now we update the FCPXML and send back.



    log.df("titles: %s", hs.inspect(titles))

end

-- callback() -> none
-- Function
-- JavaScript Callback for the Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function callback(id, params)
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "dropbox" then
            ---------------------------------------------------
            -- Make CommandPost active:
            ---------------------------------------------------
            hs.focus()

            ---------------------------------------------------
            -- Get value from UI:
            ---------------------------------------------------
            local value = params["value"] or ""
            local path = os.tmpname() .. ".fcpxml"

            ---------------------------------------------------
            -- Write the FCPXML data to a temporary file:
            ---------------------------------------------------
            writeToFile(path, value)

            ---------------------------------------------------
            -- Process the FCPXML:
            ---------------------------------------------------
            processFCPXML(path)
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Titles to Keywords Toolbox Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.titlestokeywords",
    group           = "finalcutpro",
    dependencies    = {
        ["core.toolbox.manager"]        = "manager",
        ["core.preferences.general"]    = "preferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._manager                = deps.manager
    mod._preferences            = deps.preferences
    mod._env                    = env

    --------------------------------------------------------------------------------
    -- Setup Utilities Panel:
    --------------------------------------------------------------------------------
    local toolboxID = "titlesToKeywords"
    mod._panel          =  deps.manager.addPanel({
        priority        = 10,
        id              = toolboxID,
        label           = "Titles to Keywords",
        image           = image.imageFromPath(env:pathToAbsolute("/images/LibraryTextStyleIcon.icns")),
        tooltip         = i18n("titles"),
        height          = 300,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "titlesToKeywordsPanelCallback", callback)

    return mod
end

return plugin
