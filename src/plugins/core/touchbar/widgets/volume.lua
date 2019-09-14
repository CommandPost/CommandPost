--- === plugins.core.touchbar.widgets.volume ===
---
--- Volume Slider

local require = require

local audiodevice		= require("hs.audiodevice")
local image				  = require("hs.image")
local touchbar 			= require("hs._asm.undocumented.touchbar")


local mod = {}

-- ID -> string
-- Constant
-- Volume ID
local ID = "volume"

--- plugins.core.touchbar.widgets.volume.widget() -> `hs._asm.undocumented.touchbar.item`
--- Function
--- The Widget
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.undocumented.touchbar.item`
function mod.widget()

    mod.item = touchbar.item.newSlider(ID)
        :sliderMin(0)
        :sliderMax(100)
        :sliderMinImage(image.imageFromName(image.systemImageNames.TouchBarVolumeDownTemplate))
        :sliderMaxImage(image.imageFromName(image.systemImageNames.TouchBarVolumeUpTemplate))
        :sliderValue(mod.defaultOutputDevice:volume() or 0)
        :callback(function(_, value)
            mod.defaultOutputDevice:setVolume(value)
        end)

    return mod.item

end

--- plugins.core.touchbar.widgets.volume.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- Watch for volume changes:
    --------------------------------------------------------------------------------
    mod.defaultOutputDevice = audiodevice.defaultOutputDevice()
        :watcherCallback(function()
            if mod.item then
                mod.item:sliderValue(audiodevice.defaultOutputDevice():volume())
            end
        end)
        :watcherStart()

    --------------------------------------------------------------------------------
    -- Register Widget:
    --------------------------------------------------------------------------------
    local id = ID
    local params = {
        group = "global",
        text = "Volume Slider",
        subText = "Adds a volume slider to the Touch Bar",
        item = mod.widget,
    }
    deps.manager.widgets:new(id, params)

    return mod

end


local plugin = {
    id				= "core.touchbar.widgets.volume",
    group			= "core",
    dependencies	= {
        ["core.touchbar.manager"] = "manager",
    }
}

function plugin.init(deps)
    if touchbar.supported() then
        return mod.init(deps)
    end
end

return plugin
