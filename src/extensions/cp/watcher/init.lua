--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C  O  M  M  A  N  D  P  O  S  T                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.watcher ===
---
--- Watcher Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local uuid							= require("hs.host").uuid

local log							= require("hs.logger").new("watcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.watcher:new(...) -> watcher
--- Function
--- Constructs a new watcher instance.
---
--- Parameters:
---  * `...` - The list of event name strings supported by the watcher.
---
--- Returns:
---  * a new watcher instance
function mod:new(...)
	local o = {
		_events 		= table.pack(...),
		_watchers 		= {},
		_watchersCount 	= 0,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function mod:_prepareWatcher(events)
	local watcher = {}
	for _,name in ipairs(self._events) do
		local fn = events[name]
		if fn and type(fn) == "function" then
			watcher[name] = fn
		end
	end
	return watcher
end

function mod:watch(events)
	local id = uuid()
	self._watchers[id] = self:_prepareWatcher(events)
	self._watchersCount = self._watchersCount + 1
	return {id=id}
end

function mod:unwatch(id)
	if self._watchers and id then
		if self._watchers[id.id] ~= nil then
			self._watchers[id.id] = nil
			self._watchersCount = self._watchersCount - 1
			return true
		end
	end
	return false
end

function mod:notify(type, ...)
	if self._watchers then
		for _,watcher in pairs(self._watchers) do
			if watcher[type] then
				watcher[type](...)
			end
		end
	end
end

function mod:getCount()
	return self._watchersCount
end

return mod