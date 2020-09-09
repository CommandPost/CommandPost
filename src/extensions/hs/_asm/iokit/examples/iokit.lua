local module = {}

local iokit = require("hs._asm.iokit")

module.idleTime = function()
    local hid = iokit.servicesForClass("IOHIDSystem")[1]
    local idle = hid:properties().HIDIdleTime
    if type(idle) == "string" then idle = string.unpack("J", idle) end
    return idle >> 30
end

module.vramSize = function()
    local results = {}
    local pci = iokit.servicesForClass("IOPCIDevice")
    for i,v in ipairs(pci) do
        local ioname = v:searchForProperty("IOName")
        if ioname and ioname == "display" then
            local model = v:searchForProperty("model")
            if model then
                local inBytes = true
                local vramSize = v:searchForProperty("VRAM,totalsize")
                if not vramSize then
                    inBytes = false
                    vramSize = v:searchForProperty("VRAM,totalMB")
                end
                if vramSize then
                    if type(vramSize) == "string" then vramSize = string.unpack("J", vramSize) end
                    if inBytes then vramSize = vramSize >> 20 end
                else
                    vramSize = -1
                end
                results[model] = vramSize
            end
        end
    end
    return results
end

module.attachedDevices = function()
    local usb = iokit.servicesForClass("IOUSBDevice")
    local results = {}
    for i,v in ipairs(usb) do
        local properties = v:properties()
        table.insert(results, {
            productName = properties["USB Product Name"],
            vendorName  = properties["USB Vendor Name"],
            productID   = properties["idProduct"],
            vendorID    = properties["idVendor"],
        })
    end
    return results
end

return module
