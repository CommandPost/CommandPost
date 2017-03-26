--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       S O U R C E W A T C H E R                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.sourcewatcher ===
---
--- Watches folders for specific file extensions and 
--- reloads the app if they change.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local console						= require("hs.console")
local pathwatcher					= require("hs.pathwatcher")

--------------------------------------------------------------------------------
--
-- MODULE:
--
--------------------------------------------------------------------------------

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt
function mod.new(extensions)
	local o = {
		extensions = extensions,
		paths = {},
		watchers = {},
	}
	setmetatable(o, mod.mt)
	return o
end

function mod.mt:matchesExtensions(file)
	if not self.extensions then
		-- Nothing specified, all files match
		return true
	else
		-- Must match one of the extensions
		for _,ext in ipairs(self.extensions) do
			if file:sub(-1*ext:len()) == ext then
				return true
			end
		end
		return false
	end
end

function mod.mt:filesChanged(files)
	for _,file in ipairs(files) do
		if self:matchesExtensions(file) then
			console.clearConsole()
			hs.reload()
			return
		end
	end
end

function mod.mt:watchPath(path)
	self.watchers[#self.watchers + 1] = pathwatcher.new(
		path,
		function(files)
			self:filesChanged(files)
		end
	):start()
	return self
end

return mod