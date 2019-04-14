--- === cp.apple.finalcutpro.plugins ===
---
--- Scans an entire system for Final Cut Pro Effects, Generators, Titles & Transitions.
---
--- Usage:
--- ```lua
---     require("cp.apple.finalcutpro"):plugins():scan()
--- ```

local require                   = require

local hs                        = hs

local log                       = require "hs.logger".new "scan"

local audiounit                 = require "hs.audiounit"
local fnutils                   = require "hs.fnutils"
local fs                        = require "hs.fs"
local notify                    = require "hs.notify"
local pathwatcher               = require "hs.pathwatcher"

local archiver                  = require "cp.plist.archiver"
local config                    = require "cp.config"
local fcpStrings                = require "cp.apple.finalcutpro.strings"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local localeID                  = require "cp.i18n.localeID"
local localized                 = require "cp.localized"
local plist                     = require "cp.plist"
local strings                   = require "cp.strings"
local text                      = require "cp.web.text"
local tools                     = require "cp.tools"
local watcher                   = require "cp.watcher"

local fcpApp                    = require "cp.apple.finalcutpro.app"

local v                         = require "semver"

local contains                  = fnutils.contains
local copy                      = fnutils.copy
local doesDirectoryExist        = tools.doesDirectoryExist
local ensureDirectoryExists     = tools.ensureDirectoryExists
local getLocalizedName          = localized.getLocalizedName
local insert, remove            = table.insert, table.remove
local pathToAbsolute            = fs.pathToAbsolute
local unescapeXML               = text.unescapeXML

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- THEME_PATTERN -> string
-- Constant
-- Theme Pattern
local THEME_PATTERN = ".*<theme>(.+)</theme>.*"

-- FLAGS_PATTERN -> string
-- Constant
-- Flags Pattern
local FLAGS_PATTERN = ".*<flags>(.+)</flags>.*"

-- OBSOLETE_FLAG -> number
-- Constant
-- Obsolete Flag
local OBSOLETE_FLAG = 2

-- CP_FCP_CACHE_FOLDER -> string
-- Constant
-- Final Cut Pro Cache Folder Name.
local CP_FCP_CACHE_FOLDER = "Final Cut Pro"

-- CP_FCP_CACHE_PATH -> string
-- Constant
-- User Plugin Cache Path.
local CP_FCP_CACHE_PATH = config.cachePath .. "/" .. CP_FCP_CACHE_FOLDER

-- CORE_AUDIO_PREFERENCES_PATH -> string
-- Constant
-- Core Audio Preferences File Path
local CORE_AUDIO_PREFERENCES_PATH = "/System/Library/Components/CoreAudio.component/Contents/Info.plist"

-- AUDIO_UNITS_CACHE_PATH -> string
-- Constant
-- Path to the Audio Units Cache
local AUDIO_UNITS_CACHE_PATH = "~/Library/Preferences/com.apple.audio.InfoHelper.plist"

-- EFFECTS_PRESET_PATH -> string
-- Constant
-- Effects Preset Path
local EFFECTS_PRESET_PATH = "~/Library/Application Support/ProApps/Effects Presets"

-- USER_COLOR_PRESETS_PATH -> string
-- Constant
-- User Color Presets Path
local USER_COLOR_PRESETS_PATH = "~/Library/Application Support/ProApps/Color Presets"

-- USER_MOTION_TEMPLATES_PATH -> string
-- Constant
-- User Motion Templates Path
local USER_MOTION_TEMPLATES_PATH = "~/Movies/Motion Templates.localized"

-- APP_EFFECTS_PRESETS_STRINGS_PATH -> string
-- Constant
-- App Effects Preset Path
local APP_EFFECTS_PRESETS_STRINGS_PATH = "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFColorPresetsLocalizable.strings"

-- MOTION_TEMPLATE_PATH -> string
-- Constant
-- Motion Template Path
local MOTION_TEMPLATE_PATH = "/Library/Application Support/Final Cut Pro/Templates.localized"

-- PLUGIN_TYPES -> table
-- Constant
-- Table of the different audio/video/transition/generator types.
local PLUGIN_TYPES = {
    videoEffect = "videoEffect",
    audioEffect = "audioEffect",
    title       = "title",
    generator   = "generator",
    transition  = "transition",
}

--------------------------------------------------------------------------------
-- REMINDER:
-- Use this to find strings easily:
--
-- hs.inspect(require("cp.apple.finalcutpro.strings"):findKeys("360° Noise Reduction"))
--------------------------------------------------------------------------------

--- BUILT_IN_PLUGINS -> table
--- Constant
--- Table of built-in plugins
local BUILT_IN_PLUGINS = {
    --------------------------------------------------------------------------------
    -- Built-in Effects:
    --------------------------------------------------------------------------------
    [PLUGIN_TYPES.videoEffect] = {
        ["FFEffectCategoryColor"]   = { "FFCorrectorColorBoard", "PAEColorCurvesEffectDisplayName", "PAECorrectorEffectDisplayName", "PAELUTEffectDisplayName", "HDRTools::Filter Name", "PAEHSCurvesEffectDisplayName", "HSVAdjust::Filter Name" },
        ["FFMaskEffect"]            = { "FFSplineMaskEffect", "FFShapeMaskEffect", "FFSimpleMask" },
        ["Stylize"]                 = { "DropShadow::Filter Name" },
        ["FFEffectCategoryKeying"]  = { "Keyer::Filter Name", "LumaKeyer::Filter Name" },
        ["FFEffectCategoryBasics"]  = { "FFNoiseReduction" },
        ["FFEffectCategory360"]     = { "360 Noise Reduction::Filter Name" },
    },

    --------------------------------------------------------------------------------
    -- Built-in Transitions:
    --------------------------------------------------------------------------------
    [PLUGIN_TYPES.transition] = {
        ["Transitions::Dissolves"] = { "CrossDissolve::Filter Name", "DipToColorDissolve::Transition Name", "FFTransition_OpticalFlow" },
        ["Movements"] = { "SpinSlide::Transition Name", "Swap::Transition Name", "RippleTransition::Transition Name", "Mosaic::Transition Name", "PageCurl::Transition Name", "PuzzleSlide::Transition Name", "Slide::Transition Name" },
        ["Objects"] = { "Cube::Transition Name", "StarIris::Transition Name", "Doorway::Transition Name" },
        ["Wipes"] = { "BandWipe::Transition Name", "CenterWipe::Transition Name", "CheckerWipe::Transition Name", "ChevronWipe::Transition Name", "OvalIris::Transition Name", "ClockWipe::Transition Name", "GradientImageWipe::Transition Name", "Inset Wipe::Transition Name", "X-Wipe::Transition Name", "EdgeWipe::Transition Name" },
        ["Blurs"] = { "CrossZoom::Transition Name", "CrossBlur::Transition Name" },
    },
}

-- BUILT_IN_EDEL_EFFECTS -> table
-- Constant
-- Table of Built-in Soundtrack Pro EDEL Effects.
local BUILT_IN_EDEL_EFFECTS = {
    ["Distortion"] = {
        "Bitcrusher",
        "Clip Distortion",
        "Distortion",
        "Distortion II",
        "Overdrive",
        "Phase Distortion",
        "Ringshifter",
    },
    ["Echo"] = {
        "Delay Designer",
        "Modulation Delay",
        "Stereo Delay",
        "Tape Delay",
    },
    ["EQ"] = {
        "AutoFilter",
        "Channel EQ", -- This isn't actually listed as a Logic plugin in FCPX, but it is.
        "Fat EQ",
        "Linear Phase EQ",
    },
    ["Levels"] = {
        "Adaptive Limiter",
        "Compressor",
        "Enveloper",
        "Expander",
        "Gain",
        "Limiter",
        "Multichannel Gain",
        "Multipressor",
        "Noise Gate",
        "Spectral Gate",
        "Surround Compressor",
    },
    ["Modulation"] = {
        "Chorus",
        "Ensemble",
        "Flanger",
        "Phaser",
        "Scanner Vibrato",
        "Tremolo"
    },
    ["Spaces"] = {
        "PlatinumVerb",
        "Space Designer",
    },
    ["Specialized"] = {
        "Correlation Meter",
        "Denoiser",
        "Direction Mixer",
        "Exciter",
        "MultiMeter",
        "Stereo Spread",
        "SubBass",
        "Test Oscillator",
    },
    ["Voice"] = {
        "DeEsser",
        "Pitch Correction",
        "Pitch Shifter",
        "Vocal Transformer",
    },
}

-- MOTION_TEMPLATE_TYPES -> table
-- Constant
-- Table of the different Motion Template Extensions
local MOTION_TEMPLATE_TYPES = {
    ["Effects"] = {
        type = PLUGIN_TYPES.videoEffect,
        extension = "moef",
    },
    ["Transitions"] = {
        type = PLUGIN_TYPES.transition,
        extension = "motr",
    },
    ["Generators"] = {
        type = PLUGIN_TYPES.generator,
        extension = "motn",
    },
    ["Titles"] = {
        type = PLUGIN_TYPES.title,
        extension = "moti",
    }
}

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.finalcutpro.plugins.types -> table
--- Constant
--- Table of the different audio/video/transition/generator types.
mod.types = PLUGIN_TYPES

--- cp.apple.finalcutpro.plugins.scanned <cp.prop: boolean>
--- Variable
--- Returns `true` if Final Cut Pro plugins have been scanned, otherwise `false`.
mod.scanned = config.prop("finalCutProScanned", false)

-- getFolderSize(path, size) -> number | nil
-- Function
-- Gets the folder size by adding up individual files and subfolders.
--
-- Parameters:
--  * path - The path to the folder
--
-- Returns:
--  * The size as a number of `nil` if something goes wrong.
local function getFolderSize(path, size)
    if type(path) ~= "string" then
        return
    end
    size = size or 0
    local iterFn, dirObj = fs.dir(path)
    if iterFn then
        for file in iterFn, dirObj do
            if file ~= "." and file ~= ".." then
                local attributes = fs.attributes(path .. file)
                if attributes then
                    if attributes.mode == "directory" then
                        local result = getFolderSize(path .. file .. "/")
                        if result then
                            size = size + result
                        end
                    elseif attributes.mode == "file" then
                        size = size + attributes.size
                    end
                end
            end
        end
    end
    return size
end

-- doesCacheDirectoryExist() -> boolean
-- Function
-- Ensures the cache directory exists.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`
local function doesCacheDirectoryExist()
    return ensureDirectoryExists("~/Library/Caches", hs.processInfo.bundleID, CP_FCP_CACHE_FOLDER) ~= nil
end

--- cp.apple.finalcutpro.plugins:scanSystemAudioUnits(locale) -> none
--- Function
--- Scans for Validated Audio Units, and saves the results to a cache for faster subsequent startup times.
---
--- Parameters:
---  * locale   - the locale to scan in.
---
--- Returns:
---  * None
function mod.mt:scanSystemAudioUnits(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- Restore from cache:
    --------------------------------------------------------------------------------
    local cache = {}
    local cacheFile = AUDIO_UNITS_CACHE_PATH

    local attrs = fs.attributes(cacheFile)
    local currentModification = attrs and attrs.modification
    local lastModification = config.get("audioUnitsCacheModification", nil)
    local audioUnitsCache = json.read(CP_FCP_CACHE_PATH .. "/Audio Units.cpCache")

    if currentModification and lastModification and audioUnitsCache and currentModification == lastModification then
        for _, data in pairs(audioUnitsCache) do
            local coreAudioPlistPath = data.coreAudioPlistPath or nil
            local audioEffect = data.audioEffect or nil
            local category = data.category or nil
            local plugin = data.plugin or nil
            local loc = data.locale or nil
            self:registerPlugin(coreAudioPlistPath, audioEffect, category, "OS X", plugin, loc)
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Get the full list of Audio Unit Effects:
    --------------------------------------------------------------------------------
    local effects = audiounit.getAudioEffectNames()
    local audioEffect = PLUGIN_TYPES.audioEffect

    if effects and next(effects) ~= nil then

        local coreAudioPlistPath = CORE_AUDIO_PREFERENCES_PATH
        local coreAudioPlistData = plist.fileToTable(coreAudioPlistPath)

        for _, fullName in pairs(effects) do
            local category, plugin = string.match(fullName, "^(.-):%s*(.*)$")
            --------------------------------------------------------------------------------
            -- CoreAudio Audio Units:
            --------------------------------------------------------------------------------
            if coreAudioPlistData and category == "Apple" then
                --------------------------------------------------------------------------------
                -- Look up the alternate name:
                --------------------------------------------------------------------------------
                for _, component in pairs(coreAudioPlistData["AudioComponents"]) do
                    if component.name == fullName then
                        category = "Specialized"
                        local tags = component.tags
                        if tags then
                            if contains(tags, "Pitch") then category = "Voice"
                            elseif contains(tags, "Delay") then category = "Echo"
                            elseif contains(tags, "Reverb") then category = "Spaces"
                            elseif contains(tags, "Equalizer") then category = "EQ"
                            elseif contains(tags, "Dynamics Processor") then category = "Levels"
                            elseif contains(tags, "Distortion") then category = "Distortion" end
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Cache Plugin:
            --------------------------------------------------------------------------------
            table.insert(cache, {
                coreAudioPlistPath = coreAudioPlistPath,
                audioEffect = audioEffect,
                category = category,
                plugin = plugin,
                locale = locale.code,
            })

            self:registerPlugin(coreAudioPlistPath, audioEffect, category, "OS X", plugin, locale)

        end

        --------------------------------------------------------------------------------
        -- Save Cache:
        --------------------------------------------------------------------------------
        if currentModification and #cache ~= 0 then
            if doesCacheDirectoryExist() then
                if json.write(CP_FCP_CACHE_PATH .. "/Audio Units.cpCache", cache) then
                    config.set("audioUnitsCacheModification", currentModification)
                else
                    log.ef("Failed to cache Audio Units.")
                end
            end
        else
            log.ef("Failed to cache Audio Units.")
        end
    else
        log.ef("Failed to scan for Audio Units.")
    end

end

--- cp.apple.finalcutpro.plugins:scanAppEffectsPresets(locale) -> none
--- Function
--- Scans Final Cut Pro Built-in Effects Presets
---
--- Parameters:
---  * `locale`    - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanAppEffectsPresets(locale)
    local data = plist.fileToTable(fcpApp:path() .. APP_EFFECTS_PRESETS_STRINGS_PATH)
    if data then
        local videoEffect = PLUGIN_TYPES.videoEffect
        local category = fcpStrings:find("FFColorPresetsCategory", locale)
        for _, name in pairs(data) do
            self:registerPlugin(nil, videoEffect, category, nil, name, locale.code)
        end
    end
end

--- cp.apple.finalcutpro.plugins:scanUserEffectsPresets(locale) -> none
--- Function
--- Scans Final Cut Pro Effects Presets
---
--- Parameters:
---  * `locale`    - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanUserEffectsPresets(locale)
    locale = localeID(locale)

    --------------------------------------------------------------------------------
    -- User Presets Path:
    --------------------------------------------------------------------------------
    local path = pathToAbsolute(EFFECTS_PRESET_PATH)

    --------------------------------------------------------------------------------
    -- Restore from cache:
    --------------------------------------------------------------------------------
    local cache = {}

    local currentSize = getFolderSize(path)
    local lastSize = config.get("userEffectsPresetsCacheModification", nil)
    local userEffectsPresetsCache = json.read(CP_FCP_CACHE_PATH .. "/User Effects Presets.cpCache")

    if currentSize and lastSize and userEffectsPresetsCache and currentSize == lastSize then
        for _, data in pairs(userEffectsPresetsCache) do
            local effectPath = data.effectPath or nil
            local effectType = data.effectType or nil
            local category = data.category or nil
            local plugin = data.plugin or nil
            local lan = data.locale or nil
            self:registerPlugin(effectPath, effectType, category, "Final Cut", plugin, lan)
        end
        return
    end

    local videoEffect, audioEffect = PLUGIN_TYPES.videoEffect, PLUGIN_TYPES.audioEffect
    if doesDirectoryExist(path) then
        local iterFn, dirObj = fs.dir(path)
        if not iterFn then
            log.ef("An error occured in cp.apple.finalcutpro.plugins:scanUserEffectsPresets: %s", dirObj)
        else
            for file in iterFn, dirObj do
                local plugin = string.match(file, "(.+)%.effectsPreset")
                if plugin then
                    local effectPath = path .. "/" .. file
                    local preset = archiver.unarchiveFile(effectPath)
                    if preset then
                        local category = preset.category
                        local effectType = preset.effectType or preset.presetEffectType
                        if category then
                            local type = effectType == "effect.audio.effect" and audioEffect or videoEffect
                            self:registerPlugin(effectPath, type, category, "Final Cut", plugin, locale)

                            --------------------------------------------------------------------------------
                            -- Cache Plugin:
                            --------------------------------------------------------------------------------
                            table.insert(cache, {
                                effectPath = effectPath,
                                effectType = type,
                                category = category,
                                plugin = plugin,
                                locale = locale.code,
                            })

                        end
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Save Cache:
        --------------------------------------------------------------------------------
        if currentSize and #cache ~= 0 then
            if doesCacheDirectoryExist() then
                if json.write(CP_FCP_CACHE_PATH .. "/User Effects Presets.cpCache", cache) then
                    config.set("userEffectsPresetsCacheModification", currentSize)
                else
                    log.ef("Failed to cache User Effects Presets.")
                end
            end
        else
            log.ef("Failed to cache User Effects Presets.")
        end

    end
end

--- cp.apple.finalcutpro.plugins:scanUserColorPresets(locale) -> none
--- Function
--- Scans Final Cut Pro User Color Presets
---
--- Parameters:
---  * `locale` - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanUserColorPresets(locale)
    locale = localeID(locale)

    --------------------------------------------------------------------------------
    -- User Presets Path:
    --------------------------------------------------------------------------------
    local path = pathToAbsolute(USER_COLOR_PRESETS_PATH)

    --------------------------------------------------------------------------------
    -- Restore from cache:
    --------------------------------------------------------------------------------
    local cache = {}

    local CACHE_ID = "userColorPresetsCacheChecksum"
    local CACHE_FILENAME = "User Color Presets.cpCache"

    local currentSize = getFolderSize(path)
    local lastSize = config.get(CACHE_ID, nil)
    local userEffectsPresetsCache = json.read(CP_FCP_CACHE_PATH .. "/" .. CACHE_FILENAME)

    if currentSize and lastSize and userEffectsPresetsCache and currentSize == lastSize then
        for _, data in pairs(userEffectsPresetsCache) do
            local effectPath = data.effectPath or nil
            local effectType = data.effectType or nil
            local category = data.category or nil
            local plugin = data.plugin or nil
            local lan = data.locale or nil
            self:registerPlugin(effectPath, effectType, category, nil, plugin, lan)
        end
        return
    end

    local category = fcpStrings:find("FFColorPresetsCategory", locale)
    local videoEffect = PLUGIN_TYPES.videoEffect
    if doesDirectoryExist(path) then
        local iterFn, dirObj = fs.dir(path)
        if not iterFn then
            log.ef("An error occured in cp.apple.finalcutpro.plugins:scanUserEffectsPresets: %s", dirObj)
        else
            for file in iterFn, dirObj do
                local plugin = string.match(file, "(.+)%.cboard")
                if plugin then
                    local effectPath = path .. "/" .. file
                    local preset = archiver.unarchiveFile(effectPath)
                    if preset then
                        local root = preset.root
                        if root then
                            local name = root.name
                            if category then
                                self:registerPlugin(effectPath, videoEffect, category, nil, name, locale)
                                --------------------------------------------------------------------------------
                                -- Cache Plugin:
                                --------------------------------------------------------------------------------
                                table.insert(cache, {
                                    effectPath = effectPath,
                                    effectType = videoEffect,
                                    category = category,
                                    plugin = name,
                                    locale = locale.code,
                                })

                            end
                        end
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Save Cache:
        --------------------------------------------------------------------------------
        if currentSize and #cache ~= 0 then
            if doesCacheDirectoryExist() then
                if json.write(CP_FCP_CACHE_PATH .. "/" .. CACHE_FILENAME, cache) then
                    config.set(CACHE_ID, currentSize)
                else
                    log.ef("Failed to cache User Color Presets.")
                end
            end
        else
            log.ef("Failed to cache User Color Presets.")
        end

    end
end

-- getMotionTheme(filename) -> string | nil
-- Function
-- Process a plugin so that it's added to the current scan
--
-- Parameters:
--  * filename - Filename of the plugin
--
-- Returns:
--  * The theme name, or `nil` if not found.
--
-- Notes:
--  * getMotionTheme("~/Movies/Motion Templates.localized/Effects.localized/3065D03D-92D7-4FD9-B472-E524B87B5012.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.moef")
local function getMotionTheme(filename)
    filename = filename and pathToAbsolute(filename)
    if filename then
        local inTemplate = false
        local theme = nil
        local flags = nil

        --------------------------------------------------------------------------------
        -- Reads through the motion file, looking for the template/theme elements:
        --------------------------------------------------------------------------------
        local file = io.open(filename,"r")
        while theme == nil or flags == nil do
            local line = file:read("*l")
            if line == nil then break end
            if not inTemplate then
                inTemplate = tools.endsWith(line, "<template>")
            end
            if inTemplate then
                theme = theme or line:match(THEME_PATTERN)
                flags = line:match(FLAGS_PATTERN) or flags
                if tools.endsWith(line, "</template>") then
                    break
                end
            end
        end
        file:close()

        --------------------------------------------------------------------------------
        -- Unescape the theme text:
        --------------------------------------------------------------------------------
        theme = theme and unescapeXML(theme) or nil

        --------------------------------------------------------------------------------
        -- Convert flags to a number for checking:
        --------------------------------------------------------------------------------
        flags = flags and tonumber(flags) or 0
        local isObsolete = (flags & OBSOLETE_FLAG) == OBSOLETE_FLAG
        return theme, isObsolete
    end
    return nil
end
mod._getMotionTheme = getMotionTheme

-- getPluginName(path, pluginExt, locale) -> boolean
-- Function
-- Checks if the specified path is a plugin directory, and returns the plugin name.
--
-- Parameters:
--  * `path`        - The path to the directory to check
--  * `pluginExt`   - The plugin extensions to check for.
--  * `locale`      - The locale.
--
-- Returns:
--  * The plugin name.
--  * The plugin theme.
--  * `true` if the plugin is obsolete
local function getPluginName(path, pluginExt, locale)
    if path and doesDirectoryExist(path) then
        locale = localeID(locale)
        local localName, realName = getLocalizedName(path, locale)
        if realName then
            local targetExt = "."..pluginExt
            local iterFn, dirObj = fs.dir(path)
            if not iterFn then
                log.ef("An error occured in cp.apple.finalcutpro.plugins.getPluginName: %s", dirObj)
            else
                for file in iterFn, dirObj do
                    if tools.endsWith(file, targetExt) then
                        local name = file:sub(1, (targetExt:len()+1)*-1)
                        local pluginPath = path .. "/" .. name .. targetExt
                        if name == realName then
                            name = localName
                        end
                        local theme, isObsolete = getMotionTheme(pluginPath)
                        return name, theme, isObsolete
                    end
                end
            end
        end
    end
    return nil, nil, nil
end
mod._getPluginName = getPluginName

--- cp.apple.finalcutpro.plugins:scanPluginsDirectory(locale, path, filter) -> boolean
--- Method
--- Scans a root plugins directory. Plugins directories have a standard structure which comes in two flavours:
---
---   1. <type>/<plugin name>/<plugin name>.<ext>
---   2. <type>/<group>/<plugin name>/<plugin name>.<ext>
---   3. <type>/<group>/<theme>/<plugin name>/<plugin name>.<ext>
---
--- This is somewhat complicated by 'localization', wherein each of the folder levels may have a `.localized` extension. If this is the case, it will contain a subfolder called `.localized`, which in turn contains files which describe the local name for the folder in any number of locales.
---
--- This function will drill down through the contents of the specified `path`, assuming the above structure, and then register any contained plugins in the `locale` provided. Other locales are ignored, other than some use of English when checking for specific effect types (Effect, Generator, etc.).
---
--- Parameters:
---  * `locale`   - The locale code to scan for (e.g. "en" or "fr").
---  * `path`       - The path of the root plugin directory to scan.
---  * `checkFn`    - A function which will receive the path being scanned and return `true` if it should be scanned.
---
--- Returns:
---  * `true` if the plugin directory was successfully scanned.
function mod.mt:scanPluginsDirectory(locale, path, checkFn)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- Check that the directoryPath actually exists:
    --------------------------------------------------------------------------------
    path = pathToAbsolute(path)
    if not path then
        log.wf("The provided path does not exist: '%s'", path)
        return false
    end

    --------------------------------------------------------------------------------
    -- Check that the directoryPath is actually a directory:
    --------------------------------------------------------------------------------
    local attrs = fs.attributes(path)
    if not attrs or attrs.mode ~= "directory" then
        log.ef("The provided path is not a directory: '%s'", path)
        return false
    end

    local failure = false

    --------------------------------------------------------------------------------
    -- Loop through the files in the directory:
    --------------------------------------------------------------------------------
    local iterFn, dirObj = fs.dir(path)
    if not iterFn then
        log.ef("An error occured in cp.apple.finalcutpro.plugins:scanPluginsDirectory: %s", dirObj)
    else
        for file in iterFn, dirObj do
            if file:sub(1,1) ~= "." then
                local typePath = path .. "/" .. file
                local typeNameEN = getLocalizedName(typePath, "en")
                local mt = MOTION_TEMPLATE_TYPES[typeNameEN]
                if mt then
                    local plugin = {
                        type = mt.type,
                        extension = mt.extension,
                        check = checkFn or function() return true end,
                    }
                    failure = failure or not self:scanPluginTypeDirectory(locale, typePath, plugin)
                end
            end
        end
    end
    return not failure
end

-- cp.apple.finalcutpro.plugins:handlePluginDirectory(locale, path, plugin) -> boolean
-- Method
-- Handles a Plugin Directory.
--
-- Parameters:
--  * `locale`    - The locale to scan with.
--  * `path`        - The path to the plugin type directory.
--  * `plugin`      - A table containing the plugin details collected so far.
--
-- Returns:
--  * `true` if it's a legit plugin directory, even if we didn't register it, otherwise `false` if it's not a plugin directory.
function mod.mt:handlePluginDirectory(locale, path, plugin)
    local pluginName, themeName, obsolete = getPluginName(path, plugin.extension, locale)
    if pluginName then
        plugin.name = pluginName
        plugin.themeLocal = themeName or plugin.themeLocal -- NOTE: Chris switched this around, as themeName should take priority.
        --------------------------------------------------------------------------------
        -- Only register it if not obsolete and if the check function
        -- passes (if present):
        --------------------------------------------------------------------------------
        if not obsolete and plugin:check() then
            self:registerPlugin(
                path,
                plugin.type,
                plugin.categoryLocal,
                plugin.themeLocal,
                plugin.name,
                locale
            )
        end
        --------------------------------------------------------------------------------
        -- Return true if it's a legit plugin directory, even if we didn't register it.
        --------------------------------------------------------------------------------
        return true
    end
    --------------------------------------------------------------------------------
    -- Return false if it's not a plugin directory.
    --------------------------------------------------------------------------------
    return false
end

-- cp.apple.finalcutpro.plugins:scanPluginTypeDirectory(locale, path, plugin) -> boolean
-- Method
-- Scans a folder as a plugin type folder, such as 'Effects', 'Transitions', etc. The contents will be folders that are 'groups' of plugins, containing related plugins.
--
-- Parameters:
--  * `locale`    - The locale to scan with.
--  * `path`        - The path to the plugin type directory.
--  * `plugin`      - A table containing the plugin details collected so far.
--
-- Returns:
--  * `true` if the folder was scanned successfully.
function mod.mt:scanPluginTypeDirectory(locale, path, plugin)
    locale = localeID(locale)
    local failure = false
    local iterFn, dirObj = fs.dir(path)
    if not iterFn then
        log.ef("An error occured in cp.apple.finalcutpro.plugins:scanPluginTypeDirectory: %s", dirObj)
    else
        for file in iterFn, dirObj do
            if file:sub(1,1) ~= "." then
                local p = copy(plugin)
                local childPath = path .. "/" .. file
                local attrs = fs.attributes(childPath)
                if attrs and attrs.mode == "directory" then
                    if not self:handlePluginDirectory(locale, childPath, p) then
                        p.categoryLocal, p.categoryReal = getLocalizedName(childPath, locale)
                        failure = failure or not self:scanPluginCategoryDirectory(locale, childPath, p)
                    end
                end
            end
        end
    end

    return not failure
end

--- cp.apple.finalcutpro.plugins:scanPluginCategoryDirectory(locale, path, plugin) -> boolean
--- Method
--- Scans a folder as a plugin category folder. The contents will be folders that are either theme folders or actual plugins.
---
--- Parameters:
---  * `locale`        - The locale to scan with.
---  * `path`            - The path to the plugin type directory
---  * `plugin`      - A table containing the plugin details collected so far.
---
--- Returns:
---  * `true` if the folder was scanned successfully.
function mod.mt:scanPluginCategoryDirectory(locale, path, plugin)
    locale = localeID(locale)
    local failure = false
    local iterFn, dirObj = fs.dir(path)
    if not iterFn then
        log.ef("An error occured in cp.apple.finalcutpro.plugins:scanPluginsDirectory: %s", dirObj)
    else
        for file in iterFn, dirObj do
            if file:sub(1,1) ~= "." then
                local p = copy(plugin)
                local childPath = path .. "/" .. file
                local attrs = fs.attributes(childPath)
                if attrs and attrs.mode == "directory" then
                    if not self:handlePluginDirectory(locale, childPath, p) then
                        p.themeLocal, p.themeReal = getLocalizedName(childPath, locale)
                        failure = failure or not self:scanPluginThemeDirectory(locale, childPath, p)
                    end
                end
            end
        end
    end

    return not failure
end

--- cp.apple.finalcutpro.plugins:scanPluginThemeDirectory(locale, path, plugin) -> boolean
--- Method
--- Scans a folder as a plugin theme folder. The contents will be plugin folders.
---
--- Parameters:
---  * `locale`        - The locale to scan with.
---  * `path`            - The path to the plugin type directory
---  * `plugin`          - A table containing the plugin details collected so far.
---
--- Returns:
---  * `true` if the folder was scanned successfully.
function mod.mt:scanPluginThemeDirectory(locale, path, plugin)
    locale = localeID(locale)
    local iterFn, dirObj = fs.dir(path)
    if not iterFn then
        log.ef("An error occured in cp.apple.finalcutpro.plugins:scanPluginThemeDirectory: %s", dirObj)
    else
        for file in iterFn, dirObj do
            if file:sub(1,1) ~= "." then
                local p = copy(plugin)
                local pluginPath = path .. "/" .. file
                local attrs = fs.attributes(pluginPath)
                if attrs and attrs.mode == "directory" then
                    --------------------------------------------------------------------------------
                    -- Maybe there's a subdirectory?
                    --------------------------------------------------------------------------------
                    local iterFnTwo, dirObjTwo = fs.dir(pluginPath)
                    if iterFnTwo then
                        local hasTemplate = false
                        local ext = plugin.extension
                        local extLen = (ext:len() + 1) * -1
                        for fileTwo in iterFnTwo, dirObjTwo do
                            if fileTwo:sub(extLen) == "." .. ext then
                                hasTemplate = true
                            end
                        end
                        if hasTemplate then
                            self:handlePluginDirectory(locale, pluginPath, p)
                        else
                            --------------------------------------------------------------------------------
                            -- Try going down another level:
                            --------------------------------------------------------------------------------
                            self:scanPluginCategoryDirectory(locale, pluginPath, p)
                        end
                    end
                end
            end
        end
    end
    return true
end

--- cp.apple.finalcutpro.plugins:registerPlugin(path, type, categoryName, themeName, pluginName, locale) -> plugin
--- Method
--- Registers a plugin with the specified details.
---
--- Parameters:
---  * `path`           - The path to the plugin directory.
---  * `type`           - The type of plugin
---  * `categoryName`   - The category name, in the specified locale.
---  * `themeName`      - The theme name, in the specified locale. May be `nil` if not in a theme.
---  * `pluginName`     - The plugin name, in the specified locale.
---  * `locale`         - The `cp.i18n.localeID` or string code for same (e.g. "en", "fr", "de")
---
--- Returns:
---  * The plugin object.
---
--- Notes:
---  * `locale` defaults to the current Final Cut Pro locale if nothing is supplied.
function mod.mt:registerPlugin(path, theType, categoryName, themeName, pluginName, locale)

    locale = localeID(locale) or fcpApp:currentLocale()

    local plugins = self._plugins
    if not plugins then
        plugins = {}
        self._plugins = plugins
    end

    local lang = plugins[locale.code]
    if not lang then
        lang = {}
        plugins[locale.code] = lang
    end

    local types = lang[theType]
    if not types then
        types = {}
        lang[theType] = types
    end

    local plugin = {
        path = path,
        type = theType,
        category = categoryName,
        theme = themeName,
        name = pluginName,
        locale = locale.code,
    }
    insert(types, plugin)
    --------------------------------------------------------------------------------
    -- Caching:
    --------------------------------------------------------------------------------
    if mod._motionTemplatesToCache then
        insert(mod._motionTemplatesToCache, plugin)
    end
    return plugin
end

--- cp.apple.finalcutpro.plugins:reset() -> none
--- Method
--- Resets all the cached plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:reset()
    self._plugins = {}
    mod.scanned(false)
end

--- cp.apple.finalcutpro.plugins:effectBundleStrings() -> table
--- Method
--- Returns all the Effect Bundle Strings.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The effect bundle strings in a table.
function mod.mt:effectBundleStrings()
    local source = self._effectBundleStrings
    if not source then
        local context = {
            appPath = fcpApp:path(),
            locale = fcpApp:currentLocale().aliases,
        }
        source = strings.new():context(context):fromPlist("${appPath}/Contents/Frameworks/Flexo.framework/Resources/${locale}.lproj/FFEffectBundleLocalizable.strings")
        self._effectBundleStrings = source
    end
    return source
end

--- cp.apple.finalcutpro.plugins:translateEffectBundle(input, locale) -> none
--- Method
--- Translates an Effect Bundle Item.
---
--- Parameters:
---  * input - The original name
---  * locale - The locale code you want to attempt to translate to
---
--- Returns:
---  * The translated value for `input` in the specified locale, if present.
function mod.mt:translateEffectBundle(input, locale)
    locale = localeID(locale)
    local context = { locale = locale.aliases }
    return self:effectBundleStrings():find(input, context) or input
end

--- cp.apple.finalcutpro.plugins:scanAppAudioEffectBundles() -> none
--- Method
--- Scans the Audio Effect Bundles directories.
---
--- Parameters:
---  * directoryPath - Directory to scan
---
--- Returns:
---  * None
function mod.mt:scanAppAudioEffectBundles(locale)
    locale = localeID(locale)
    local audioEffect = PLUGIN_TYPES.audioEffect
    local path = fcpApp:path() .. "/Contents/Frameworks/Flexo.framework/Resources/Effect Bundles"
    if doesDirectoryExist(path) then
        local iterFn, dirObj = fs.dir(path)
        if not iterFn then
            log.ef("An error occured in cp.apple.finalcutpro.plugins:scanAppAudioEffectBundles: %s", dirObj)
        else
            for file in iterFn, dirObj do
                --------------------------------------------------------------------------------
                -- Example: Alien.Voice.audio.effectBundle
                --------------------------------------------------------------------------------
                local name, category, type = string.match(file, "^([^%.]+)%.([^%.]+)%.([^%.]+)%.effectBundle$")
                if name and type == "audio" then
                    local plugin = self:translateEffectBundle(name, locale)
                    self:registerPlugin(path .. "/" .. file, audioEffect, category, "Final Cut", plugin, locale)
                end
            end
        end
    end
end

--- cp.apple.finalcutpro.plugins:scanAppMotionTemplates(locale) -> none
--- Method
--- Scans for app-provided Final Cut Pro Plugins.
---
--- Parameters:
---  * `locale`    - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanAppMotionTemplates(locale)
    locale = localeID(locale)
    local fcpPath = fcpApp:path()
    self:scanPluginsDirectory(locale, fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized")
    self:scanPluginsDirectory(
        locale,
        fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized",
        --------------------------------------------------------------------------------
        -- We filter out the 'Simple' category here, since it contains
        -- unlisted iMovie titles.
        --------------------------------------------------------------------------------
        function(plugin) return plugin.categoryReal ~= "Simple" end
    )
end

--- cp.apple.finalcutpro.plugins:scanUserMotionTemplates(locale) -> none
--- Method
--- Scans for user-provided Final Cut Pro Plugins.
---
--- Parameters:
---  * `locale`    - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanUserMotionTemplates(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- User Motion Templates Path:
    --------------------------------------------------------------------------------
    local path = pathToAbsolute(USER_MOTION_TEMPLATES_PATH)
    if not path then
        return nil
    end

    --------------------------------------------------------------------------------
    -- Restore from cache:
    --------------------------------------------------------------------------------
    local currentSize = getFolderSize(path)
    local lastSize = config.get("userMotionTemplatesCacheSize", nil)
    local userMotionTemplatesCache = json.read(CP_FCP_CACHE_PATH .. "/User Motion Templates.cpCache")
    if currentSize and lastSize and currentSize == lastSize then
        if userMotionTemplatesCache and userMotionTemplatesCache[locale.code] and #userMotionTemplatesCache[locale.code] > 0 then
            --------------------------------------------------------------------------------
            -- Restore from cache:
            --------------------------------------------------------------------------------
            for _, data in pairs(userMotionTemplatesCache[locale.code]) do
                self:registerPlugin(data.path, data.type, data.category, data.theme, data.name, data.locale)
            end
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Scan for User Motion Templates:
    --------------------------------------------------------------------------------
    mod._motionTemplatesToCache = nil
    mod._motionTemplatesToCache = {}
    local result = self:scanPluginsDirectory(locale, path)
    if result and currentSize then
        --------------------------------------------------------------------------------
        -- Save to cache:
        --------------------------------------------------------------------------------
        local cache = { [locale.code] = mod._motionTemplatesToCache }
        if json.write(CP_FCP_CACHE_PATH .. "/User Motion Templates.cpCache", cache) then
            config.set("userMotionTemplatesCacheSize", currentSize)
        else
            log.ef("Failed to cache User Motion Templates.")
        end
        mod._motionTemplatesToCache = nil
    end
    return result
end

--- cp.apple.finalcutpro.plugins:scanSystemMotionTemplates(locale) -> none
--- Method
--- Scans for system-provided Final Cut Pro Plugins.
---
--- Parameters:
---  * `locale`    - The locale to scan for.
---
--- Returns:
---  * None
function mod.mt:scanSystemMotionTemplates(locale)
    locale = localeID(locale)

    --------------------------------------------------------------------------------
    -- User Motion Templates Path:
    --------------------------------------------------------------------------------
    local path = pathToAbsolute(MOTION_TEMPLATE_PATH)
    if not path then
        return nil
    end

    --------------------------------------------------------------------------------
    -- Restore from cache:
    --------------------------------------------------------------------------------
    local currentSize = getFolderSize(path)
    local lastSize = config.get("systemMotionTemplatesCacheSize", nil)
    local systemMotionTemplatesCache = json.read(CP_FCP_CACHE_PATH .. "/System Motion Templates.cpCache")

    if currentSize and lastSize and currentSize == lastSize then
        if systemMotionTemplatesCache and systemMotionTemplatesCache[locale.code] and #systemMotionTemplatesCache[locale.code] > 0 then
            --------------------------------------------------------------------------------
            -- Restore from cache:
            --------------------------------------------------------------------------------
            for _, data in pairs(systemMotionTemplatesCache[locale.code]) do
                self:registerPlugin(data.path, data.type, data.category, data.theme, data.name, data.locale)
            end
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Scan for User Motion Templates:
    --------------------------------------------------------------------------------
    mod._motionTemplatesToCache = nil
    mod._motionTemplatesToCache = {}
    local result = self:scanPluginsDirectory(locale, path)
    if result and currentSize then
        --------------------------------------------------------------------------------
        -- Save to cache:
        --------------------------------------------------------------------------------
        local cache = { [locale.code] = mod._motionTemplatesToCache }
        if json.write(CP_FCP_CACHE_PATH .. "/System Motion Templates.cpCache", cache) then
            config.set("systemMotionTemplatesCacheSize", currentSize)
        else
            log.ef("Failed to cache System Motion Templates.")
        end
        mod._motionTemplatesToCache = nil
    end
    return result

end

--- cp.apple.finalcutpro.plugins:scanAppEdelEffects() -> none
--- Method
--- Scans for Soundtrack Pro EDEL Effects.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:scanAppEdelEffects(locale)
    locale = localeID(locale)
    local audioEffect = PLUGIN_TYPES.audioEffect
    for category, plugins in pairs(BUILT_IN_EDEL_EFFECTS) do
        for _, plugin in ipairs(plugins) do
            self:registerPlugin(nil, audioEffect, category, "Logic", plugin, locale)
        end
    end
end

--- cp.apple.finalcutpro.plugins:effectStrings() -> table
--- Method
--- Returns a table of Effects Strings.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of effect strings.
function mod.mt:effectStrings()
    local source = self._effectStrings
    if not source then
        source = strings.new():context({
            appPath = fcpApp:path(),
            locale = fcpApp:currentLocale().aliases,
        })
        source:fromPlist("${appPath}/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/${locale}.lproj/Localizable.strings")
        source:fromPlist("${appPath}/Contents/Frameworks/Flexo.framework/Versions/A/Resources/${locale}.lproj/FFLocalizable.strings")
        self._effectStrings = source
    end
    return source
end

-- translateInternalEffect(input, locale) -> none
-- Function
-- Translates an Effect Bundle Item
--
-- Parameters:
--  * input - The original name
--  * locale - The `localeID` code you want to attempt to translate to
--
-- Returns:
--  * Result as string
--
-- Notes:
--  * require("cp.plist").fileToTable("/Applications/Final Cut Pro.app/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/English.lproj/Localizable.strings")
--  * translateInternalEffect("Draw Mask", "en")
function mod.mt:translateInternalEffect(input, locale)
    locale = localeID(locale)
    local context = {
        locale = locale.aliases
    }
    return self:effectStrings():find(input, context) or input
end

--- cp.apple.finalcutpro.plugins:app() -> plugins
--- Method
--- Returns the `cp.apple.finalcutpro` object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro` object.
function mod.mt:app()
    return self._app
end

--- cp.apple.finalcutpro.plugins:ofType(type[, locale]) -> table
--- Method
--- Finds the plugins of the specified type (`types.videoEffect`, etc.) and if provided, locale.
---
--- Parameters:
---  * `type`        - The plugin type. See `types` for the complete list.
---  * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
---  * A table of the available plugins of the specified type.
function mod.mt:ofType(type, locale)
    locale = localeID(locale)
    local plugins = self._plugins
    local bestLocale = fcpApp:bestSupportedLocale(locale) or fcpApp:currentLocale()
    if not bestLocale then
        log.wf("Unsupported locale was requested: %s", locale.code)
        return nil
    end

    if not plugins or not plugins[bestLocale.code] then
        plugins = self:scan(bestLocale)
    else
        plugins = plugins[bestLocale.code]
    end
    return plugins and plugins[type]
end

--- cp.apple.finalcutpro.plugins:videoEffects([locale]) -> table
--- Method
--- Finds the 'video effect' plugins.
---
--- Parameters:
---  * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
---  * A table of the available plugins.
function mod.mt:videoEffects(locale)
    locale = localeID(locale)
    return self:ofType(PLUGIN_TYPES.videoEffect, locale)
end

--- cp.apple.finalcutpro.plugins:audioEffects([locale]) -> table
--- Method
--- Finds the 'audio effect' plugins.
---
--- Parameters:
---  * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
---  * A table of the available plugins.
function mod.mt:audioEffects(locale)
    locale = localeID(locale)
    return self:ofType(PLUGIN_TYPES.audioEffect, locale)
end

--- cp.apple.finalcutpro.plugins:titles([locale]) -> table
--- Method
--- Finds the 'title' plugins.
---
--- Parameters:
---  * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
---  * A table of the available plugins.
function mod.mt:titles(locale)
    locale = localeID(locale)
    return self:ofType(PLUGIN_TYPES.title, locale)
end

--- cp.apple.finalcutpro.plugins:transitions([locale]) -> table
--- Method
--- Finds the 'transitions' plugins.
---
--- Parameters:
--- * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
--- * A table of the available plugins.
function mod.mt:transitions(locale)
    locale = localeID(locale)
    return self:ofType(PLUGIN_TYPES.transition, locale)
end

--- cp.apple.finalcutpro.plugins:generators([locale]) -> table
--- Method
--- Finds the 'generator' plugins.
---
--- Parameters:
---  * `locale`    - The locale code to search for (e.g. "en"). Defaults to the current FCPX langauge.
---
--- Returns:
---  * A table of the available plugins.
function mod.mt:generators(locale)
    locale = localeID(locale)
    return self:ofType(PLUGIN_TYPES.generator, locale)
end

--- cp.apple.finalcutpro.plugins:scanAppBuiltInPlugins([locale]) -> None
--- Method
--- Scan Built In Plugins.
---
--- Parameters:
---  * `locale`    - The `cp.i18n.localeID` code to search for. Defaults to the current FCPX langauge.
---
--- Returns:
---  * None
function mod.mt:scanAppBuiltInPlugins(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- Add Supported locales, Plugin Types & Built-in Effects to Results Table:
    --------------------------------------------------------------------------------
    for pluginType,categories in pairs(BUILT_IN_PLUGINS) do
        for category,plugins in pairs(categories) do
            category = self:translateInternalEffect(category, locale)
            for _,plugin in pairs(plugins) do
                self:registerPlugin(nil, pluginType, category, nil, self:translateInternalEffect(plugin, locale), locale)
            end
        end
    end
end

-- cp.apple.finalcutpro.plugins:_loadPluginVersionCache(rootPath, version, locale, searchHistory) -> boolean
-- Method
-- Tries to load the cached plugin list from the specified root path. It will search previous version history if enabled and available.
--
-- Parameters:
--  * `rootPath`         - The path the version folders are stored under.
--  * `version`          - The FCPX version number.
--  * `locale`         - The locale to load.
--  * `searchHistory`    - If `true`, previous versions of this minor version will be searched.
--
-- Notes:
--  * When `searchHistory` is `true`, it will only search to the `0` patch level. E.g. `10.3.2` will stop searching at `10.3.0`.
function mod.mt:_loadPluginVersionCache(rootPath, version, locale, searchHistory)
    locale = localeID(locale)
    version = type(version) == "string" and v(version) or version
    local filePath = pathToAbsolute(string.format("%s/%s/plugins.%s.cpCache", rootPath, version, locale.code))
    if filePath then
        local file = io.open(filePath, "r")
        if file then
            local content = file:read("*all")
            file:close()
            local result = json.decode(content)
            self._plugins[locale.code] = result
            return result ~= nil
        end
    elseif searchHistory and version.patch > 0 then
        return self:_loadPluginVersionCache(rootPath, v(version.major, version.minor, version.patch-1), locale, searchHistory)
    end
    return false
end

--- cp.apple.finalcutpro.plugins.clearCaches() -> boolean
--- Function
--- Clears any local caches created for tracking the plugins.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the caches have been cleared successfully.
---
--- Notes:
---  * Does not uninstall any of the actual plugins.
function mod.mt.clearCaches()
    local cachePath = pathToAbsolute(CP_FCP_CACHE_PATH)
    if cachePath then
        local ok, err = tools.rmdir(cachePath, true)
        if not ok then
            log.ef("Unable to remove user plugin cache: %s", err)
            return false
        end
    end
    config.set("audioUnitsCacheModification", nil)
    config.set("userEffectsPresetsCacheModification", nil)
    config.set("userMotionTemplatesCacheSize", nil)
    config.set("systemMotionTemplatesCacheSize", nil)
    return true
end

-- cp.apple.finalcutpro.plugins:_loadAppPluginCache(locale) -> boolean
-- Method
-- Attempts to load the app-bundled plugin list from the cache.
--
-- Parameters:
--  * `locale` - The localeID to load for.
--
-- Returns:
--  * `true` if the cache was loaded successfully.
function mod.mt:_loadAppPluginCache(locale)
    locale = localeID(locale)
    local fcpVersion = fcpApp:versionString()
    if not fcpVersion then
        return false
    end

    return self:_loadPluginVersionCache(CP_FCP_CACHE_PATH, fcpVersion, locale, false)
end

-- cp.apple.finalcutpro.plugins:_saveAppPluginCache(locale) -> boolean
-- Method
-- Saves the current plugin cache as the 'app-bundled' cache.
--
-- Note: This should only be called before any system or user level plugins are loaded!
--
-- Parameters:
--  * `locale`     The locale
--
-- Returns:
--  * `true` if the cache was saved successfully.
function mod.mt:_saveAppPluginCache(locale)
    locale = localeID(locale)
    local fcpVersion = fcpApp:version()
    if not fcpVersion then
        log.ef("Failed to detect Final Cut Pro version: %s", fcpVersion)
        return false
    end
    local version = tostring(fcpVersion)
    if not version then
        log.ef("Failed to translate Final Cut Pro version: %s", version)
        return false
    end
    local path = ensureDirectoryExists("~/Library/Caches", "org.latenitefilms.CommandPost", "Final Cut Pro", version)
    if not path then
        return false
    end
    local cachePath = path .. "/plugins."..locale.code..".cpCache"
    local plugins = self._plugins[locale.code]
    if plugins then
        local file = io.open(cachePath, "w")
        if file then
            file:write(json.encode(plugins))
            file:close()
            return true
        end
    else
        --------------------------------------------------------------------------------
        -- Remove it:
        --------------------------------------------------------------------------------
        os.remove(cachePath)
    end
    return false
end

-- cp.apple.finalcutpro.plugins:scanAppPlugins(locale) -> none
-- Method
-- Scans App Plugins for a specific locale.
--
-- Parameters:
--  * locale - The locale you want to scan for.
--
-- Returns:
--  * None
function mod.mt:scanAppPlugins(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- First, try loading from the cache:
    --------------------------------------------------------------------------------
    if not self:_loadAppPluginCache(locale) then
        --------------------------------------------------------------------------------
        -- Scan Built-in Plugins:
        --------------------------------------------------------------------------------
        self:scanAppBuiltInPlugins(locale)

        --------------------------------------------------------------------------------
        -- Scan Soundtrack Pro EDEL Effects:
        --------------------------------------------------------------------------------
        self:scanAppEdelEffects(locale)

        --------------------------------------------------------------------------------
        -- Scan Audio Effect Bundles:
        --------------------------------------------------------------------------------
        self:scanAppAudioEffectBundles(locale)

        --------------------------------------------------------------------------------
        -- Scan App Motion Templates:
        --------------------------------------------------------------------------------
        self:scanAppMotionTemplates(locale)

        --------------------------------------------------------------------------------
        -- Scan Built-in Effects Presets:
        --------------------------------------------------------------------------------
        self:scanAppEffectsPresets(locale)

        --------------------------------------------------------------------------------
        -- Save all of the above to the cache:
        --------------------------------------------------------------------------------
        self:_saveAppPluginCache(locale)
    end

end

-- cp.apple.finalcutpro.plugins:scanSystemPlugins(locale) -> none
-- Method
-- Scans System Plugins for a specific locale.
--
-- Parameters:
--  * locale - The locale code you want to scan for.
--
-- Returns:
--  * None
function mod.mt:scanSystemPlugins(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- Scan System-level Motion Templates:
    --------------------------------------------------------------------------------
    self:scanSystemMotionTemplates(locale)

    --------------------------------------------------------------------------------
    -- Scan System Audio Units:
    --------------------------------------------------------------------------------
    self:scanSystemAudioUnits(locale)
end

-- cp.apple.finalcutpro.plugins:scanUserPlugins(locale) -> none
-- Method
-- Scans User Plugins for a specific locale.
--
-- Parameters:
--  * locale - The locale code you want to scan for.
--
-- Returns:
--  * None
function mod.mt:scanUserPlugins(locale)
    locale = localeID(locale)
    --------------------------------------------------------------------------------
    -- Scan User Effect Presets:
    --------------------------------------------------------------------------------
    self:scanUserEffectsPresets(locale)

    --------------------------------------------------------------------------------
    -- Scan Legacy User Color Presets:
    --------------------------------------------------------------------------------
    self:scanUserColorPresets(locale)

    --------------------------------------------------------------------------------
    -- Scan User Motion Templates:
    --------------------------------------------------------------------------------
    self:scanUserMotionTemplates(locale)
end

--- cp.apple.finalcutpro.plugins:scan() -> none
--- Function
--- Scans Final Cut Pro for Effects, Transitions, Generators & Titles
---
--- Parameters:
---  * fcp - the `cp.apple.finalcutpro` instance
---
--- Returns:
---  * None
function mod.mt:scan(locale)

    locale = localeID(locale) or fcpApp:currentLocale()

    --------------------------------------------------------------------------------
    -- Reset Results Table:
    --------------------------------------------------------------------------------
    self:reset()

    --------------------------------------------------------------------------------
    -- Scan app-bundled plugins:
    --------------------------------------------------------------------------------
    self:scanAppPlugins(locale)

    --------------------------------------------------------------------------------
    -- Scan system-installed plugins:
    --------------------------------------------------------------------------------
    self:scanSystemPlugins(locale)

    --------------------------------------------------------------------------------
    -- Scan user-installed plugins:
    --------------------------------------------------------------------------------
    self:scanUserPlugins(locale)

    --------------------------------------------------------------------------------
    -- Scan has been completed:
    --------------------------------------------------------------------------------
    mod.scanned(true)

    return self._plugins[locale]
end

--- cp.apple.finalcutpro.plugins.scanned() -> boolean
--- Function
--- Gets if the system has been scanned.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` is scanned otherwise `false`.
function mod.mt.scanned()
    return mod.scanned()
end

--- cp.apple.finalcutpro.plugins:scanAll() -> nil
--- Method
--- Scans all supported locales, loading them into memory.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function mod.mt:scanAll()
    for _,locale in ipairs(fcpApp:supportedLocales()) do
        self:scan(locale)
    end
end

--- cp.apple.finalcutpro.plugins:watch(events) -> watcher
--- Method
--- Adds a watcher for the provided events table.
---
--- Parameters:
---  * events - A table of events to watch.
---
--- Returns:
---  * The watcher object
---
--- Notes:
---  * The events can be:
---  ** videoEffects
---  ** audioEffects
---  ** transitions
---  ** titles
---  ** generators
function mod.mt:watch(events)
    return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.plugins:unwatch(id) -> watcher
--- Method
--- Unwatches a watcher with a specific ID.
---
--- Parameters:
---  * id - The ID of the watcher to stop watching.
---
--- Returns:
---  * The watcher object.
function mod.mt:unwatch(a)
    return self._watcher:unwatch(a)
end

-- doesPathContainPlugins(path) -> boolean
-- Function
-- Does a path contain Final Cut Pro plugins?
--
-- Parameters:
--  * path - The path to check
--
-- Returns:
--  * `true` if found, otherwise `false`
local function doesPathContainPlugins(path)
    local attr = fs.attributes(path)
    if attr and attr.mode == "directory" then
        local iterFn, dirObj = fs.dir(path)
        if iterFn then
            for file in iterFn, dirObj do
                if file:sub(1,1) ~= "." then
                    if doesPathContainPlugins(path .. "/" .. file) then
                        return true
                    end
                end
            end
        end
    elseif attr and attr.mode == "file" then
        if path:sub(-5) == ".moef" or
        path:sub(-5) == ".motr" or
        path:sub(-5) == ".motn" or
        path:sub(-5) == ".moti" or
        path:sub(-14) == ".effectsPreset" or
        path:sub(-7) == ".cboard" then
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.plugins.new(fcp) -> plugins object
--- Function
--- Creates a new Plugins Object.
---
--- Parameters:
---  * fcp - The `cp.apple.finalcutpro` object
---
--- Returns:
---  * The plugins object
function mod.new(fcp)
    local o = {
        _app = fcp,
        _plugins = {},
        _watcher = watcher.new("videoEffects", "audioEffects", "transitions", "titles", "generators"),
        _pathwatchers = {},
    }

    --------------------------------------------------------------------------------
    -- Setup Path Watches:
    --------------------------------------------------------------------------------
    local notifier = notify.new(function()
        mod.mt.clearCaches()
        hs.reload()
    end, {
        title = i18n("newPluginDetected"),
        subTitle = i18n("needsToRestartToUpdateConsole"),
        informativeText = i18n("restartCommandPostNow"),
        actionButtonTitle = i18n("restart"),
        otherButtonTitle = i18n("ignore"),
        alwaysPresent = true,
        hasActionButton = true,
        withdrawAfter = 15,
    })
    local paths = {
        USER_MOTION_TEMPLATES_PATH .. "/",  -- "~/Movies/Motion Templates.localized"
        EFFECTS_PRESET_PATH .. "/",         -- "~/Library/Application Support/ProApps/Effects Presets"
        USER_COLOR_PRESETS_PATH .. "/",     -- "~/Library/Application Support/ProApps/Color Presets"
        MOTION_TEMPLATE_PATH .. "/",        -- "/Library/Application Support/Final Cut Pro/Templates.localized"
    }
    for _, path in pairs(paths) do
        local pw = pathwatcher.new(path, function(files)
            for _, file in pairs(files) do
                if doesPathContainPlugins(file) then
                    notifier:send()
                    return
                end
            end
        end):start()
        table.insert(o._pathwatchers, pw)
    end

    return setmetatable(o, mod.mt)
end

--------------------------------------------------------------------------------
-- Ensures the cache is cleared if the config is reset:
--------------------------------------------------------------------------------
config.watch({
    reset = mod.mt.clearCaches,
})

return mod
