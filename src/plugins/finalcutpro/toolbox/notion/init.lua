--- === plugins.finalcutpro.toolbox.notion ===
---
--- Notion Toolbox Panel.

local require                   = require

local log                       = require "hs.logger".new "notion"

local hs                        = _G.hs

local dialog                    = require "hs.dialog"
local eventtap                  = require "hs.eventtap"
local fnutils                   = require "hs.fnutils"
local fs                        = require "hs.fs"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local task                      = require "hs.task"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local fcpxml                    = require "cp.apple.fcpxml"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local ensureDirectoryExists     = tools.ensureDirectoryExists
local execute                   = hs.execute
local getFileExtensionFromPath  = tools.getFileExtensionFromPath
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromPath             = image.imageFromPath
local mkdir                     = fs.mkdir
local removeFilenameFromPath    = tools.removeFilenameFromPath
local replace                   = tools.replace
local spairs                    = tools.spairs
local split                     = tools.split
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- NOTION_TOKEN_HELP_URL -> string
-- Constant
-- URL to Token Help
local NOTION_TOKEN_HELP_URL = "https://vzhd1701.notion.site/Find-Your-Notion-Token-5f57951434c1414d84ac72f88226eede"

-- NOTION_DATABASE_VIEW_HELP_URL -> string
-- Constant
-- URL to Database View Help
local NOTION_DATABASE_VIEW_HELP_URL = "https://github.com/vzhd1701/csv2notion/raw/master/examples/db_link.png"

--- plugins.finalcutpro.toolbox.notion.settings <cp.prop: table>
--- Field
--- Snippets
mod.settings = json.prop(config.userConfigRootPath, "Notion", "Settings.cpNotion", {})

--- plugins.finalcutpro.toolbox.notion.mergeData <cp.prop: boolean>
--- Field
--- Merge data?
mod.mergeData = config.prop("toolbox.notion.mergeData", true)

--- plugins.finalcutpro.toolbox.notion.token <cp.prop: string>
--- Field
--- Notion Token.
mod.token = config.prop("toolbox.notion.token", "")

--- plugins.finalcutpro.toolbox.notion.databaseURL <cp.prop: string>
--- Field
--- Notion Database URL.
mod.databaseURL = config.prop("toolbox.notion.databaseURL", "")

--- plugins.finalcutpro.toolbox.notion.defaultEmoji <cp.prop: string>
--- Field
--- Default Emoji
mod.defaultEmoji = config.prop("toolbox.notion.defaultEmoji", "🎬")

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

-- uploadToNotion(csvPath) -> none
-- Function
-- Uploads a CSV files to Notion.
--
-- Parameters:
--  * csvPath - A string containing the path to the CSV file.
--
-- Returns:
--  * None
local function uploadToNotion(csvPath)
    ---------------------------------------------------
    -- Show the Panel:
    ---------------------------------------------------
    hs.focus()

    local injectScript = mod._manager.injectScript

    --log.df("uploadToNotion: %s", csvPath)

    local token                 = mod.token()
    local databaseURL           = mod.databaseURL()
    local mergeData             = mod.mergeData()
    local defaultEmoji          = mod.defaultEmoji()

    --------------------------------------------------------------------------------
    -- Make sure there's a valid token!
    --------------------------------------------------------------------------------
    if not token or trim(token) == "" then
        injectScript("setStatus('red', '" .. string.upper(i18n("failed")) .. ": " .. i18n("aValidTokenIsRequired") .. "');")
        return
    end

    --log.df("mergeData: %s", mergeData)
    --log.df("databaseURL: %s", databaseURL)
    --log.df("defaultEmoji: %s", defaultEmoji)
    --log.df("token: %s", token)

    --------------------------------------------------------------------------------
    -- Define path to csv2notion:
    --------------------------------------------------------------------------------
    local binPath = config.basePath .. "/plugins/finalcutpro/toolbox/shotdata/csv2notion/csv2notion"

    --------------------------------------------------------------------------------
    -- Setup Arguments for csv2notion:
    --------------------------------------------------------------------------------
    local arguments = {
        "--token",
        token,
    }

    if databaseURL and databaseURL ~= "" then
        table.insert(arguments, "--url")
        table.insert(arguments, databaseURL)
    end

    if mergeData then
        table.insert(arguments, "--merge")
    end

    if defaultEmoji and defaultEmoji ~= "" then
        table.insert(arguments, "--default-icon")
        table.insert(arguments, defaultEmoji)
    end

    table.insert(arguments, "--verbose")

    table.insert(arguments, csvPath)

    --------------------------------------------------------------------------------
    -- Trigger new hs.task that calls csv2notion:
    --------------------------------------------------------------------------------
    mod.notionTask = task.new(binPath, function() -- (exitCode, stdOut, stdErr)
        --------------------------------------------------------------------------------
        -- Callback Function:
        --------------------------------------------------------------------------------
        --[[
        log.df("Shot Data Completion Callback:")
        log.df(" - exitCode: %s", exitCode)
        log.df(" - stdOut: %s", stdOut)
        log.df(" - stdErr: %s", stdErr)
        --]]
    end, function(_, _, stdErr) -- (obj, stdOut, stdErr)
        --------------------------------------------------------------------------------
        -- Stream Callback Function:
        --------------------------------------------------------------------------------
        --log.df("Stream Callback Function")
        --log.df("obj: %s", obj)
        --log.df("stdOut: %s", stdOut)
        if stdErr and stdErr ~= "" then

            --------------------------------------------------------------------------------
            -- Remove Line Breaks:
            --------------------------------------------------------------------------------
            local status = stdErr:gsub("[\r\n%z]", "")

            --------------------------------------------------------------------------------
            -- Trim any white space:
            --------------------------------------------------------------------------------
            status = trim(status)

            --------------------------------------------------------------------------------
            -- Remove type prefix:
            --------------------------------------------------------------------------------
            local statusColour = "green"
            if status:sub(1, 11) == "INFO: Done!" then
                status = i18n("successfullyUploadedToNotion") .. "!"
            elseif status:sub(1, 6) == "INFO: " then
                status = status:sub(7) .. "..."
            elseif status:sub(1, 10) == "CRITICAL: " then
                status = status:sub(11)
                statusColour = "red"
            elseif status:sub(1, 9) == "WARNING: " then
                status = status:sub(10)
                statusColour = "orange"
            elseif status:sub(2, 2) == "%" or status:sub(3, 3) == "%" or status:sub(4, 4) == "%" then
                --------------------------------------------------------------------------------
                -- Example:
                --
                -- 0%|          | 0/19 [00:00<?, ?it/s]
                --------------------------------------------------------------------------------
                status = i18n("uploading") .. "... " .. status
            end

            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            if status:len() < 160 then
                injectScript("setStatus(`" .. statusColour .. "`, `" .. status .. "`);")
            else
                injectScript("setStatus(`red`, `" .. string.upper(i18n("error")) .. ": " .. i18n("checkTheDebugConsoleForTheFullErrorMessage") .. "...`);")
            end

            --------------------------------------------------------------------------------
            -- Write to Debug Console:
            --------------------------------------------------------------------------------
            log.df("Notion Upload Status: %s", status)
        end

        return true
    end, arguments):start()
end

-- updateUI() -> none
-- Function
-- Update the user interface.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    --------------------------------------------------------------------------------
    -- Update the user interface elements:
    --------------------------------------------------------------------------------
    local script = [[
        setStatus("green", `]] .. i18n("readyToUpload") .. [[...`);

        changeCheckedByID("mergeData", ]] .. tostring(mod.mergeData()) .. [[);

        changeValueByID("token", "]] .. mod.token() .. [[");
        changeValueByID("databaseURL", "]] .. mod.databaseURL() .. [[");
        changeValueByID("defaultEmoji", "]] .. mod.defaultEmoji() .. [[");
    ]]

    local injectScript = mod._manager.injectScript
    injectScript(script)
end

-- uploadTimelineIndex() -> none
-- Function
-- Upload Timeline Index.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function uploadTimelineIndex()
    --------------------------------------------------------------------------------
    -- Upload Timeline Index:
    --------------------------------------------------------------------------------
    local injectScript = mod._manager.injectScript
    injectScript([[setStatus('green', `]] .. i18n("processingCSVData") .. [[...`);]])

    --------------------------------------------------------------------------------
    -- Add a slight delay so that the status message updates first:
    --------------------------------------------------------------------------------
    doAfter(1, function()
        local timeline = fcp.timeline
        local index = timeline.index
        fcp:launch(5)
        timeline:show()
        if not timeline.toolbar.index:checked() then
            timeline.toolbar.index:press()
        end
        if index:isShowing() then
            local activeTab = index:activeTab()
            local list = activeTab and activeTab.list
            if list and not index.roles:isShowing() then
                local result = list:toCSV()
                if result then
                    local tempFolder = os.tmpname() .. "_csv_folder"
                    local success, errorMessage = mkdir(tempFolder)
                    if not success then
                        log.ef("[Notion Toolbox] Error: %s", errorMessage)
                    else
                        local path = tempFolder .. "/Timeline Index.csv"
                        if path then
                            writeToFile(path, result)
                            uploadToNotion(path)
                            return
                        end
                    end
                end
            end
        end
        injectScript([[setStatus("red", `]] .. i18n("failedToExportTheTimelineIndex") .. [[...`);]])
    end)
end

-- uploadBrowserContents() -> none
-- Function
-- Upload Browser Contents.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function uploadBrowserContents()
    --------------------------------------------------------------------------------
    -- Upload Browser Contents:
    --------------------------------------------------------------------------------
    local injectScript = mod._manager.injectScript
    injectScript([[setStatus('green', `]] .. i18n("processingCSVData") .. [[...`);]])

    --------------------------------------------------------------------------------
    -- Add a slight delay so that the status message updates first:
    --------------------------------------------------------------------------------
    doAfter(1, function()
        local list = fcp.libraries.list
        fcp:launch(5)
        list:show()
        if list:isShowing() then
            local result = list.contents:toCSV()
            if result then
                local tempFolder = os.tmpname() .. "_csv_folder"
                local success, errorMessage = mkdir(tempFolder)
                if not success then
                    log.ef("[Notion Toolbox] Error: %s", errorMessage)
                else
                    local path = tempFolder .. "/Browser Contents.csv"
                    if path then
                        writeToFile(path, result)
                        uploadToNotion(path)
                        return
                    end
                end
            end
        end
        injectScript([[setStatus("red", `]] .. i18n("failedToExportTheBrowserContents") .. [[...`);]])
    end)
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
    if not callbackType then
        log.ef("Invalid callback type in Shot Data Toolbox Panel.")
        return
    end
    if callbackType == "uploadTimelineIndex" then
        --------------------------------------------------------------------------------
        -- Upload Timeline Index:
        --------------------------------------------------------------------------------
        uploadTimelineIndex()
    elseif callbackType == "uploadBrowserContents" then
        --------------------------------------------------------------------------------
        -- Upload Browser Contents:
        --------------------------------------------------------------------------------
        uploadBrowserContents()
    elseif callbackType == "findToken" then
        --------------------------------------------------------------------------------
        -- Find Token Help Button:
        --------------------------------------------------------------------------------
        execute("open " .. NOTION_TOKEN_HELP_URL)
    elseif callbackType == "findDatabaseURL" then
        --------------------------------------------------------------------------------
        -- Find Database Help Button:
        --------------------------------------------------------------------------------
        execute("open " .. NOTION_DATABASE_VIEW_HELP_URL)
    elseif callbackType == "updateUI" then
        --------------------------------------------------------------------------------
        -- Update the User Interface:
        --------------------------------------------------------------------------------
        updateUI()
    elseif callbackType == "updateText" then
        --------------------------------------------------------------------------------
        -- Updated Text Values from the User Interface:
        --------------------------------------------------------------------------------
        local tid = params and params["id"]
        local value = params and params["value"]
        if tid then
            if tid == "token" then
                mod.token(value)
            elseif tid == "databaseURL" then
                mod.databaseURL(value)
            elseif tid == "defaultEmoji" then
                mod.defaultEmoji(value)
            end
        end
    elseif callbackType == "updateChecked" then
        --------------------------------------------------------------------------------
        -- Updated Checked Values from the User Interface:
        --------------------------------------------------------------------------------
        local tid = params and params["id"]
        local value = params and params["value"]

        if tid then
            if tid == "mergeData" then
                mod.mergeData(value)
            end
        end
    elseif callbackType == "loadSettings" then
        --------------------------------------------------------------------------------
        -- Load Settings:
        --------------------------------------------------------------------------------
        local menu = {}

        local settings = mod.settings()

        local numberOfSettings = tableCount(settings)

        local function updateSettings(setting)
            mod.token(setting["token"])
            mod.databaseURL(setting["databaseURL"])
            mod.defaultEmoji(setting["defaultEmoji"])
            mod.mergeData(setting["mergeData"])
            updateUI()
        end

        if numberOfSettings == 0 then
            table.insert(menu, {
                title = i18n("none"),
                disabled = true,
            })
        else
            for tid, setting in pairs(settings) do
                table.insert(menu, {
                    title = tid,
                    fn = function() updateSettings(setting) end
                })
            end
            table.insert(menu, {
                title = "-",
                disabled = true,
            })
            table.insert(menu, {
                title = i18n("deleteAllSettings"),
                fn = function()
                    mod.settings({})
                    updateUI()
                end,
            })

        end

        local popup = menubar.new()
        popup:setMenu(menu):removeFromMenuBar()
        popup:popupMenu(mouse.absolutePosition(), true)
    elseif callbackType == "saveSettings" then
        --------------------------------------------------------------------------------
        -- Save Settings:
        --------------------------------------------------------------------------------
        local label = params and params["label"]
        if label and label ~= "" then
            local settings = mod.settings()

            settings[label] = {
                ["token"]                           = mod.token(),
                ["databaseURL"]                     = mod.databaseURL(),
                ["defaultEmoji"]                    = mod.defaultEmoji(),
                ["mergeData"]                       = mod.mergeData(),
            }

            mod.settings(settings)
        end
    elseif callbackType == "emojiPicker" then
        --------------------------------------------------------------------------------
        -- Emoji Picker Button Pressed:
        --------------------------------------------------------------------------------
        mod.defaultEmoji("")

        local injectScript = mod._manager.injectScript
        local script = [[
            changeValueByID("defaultEmoji", "]] .. mod.defaultEmoji() .. [[");
            document.getElementById("defaultEmoji").focus();
            pressButton("openEmojiPicker");
        ]]
        injectScript(script)
    elseif callbackType == "openEmojiPicker" then
        --------------------------------------------------------------------------------
        -- Open Emoji Picker (triggered by above JavaScript):
        --------------------------------------------------------------------------------
        eventtap.keyStroke({"control", "command"}, "space")
    else
        --------------------------------------------------------------------------------
        -- Unknown Callback:
        --------------------------------------------------------------------------------
        log.df("Unknown Callback in Notion Toolbox Panel:")
        log.df("id: %s", inspect(id))
        log.df("params: %s", inspect(params))
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.notion",
    group           = "finalcutpro",
    dependencies    = {
        ["core.commands.global"]        = "global",
        ["core.preferences.general"]    = "preferences",
        ["core.toolbox.manager"]        = "manager",
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
    local icon = imageFromPath(env:pathToAbsolute("/images/notion-logo.png"))
    mod._panel = deps.manager.addPanel({
        priority        = 1.2,
        id              = "notion",
        label           = i18n("notion"),
        image           = icon,
        tooltip         = i18n("notion"),
        height          = 490,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "notionPanelCallback", callback)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("uploadBrowserContents")
        :whenActivated(function()
            mod._manager.show("notion")
            doAfter(1, function()
                uploadBrowserContents()
            end)
        end)
        :titled(i18n("uploadBrowserContentsToNotion"))
        :subtitled(i18n("toolbox"))
        :image(icon)

    deps.global
        :add("uploadTimelineIndex")
        :whenActivated(function()
            mod._manager.show("notion")
            doAfter(1, function()
                uploadTimelineIndex()
            end)
        end)
        :titled(i18n("uploadTimelineIndexToNotion"))
        :subtitled(i18n("toolbox"))
        :image(icon)

    return mod
end

return plugin
