local guitk = require("hs._asm.guitk")
local timer = require("hs.timer")

local module = {}

local gui = guitk.new{ x = 100, y = 100, h = 100, w = 204 }:show()
local mgr = guitk.manager.new()
gui:contentManager(mgr)

mgr[#mgr + 1] = {
    id       = "backgroundSpinner",
    _element = guitk.element.progress.new():circular(true):start(),
}
mgr[#mgr + 1] = {
    id       = "foregroundSpinner",
    _element = guitk.element.progress.new():circular(true):threaded(false):start(),
}

mgr[#mgr + 1] = {
    id           = "backgroundBar",
    _element     = guitk.element.progress.new():start(),
    frameDetails = { x = 10, y = 10, w = 184 },
}
mgr[#mgr + 1] = {
    id       = "foregroundBar",
    _element = guitk.element.progress.new():threaded(false):start(),
    frameDetails = { w = 184 },
}

mgr[#mgr + 1] = {
    id            = "hoursBar",
    _element      = guitk.element.progress.new(),
    min           = 0,
    max           = 23,
    indeterminate = false,
    indicatorSize = "small",
    color         = { red   = 1 },
    tooltip       = "hours",
    frameDetails  = { w = 120 },
}
mgr[#mgr + 1] = {
    id            = "minutesBar",
    _element      = guitk.element.progress.new(),
    min           = 0,
    max           = 60,
    indeterminate = false,
    indicatorSize = "small",
    color         = { green = 1 },
    tooltip       = "minutes",
    frameDetails  = { w = 120 },
}
mgr[#mgr + 1] = {
    id            = "secondsBar",
    _element      = guitk.element.progress.new(),
    min           = 0,
    max           = 60,
    indeterminate = false,
    indicatorSize = "small",
    color         = { blue  = 1 },
    tooltip       = "seconds",
    frameDetails  = { w = 120 },
}

mgr[#mgr + 1] = {
    id            = "hoursSpinner",
    _element      = guitk.element.progress.new(),
    circular      = true,
    min           = 0,
    max           = 23,
    indeterminate = false,
    indicatorSize = "small",
    color         = { red   = 1, green = 1 },
    tooltip       = "hours",
}
mgr[#mgr + 1] = {
    id            = "minutesSpinner",
    _element      = guitk.element.progress.new(),
    circular      = true,
    min           = 0,
    max           = 60,
    indeterminate = false,
    indicatorSize = "small",
    color         = { green = 1, blue = 1 },
    tooltip       = "minutes",
}
mgr[#mgr + 1] = {
    id            = "secondsSpinner",
    _element      = guitk.element.progress.new(),
    circular      = true,
    min           = 0,
    max           = 60,
    indeterminate = false,
    indicatorSize = "small",
    color         = { blue  = 1, red = 1 },
    tooltip       = "seconds",
}

mgr("backgroundBar"):frameDetails{ x = 10, y = 10, w = 184 }

mgr("backgroundSpinner"):moveBelow(mgr("backgroundBar"))
mgr("foregroundSpinner"):moveBelow(mgr("backgroundBar"), "flushRight")

mgr("hoursBar"):moveBelow(mgr("backgroundBar"), -2, "centered")
mgr("minutesBar"):moveBelow(mgr("hoursBar"))
mgr("secondsBar"):moveBelow(mgr("minutesBar"))

mgr("foregroundBar"):moveBelow(mgr("backgroundSpinner"))

mgr("hoursSpinner"):moveBelow(mgr("foregroundBar"))
mgr("minutesSpinner"):moveBelow(mgr("foregroundBar"), "centered")
mgr("secondsSpinner"):moveBelow(mgr("foregroundBar"), "flushRight")

local updateTimeBars = function()
    local t = os.date("*t")
    mgr("hoursBar"):value(t.hour)
    mgr("minutesBar"):value(t.min)
    mgr("secondsBar"):value(t.sec)
    mgr("hoursSpinner"):value(t.hour)
    mgr("minutesSpinner"):value(t.min)
    mgr("secondsSpinner"):value(t.sec)
end

module.timer   = timer.doEvery(1, updateTimeBars):start()
updateTimeBars()

module.mgr = mgr

return module

