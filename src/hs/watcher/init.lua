local mod = {}

--- hs.watcher:new(App) -> watcher
--- Function
--- Constructs a new watcher instance.
---
--- Parameters:
---  * `...` - The list of event names supported by the watcher.
---
--- Returns:
---  * a new watcher instance
---
function mod:new(...)
	o = {
		_events = pack(...),
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

local function mod:_prepareWatcher(events)
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
	if not self._watchers then
		self._watchers = {}
	end
	self._watchers[#self._watchers + 1] = self:_prepareWatcher(events)
	return {id=#self._watchers}
end

function mod:unwatch(id)
	
end

function commands:notify(type, ...)
	if self._watchers then
		for _,watcher in ipairs(self._watchers) do
			if watcher[type] then
				watcher[type](...)
			end
		end
	end
end


return mod