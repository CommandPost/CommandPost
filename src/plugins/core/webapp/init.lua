--- === plugins.core.webapp ===
---
--- WebApp Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("webapp")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local hsminweb          = require("hs.httpserver.hsminweb")
local pasteboard        = require("hs.pasteboard")
local timer             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.webapp.DEFAULT_PORT -> number
--- Constant
--- The Default Port.
mod.DEFAULT_PORT            = 12345

--- plugins.core.webapp.DEFAULT_SETTING -> boolean
--- Constant
--- Whether or not the WebApp should be enabled by default.
mod.DEFAULT_SETTING         = false

--- plugins.core.webapp.PREFERENCE_NAME -> string
--- Constant
--- The Preference Name
mod.PREFERENCE_NAME         = "enableWebApp"

--- plugins.core.webapp.start() -> WebApp
--- Function
--- Starts the WebApp.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WebApp object.
function mod.start()
    if mod._server then
        log.df("CommandPost WebApp Already Running")
    else
        mod._server = hsminweb.new()
            :name("CommandPost Webapp")
            :port(mod.DEFAULT_PORT)
            :cgiEnabled(true)
            :documentRoot(mod.path)
            :luaTemplateExtension("lp")
            :directoryIndex({"index.lp"})
            :start()
        log.df("Started CommandPost WebApp.")
    end
    return mod
end

--- plugins.core.webapp.stop() -> WebApp
--- Function
--- Stops the WebApp.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WebApp object.
function mod.stop()
    if mod._server then
        mod._server:stop()
        mod._server = nil
        log.df("Stopped CommandPost WebApp")
    end
end

--- plugins.core.webapp.copyLinkToPasteboard() -> None
--- Function
--- Copies the Hostname to the Pasteboard.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.copyLinkToPasteboard()
    pasteboard.setContents(mod.hostname)
end

--- plugins.core.webapp.update() -> None
--- Function
--- Starts or Stops the WebApp.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        mod.start()
    else
        mod.stop()
    end
end

--- plugins.core.webapp.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop(mod.PREFERENCE_NAME, mod.DEFAULT_SETTING):watch(mod.update)

-- getHostname() -> string | nil
-- Function
-- Gets the Hostname URL as string
--
-- Parameters:
--  * None
--
-- Returns:
--  * The hostname as a string or `nil` if the hostname could not be determined.
local function getHostname()
    local _hostname, _status = hs.execute("hostname")
    if _status and _hostname then
        return "http://" .. tools.trim(_hostname) .. ":" .. mod.DEFAULT_PORT
    else
        return nil
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.webapp",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.webapp"]  = "webappPreferences",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Get Hostname:
    --------------------------------------------------------------------------------
    mod.hostname = getHostname() or i18n("webappUnresolvedHostname")

    --------------------------------------------------------------------------------
    -- Get Path:
    --------------------------------------------------------------------------------
    mod.path = env:pathToAbsolute("html")

    --------------------------------------------------------------------------------
    -- Setup Preferences:
    --------------------------------------------------------------------------------
    deps.webappPreferences
        :addHeading(10, i18n ("webappIntroduction"))
        :addParagraph(15, i18n("webappInstructions"), false)
        :addHeading(25, i18n("webappSettings"))
        :addCheckbox(30,
            {
                label = i18n("webappEnable"),
                onchange = function() mod.enabled:toggle() end,
                checked = mod.enabled,
            }
        )
        :addHeading(40, i18n("webappHostname"))
        :addParagraph(45, mod.hostname)
        :addButton(50,
            {
                label = "Copy Link to Pasteboard",
                onclick = mod.copyLinkToPasteboard
            }
        )

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Start the WebApp if Enabled:
    --------------------------------------------------------------------------------
    if mod.enabled() then
        timer.doAfter(1, mod.start)
    end
end

return plugin
