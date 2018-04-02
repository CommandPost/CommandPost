local audiodevice            = require("hs.audiodevice")

local plugin = {
    id = "core.tangent.os.sound",
    group = "core",
    dependencies = {
        ["core.tangent.os"] = "osGroup",
    }
}

function plugin.init(deps)
    local soundGroup = deps.osGroup:group(i18n("sound"))

    local toggleMute = function()
        local output = audiodevice.defaultOutputDevice()
        if output then
            output:setOutputMuted(not output:outputMuted())
        end
    end

    soundGroup:parameter(0x0AA00001)
        :name(i18n("volume"))
        :name9(i18n("volume9"))
        :name10(i18n("volume10"))
        :minValue(0)
        :maxValue(100)
        :stepSize(5)
        :onGet(function()
            local output = audiodevice.defaultOutputDevice()
            if output then
                return output:outputVolume()
            end
        end)
        :onChange(function(increment)
            local output = audiodevice.defaultOutputDevice()
            if output then
                local volume = output:outputVolume()
                if volume ~= nil then
                    output:setOutputVolume(volume + increment)
                end
            end
        end)
        :onReset(toggleMute)

    local iMuted, iUnmuted = i18n("muted"), i18n("unmuted")
    soundGroup:menu(0x0AA00002)
        :name(i18n("mute"))
        :name9(i18n("mute9"))
        :name10(i18n("mute10"))
        :onGet(function()
            local output = audiodevice.defaultOutputDevice()
            if output then
                return output:outputMuted() and iMuted or iUnmuted
            end
        end)
        :onNext(toggleMute)
        :onPrev(toggleMute)

    return soundGroup
end

return plugin