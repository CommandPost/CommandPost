--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        C O M P R E S S O R     A P I                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.compressor ===
---
--- Represents the Compressor application, providing functions that allow different tasks to be accomplished.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("compressor")

local application								= require("hs.application")
local fs 										= require("hs.fs")
local inspect									= require("hs.inspect")

local v											= require("semver")

local plist										= require("cp.plist")
local just										= require("cp.just")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local App = {}

--- cp.apple.compressor.BUNDLE_ID
--- Constant
--- Compressor's Bundle ID
App.BUNDLE_ID 									= "com.apple.Compressor"

--- cp.apple.compressor:new() -> App
--- Function
--- Creates a new App instance representing Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * True is successful otherwise Nil
function App:new()
	o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.apple.compressor:application() -> hs.application
--- Function
--- Returns the hs.application for Compressor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The hs.application, or nil if the application is not installed.
function App:application()
	if self:isInstalled() then
		local result = application.applicationsForBundleID(App.BUNDLE_ID) or nil
		-- If there is at least one copy running, return the first one
		if result and #result > 0 then
			return result[1]
		end
	end
	return nil
end

--- cp.apple.compressor:getBundleID() -> string
--- Function
--- Returns the Compressor Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Compressor Bundle ID
function App:getBundleID()
	return App.BUNDLE_ID
end

--- cp.apple.compressor:isRunning() -> boolean
--- Function
--- Is Compressor Running?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Compressor is running otherwise `false`
function App:isRunning()
	local app = self:application()
	return app and app:isRunning()
end

--- cp.apple.compressor:launch() -> boolean
--- Function
--- Launches Compressor, or brings it to the front if it was already running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Compressor was either launched or focused, otherwise false (e.g. if Compressor doesn't exist)
function App:launch()

	local result = nil

	local app = self:application()
	if app == nil then
		-- Compressor is Closed:
		result = application.launchOrFocusByBundleID(App.BUNDLE_ID)
	else
		-- Compressor is Open:
		if not app:isFrontmost() then
			-- Open if not Active:
			result = application.launchOrFocusByBundleID(App.BUNDLE_ID)
		else
			-- Already frontmost:
			return true
		end
	end

	return result
end

--- cp.apple.compressor:restart() -> boolean
--- Function
--- Restart Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Compressor was running and restarted successfully.
function App:restart()
	local app = self:application()
	if app then
		-- Kill Compressor:
		self:quit()

		-- Wait until Compressor is Closed (checking every 0.1 seconds for up to 20 seconds):
		just.doWhile(function() return self:isRunning() end, 20, 0.1)

		-- Launch Compressor:
		return self:launch()
	end
	return false
end

--- cp.apple.compressor:show() -> cp.apple.compressor object
--- Function
--- Activate Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `cp.apple.compressor` object otherwise `nil`
function App:show()
	local app = self:application()
	if app then
		if app:isHidden() then
			app:unhide()
		end
		if app:isRunning() then
			app:activate()
		end
	end
	return self
end

--- cp.apple.compressor:isShowing() -> boolean
--- Function
--- Is Compressor Showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing otherwise `false`
function App:isShowing()
	local app = self:application()
	return app ~= nil and app:isRunning() and not app:isHidden()
end

--- cp.apple.compressor:hide() -> cp.apple.compressor object
--- Function
--- Hides Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `cp.apple.compressor` object otherwise `nil`
function App:hide()
	local app = self:application()
	if app then
		app:hide()
	end
	return self
end

--- cp.apple.compressor:quit() -> cp.apple.compressor object
--- Function
--- Quits Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `cp.apple.compressor` object otherwise `nil`
function App:quit()
	local app = self:application()
	if app then
		app:kill()
	end
	return self
end

--- cp.apple.compressor:path() -> string or nil
--- Function
--- Path to Compressor Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Compressor's filesystem path, or `nil` if the bundle identifier could not be located
function App:getPath()
	return application.pathForBundleID(App.BUNDLE_ID)
end

--- cp.apple.compressor:isInstalled() -> boolean
--- Function
--- Is a supported version of Compressor Installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if a supported version of Compressor is installed otherwise `false`
function App:isInstalled()
	local app = application.infoForBundleID(App.BUNDLE_ID)
	if app then return true end
	return false
end

--- cp.apple.compressor:isFrontmost() -> boolean
--- Function
--- Is Compressor Frontmost?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Compressor is Frontmost.
function App:isFrontmost()
	local app = self:application()
	return app and app:isFrontmost()
end

--- cp.apple.compressor:getVersion() -> string or nil
--- Function
--- Version of Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * Version as string or nil if an error occurred
---
--- Notes:
---  * If Compressor is running it will get the version of the active Compressor application, otherwise, it will use hs.application.infoForBundleID() to find the version.
function App:getVersion()
	local app = self:application()
	if app then
		return app and app["CFBundleShortVersionString"] or nil
	else
		return application.infoForBundleID(App.BUNDLE_ID) and application.infoForBundleID(App.BUNDLE_ID)["CFBundleShortVersionString"] or nil
	end
end

return App:new()