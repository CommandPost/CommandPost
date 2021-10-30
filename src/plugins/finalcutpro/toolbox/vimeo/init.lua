--- === plugins.finalcutpro.toolbox.vimeo ===
---
--- Vimeo Toolbox Panel.

local require                   = require

--local log                       = require "hs.logger".new "vimeo"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local text                      = require "cp.web.text"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeXML                 = text.escapeXML
local fromCSV                   = tools.fromCSV
local lines                     = tools.lines
local readFromFile              = tools.readFromFile
local removeFilenameFromPath    = tools.removeFilenameFromPath
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

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

-- sendVimeoCSVToFinalCutProX() -> none
-- Function
-- Send Vimeo CSV File to Final Cut Pro X.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function sendVimeoCSVToFinalCutProX()
    --------------------------------------------------------------------------------
    -- Prompt for CSV file:
    --------------------------------------------------------------------------------
    if not doesDirectoryExist(mod.lastCSVPath()) then
        mod.lastCSVPath(desktopPath)
    end
    local result = chooseFileOrFolder(i18n("pleaseSelectACSVFile") .. ":", mod.lastCSVPath(), true, false, false, {"csv"}, true)
    local path = result and result["1"]
    if not path then
        return
    end
    mod.lastCSVPath(removeFilenameFromPath(path))

    --------------------------------------------------------------------------------
    -- Read the CSV file:
    --------------------------------------------------------------------------------
    local data = readFromFile(path)
    local dataLines = data and lines(data) or {}

    --------------------------------------------------------------------------------
    -- Make sure the CSV is in the format we expect:
    --------------------------------------------------------------------------------
    if not dataLines[1] == [["Video Version","#","Timecode","Username","Note","Reply","Date Added","Resolved"]] or not dataLines[2] then
        webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("pleaseCheckTheContentsOfTheCSVFileAndTryAgain"), i18n("ok"), nil, "warning")
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
    -- Process each line:
    --------------------------------------------------------------------------------
    for i=2, #dataLines do
        --------------------------------------------------------------------------------
        -- Make sure each row has 8 columns:
        --------------------------------------------------------------------------------
        local rowData = fromCSV(dataLines[i])
        if not #rowData == 8 then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("pleaseCheckTheContentsOfTheCSVFileAndTryAgain"), i18n("ok"), nil, "warning")
            return
        end

        --------------------------------------------------------------------------------
        -- Handle Note:
        --------------------------------------------------------------------------------
        local note = rowData[5]

        --------------------------------------------------------------------------------
        -- Handled Completed Tag:
        --------------------------------------------------------------------------------
        local completed = "0"
        if rowData[8] == "Yes" then
            completed = "1"
        end

        --------------------------------------------------------------------------------
        -- Handle Timecode:
        --------------------------------------------------------------------------------
        local timecode = rowData[3]
        local times = timecode:split(":")
        if not #times == 3 then
            webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("pleaseCheckTheContentsOfTheCSVFileAndTryAgain"), i18n("ok"), nil, "warning")
            return
        end
        local hours = times[1]
        local minutes = times[2]
        local seconds = times[3]

        --------------------------------------------------------------------------------
        -- Include the username:
        --------------------------------------------------------------------------------
        if mod.includeUsername() then
            if rowData[4] ~= "" then
                note = "[" .. rowData[4] .. "]: " .. note
            end
        end

        --------------------------------------------------------------------------------
        -- Include Date Added:
        --------------------------------------------------------------------------------
        if mod.includeDateAdded() then
           note = note .. " (" .. rowData[7] .. ")"
        end

        --------------------------------------------------------------------------------
        -- Include any replies:
        --------------------------------------------------------------------------------
        local reply = rowData[6]
        if mod.includeReplies() then
            local replies = ""
            local replyCount = 0
            for ii=i + 1, #dataLines do
                local replyRowData = fromCSV(dataLines[ii])
                local currentTimecode = replyRowData[3]
                if timecode == currentTimecode then
                    replyCount = replyCount + 1
                    replies = replies .. ". [" .. i18n("reply") .. " " .. replyCount .. "]: " .. replyRowData[6]
                    if mod.includeDateAdded() then
                        replies = replies .. " (" .. rowData[7] .. ")"
                    end
                else
                    break
                end
            end
            note = note .. replies
        end

        --------------------------------------------------------------------------------
        -- Calculate Start Time:
        --------------------------------------------------------------------------------
        totalSeconds = (tonumber(hours) * 3600) + (tonumber(minutes) * 60) + tonumber(seconds) + videoStartTime

        --------------------------------------------------------------------------------
        -- Generate the Marker FCPXML:
        --------------------------------------------------------------------------------
        fcpxmlMiddle = fcpxmlMiddle .. [[                                <marker start="]] .. totalSeconds .. [[s" duration="100/2500s" value="]] .. escapeXML(note) .. [[" completed="]] .. completed .. [["/>]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- Calculate the total duration:
    --------------------------------------------------------------------------------
    local duration = totalSeconds + numberOfSecondsAfterLastMarker - videoStartTime .. "s"

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
        ["core.toolbox.manager"]    = "manager",
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
        height          = 340,
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
    :addContent(9, "<br />", false)
    :addButton(10,
        {
            label 	    = i18n("sendVimeoCsvToFinalCutPro"),
            width       = 200,
            onclick	    = sendVimeoCSVToFinalCutProX,
        }
    )

    return mod
end

return plugin
