--- === plugins.finalcutpro.toolbox.vimeo ===
---
--- Vimeo Toolbox Panel.

local require                   = require

local log                       = require "hs.logger".new "vimeo"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local text                      = require "cp.web.text"
local tools                     = require "cp.tools"

local csv                       = require "csv"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeXML                 = text.escapeXML
local removeFilenameFromPath    = tools.removeFilenameFromPath
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- VIMEO_CSV_HEADER -> table
-- Constant
-- A table of the header items in a Vimeo CSV. If there's multiple variations for a header, use '|' as a separator.
local VIMEO_CSV_HEADER = {"Video Version","#","Timecode","Username|Name","Note","Reply","Date Added","Resolved"}

-- desktopPath -> string
-- Constant
-- Path to the users desktop
local desktopPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.finalcutpro.toolbox.vimeo.lastCSVPath <cp.prop: string>
--- Field
--- Last CSV Path
mod.lastCSVPath = config.prop("toolbox.vimeo.lastCSVPath", desktopPath)

--- plugins.finalcutpro.toolbox.vimeo.includeUsername <cp.prop: boolean>
--- Field
--- Include Username
mod.includeUsername = config.prop("toolbox.vimeo.includeUsername", true)

--- plugins.finalcutpro.toolbox.vimeo.includeReplies <cp.prop: boolean>
--- Field
--- Include Reply
mod.includeReplies = config.prop("toolbox.vimeo.includeReplies", true)

--- plugins.finalcutpro.toolbox.vimeo.includeDateAdded <cp.prop: boolean>
--- Field
--- Include Date Added
mod.includeDateAdded = config.prop("toolbox.vimeo.includeDateAdded", true)

-- sendVimeoCSVToFinalCutProX(path) -> none
-- Function
-- Send Vimeo CSV File to Final Cut Pro X.
--
-- Parameters:
--  * path - An optional path to the CSV file.
--
-- Returns:
--  * None
local function sendVimeoCSVToFinalCutProX(path)
    --------------------------------------------------------------------------------
    -- Prompt for CSV file:
    --------------------------------------------------------------------------------
    if not path then
        if not doesDirectoryExist(mod.lastCSVPath()) then
            mod.lastCSVPath(desktopPath)
        end
        local result = chooseFileOrFolder(i18n("pleaseSelectACSVFile") .. ":", mod.lastCSVPath(), true, false, false, {"csv"}, true)
        path = result and result["1"]
        if not path then
            return
        end
        mod.lastCSVPath(removeFilenameFromPath(path))
    end

    --------------------------------------------------------------------------------
    -- Read the CSV file:
    --------------------------------------------------------------------------------
    local data = csv.open(path, {header=true})
    if not data then
        if mod._manager.getWebview() then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("badCSVFileForVimeoToolbox"), i18n("ok"), nil, "warning")
        else
            log.ef("[Vimeo Toolbox] Failed to process the CSV file. This CSV file does not contain the contents we expect from Vimeo.")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure the first line has valid columns:
    --------------------------------------------------------------------------------
    local valid = true
    for line in data:lines() do
        for _, v in pairs(VIMEO_CSV_HEADER) do
            if v:find("|") then
                --------------------------------------------------------------------------------
                -- There's multiple options for the header (separated by '|' in the table):
                --------------------------------------------------------------------------------
                local options = v:split("|")
                local foundOption = false
                for _, option in pairs(options) do
                    if line[option] then
                        foundOption = true
                    end
                end
                if not foundOption then
                    valid = false
                    break
                end
            else
                --------------------------------------------------------------------------------
                -- There's only one option for the header:
                --------------------------------------------------------------------------------
                if not line[v] then
                    valid = false
                    break
                end
            end
        end
        if not valid then
            break
        end
    end

    if not valid then
        if mod._manager.getWebview() then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("badCSVFileForVimeoToolbox"), i18n("ok"), nil, "warning")
        else
            log.ef("[Vimeo Toolbox] Failed to process the CSV file. This CSV file does not contain the contents we expect from Vimeo.")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Define some parameters:
    --------------------------------------------------------------------------------
    local numberOfSecondsAfterLastMarker = 1
    local videoStartTime = 3600
    local fcpxmlMiddle = ""
    local totalSeconds = 0

    --------------------------------------------------------------------------------
    -- Put the results into an ordered table:
    --------------------------------------------------------------------------------
    local results = {}
    local counter = 1
    for line in data:lines() do
        results[counter] = line
        counter = counter + 1
    end

    --------------------------------------------------------------------------------
    -- If there's only one line, then something has broken:
    --------------------------------------------------------------------------------
    if counter <= 1 then
        if mod._manager.getWebview() then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("badCSVFileForVimeoToolbox"), i18n("ok"), nil, "warning")
        else
            log.ef("[Vimeo Toolbox] Failed to process the CSV file. This CSV file does not contain the contents we expect from Vimeo.")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Process the results:
    --------------------------------------------------------------------------------
    local lastClip = 0
    for i, line in tools.spairs(results) do
        --------------------------------------------------------------------------------
        -- Handle Note:
        --------------------------------------------------------------------------------
        local note = line["Note"]

        --------------------------------------------------------------------------------
        -- Handled Completed Tag:
        --------------------------------------------------------------------------------
        local completed = (line["Resolved"] == "Yes") and "1" or "0"

        --------------------------------------------------------------------------------
        -- Handle Timecode:
        --------------------------------------------------------------------------------
        local timecode = line["Timecode"]
        local times = timecode:split(":")
        if not #times == 3 then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("badCSVFileForVimeoToolbox"), i18n("ok"), nil, "warning")
            return
        end
        local hours = times[1]
        local minutes = times[2]
        local seconds = times[3]

        --------------------------------------------------------------------------------
        -- Skip any CSV lines that don't have hours, minutes and seconds:
        --------------------------------------------------------------------------------
        if hours and minutes and seconds then
            --------------------------------------------------------------------------------
            -- Include the username:
            --------------------------------------------------------------------------------
            if mod.includeUsername() then
                local username = line["Username"] or line["Name"]
                if username and username ~= "" then
                    note = "[" .. username .. "]: " .. note
                end
            end

            --------------------------------------------------------------------------------
            -- Include Date Added:
            --------------------------------------------------------------------------------
            if mod.includeDateAdded() then
                local dateAdded = line["Date Added"]
                if dateAdded and dateAdded ~= "" then
                    note = note .. " (" .. dateAdded .. ")"
                end
            end

            --------------------------------------------------------------------------------
            -- Include any replies:
            --------------------------------------------------------------------------------
            if mod.includeReplies() then
                local replies = ""
                local replyCount = 0
                for ii=i + 1, #results do
                    local replyData = results[ii]
                    if replyData then
                        local currentTimecode = replyData["Timecode"]
                        if timecode == currentTimecode then
                            replyCount = replyCount + 1
                            local reply = replyData["Reply"]
                            local dataAdded = replyData["Date Added"]
                            if reply and reply ~= "" then
                                replies = replies .. ". [" .. i18n("reply") .. " " .. replyCount .. "]: " .. replyData["Reply"]
                                if mod.includeDateAdded() and dataAdded and dataAdded ~= "" then
                                    replies = replies .. " (" ..dataAdded .. ")"
                                end
                            end
                        else
                            break
                        end
                    end
                end
                note = note .. replies
            end

            --------------------------------------------------------------------------------
            -- Calculate Start Time:
            --------------------------------------------------------------------------------
            totalSeconds = (tonumber(hours) * 3600) + (tonumber(minutes) * 60) + tonumber(seconds) + videoStartTime

            --------------------------------------------------------------------------------
            -- Is this the last clip?
            --------------------------------------------------------------------------------
            if totalSeconds > lastClip then
                lastClip = totalSeconds
            end

            --------------------------------------------------------------------------------
            -- Generate the Marker FCPXML:
            --------------------------------------------------------------------------------
            fcpxmlMiddle = fcpxmlMiddle .. [[                                <marker start="]] .. totalSeconds .. [[s" duration="100/2500s" value="]] .. escapeXML(note) .. [[" completed="]] .. completed .. [["/>]] .. "\n"
        end
    end

    --------------------------------------------------------------------------------
    -- Calculate the total duration:
    --------------------------------------------------------------------------------
    local duration = lastClip + numberOfSecondsAfterLastMarker - videoStartTime .. "s"

    --------------------------------------------------------------------------------
    -- Hard coded FCPXML Template:
    --------------------------------------------------------------------------------
    local fcpxmlStart = [[<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE fcpxml>

    <fcpxml version="1.9">
        <resources>
            <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
            <effect id="r2" name="Custom" uid=".../Generators.localized/Solids.localized/Custom.localized/Custom.motn"/>
        </resources>
        <library>
            <event name="📝 VIMEO COMMENTS">
                <project name="Vimeo Comments (Imported on ]] .. escapeXML(os.date("%Y-%m-%d %H:%M")) .. [[)">
                    <sequence duration="]] .. duration .. [[" format="r1" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                        <spine>
                            <gap name="Gap" offset="0s" duration="]] .. duration .. [[" start="3600s">
                                <video name="Vimeo Comments" lane="1" offset="3600s" ref="r2" duration="]] .. duration .. [[" start="3600s">
                                    <adjust-blend amount="0"/>
    ]]
    local fcpxmlEnd = [[
                                </video>
                            </gap>
                        </spine>
                    </sequence>
                </project>
            </event>
        </library>
    </fcpxml>]]

    --------------------------------------------------------------------------------
    -- Put it all together:
    --------------------------------------------------------------------------------
    fcpxmlMiddle = fcpxmlStart .. fcpxmlMiddle .. fcpxmlEnd

    --------------------------------------------------------------------------------
    -- Write a temporary file and import it into FCPX:
    --------------------------------------------------------------------------------
    local tempFilename = os.tmpname() .. ".fcpxml"
    writeToFile(tempFilename, fcpxmlMiddle)
    fcp:importXML(tempFilename)
end

local plugin = {
    id              = "finalcutpro.toolbox.vimeo",
    group           = "finalcutpro",
    dependencies    = {
        ["core.toolbox.manager"]        = "manager",
        ["core.commands.global"]        = "global",
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
    -- Setup Toolbox Panel:
    --------------------------------------------------------------------------------
    mod._panel = deps.manager.addPanel({
        priority        = 4,
        id              = "vimeo",
        label           = i18n("vimeo"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/Vimeo.icns")),
        tooltip         = i18n("vimeo"),
        height          = 360,
    })
    :addHeading(1, i18n("vimeoMarkerConverter"))
    :addContent(2, [[<p class="uiItem">]] .. i18n("vimeoMarkerConverterDescriptionOne") .. [[</p>]], false)
    :addContent(3, "<br />", false)
    :addContent(4, [[<p class="uiItem">]] .. i18n("vimeoMarkerConverterDescriptionTwo") .. [[</p>]], false)
    :addHeading(5, i18n("options"))
    :addCheckbox(6,
        {
            label = i18n("includeUsername"),
            onchange = function(_, params) mod.includeUsername(params.checked) end,
            checked = mod.includeUsername,
        }
    )
    :addCheckbox(7,
        {
            label = i18n("includeReplies"),
            onchange = function(_, params) mod.includeReplies(params.checked) end,
            checked = mod.includeReplies,
        }
    )
    :addCheckbox(8,
        {
            label = i18n("includeDateAdded"),
            onchange = function(_, params) mod.includeDateAdded(params.checked) end,
            checked = mod.includeDateAdded,
        }
    )
    :addCheckbox(8.1,
        {
            label = i18n("enableDroppingVimeoCSVToDockIcon"),
            onchange = function(_, params)
                mod.includeDateAdded(params.checked)
                if params.checked then
                    mod._preferences.dragAndDropFileAction("sendVimeoCsvToFinalCutPro")
                else
                    if mod._preferences.dragAndDropFileAction() == "sendVimeoCsvToFinalCutPro" then
                        mod._preferences.dragAndDropFileAction("")
                    end
                end

            end,
            checked = function()
                return mod._preferences.dragAndDropFileAction() == "sendVimeoCsvToFinalCutPro"
            end,
        }
    )
    :addContent(9, "<br />", false)
    :addButton(10,
        {
            label       = i18n("sendVimeoCsvToFinalCutPro"),
            width       = 200,
            onclick     = function() sendVimeoCSVToFinalCutProX() end,
        }
    )

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("sendVimeoCsvToFinalCutPro")
        :whenActivated(function()
            sendVimeoCSVToFinalCutProX()
        end)
        :titled(i18n("sendVimeoCsvToFinalCutPro"))

    --------------------------------------------------------------------------------
    -- Drag & Drop File to the Dock Icon:
    --------------------------------------------------------------------------------
    mod._preferences.registerDragAndDropFileAction("sendVimeoCsvToFinalCutPro", i18n("sendVimeoCsvToFinalCutPro"), function(path)
        sendVimeoCSVToFinalCutProX(path)
    end)

    return mod
end

return plugin
