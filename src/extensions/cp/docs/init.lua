--- === cp.docs ===
---
--- Documentation Tools.
---
--- These tools are for helping generate CommandPost documentation.
---
--- Example Usage:
--- ```lua
--- require("cp.docs").generate()
--- ```

local require = require

local log           = require("hs.logger").new("docs")

local config        = require("cp.config")
local tools         = require("cp.tools")

local execute       = hs.execute


local mod = {}

--- cp.docs.generate() -> none
--- Function
--- Generates the CommandPost Developers Guide.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.generate()
    local path = config.basePath .. "/../../CommandPost/"

    if not tools.doesFileExist(path) then
        log.ef("The CommandPost GitHub Path could not be found: %s", path)
        return
    end

    local output, status = execute([[cd "]] .. path .. [["; ./scripts/build_commandpost_docs.sh]])
    if status then
        log.df("%s", output)
        if mod.updateDeveloperGuideSummary() then
            log.df("Documentation Updated Successfully!")
        end
    else
        log.df("%s", output)
        log.ef("Build Documentation Script Failed.")
    end
end

--- cp.docs.updateDeveloperGuideSummary() -> boolean
--- Function
--- Updates the Developer Guide Summary.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `nil`
function mod.updateDeveloperGuideSummary()

    local summaryPath = config.basePath .. "/../../CommandPost-DeveloperGuide/SUMMARY.md"

    if not tools.doesFileExist(summaryPath) then
        log.ef("Summary file could not be found: %s", summaryPath)
        return
    end

    local cpResults = mod.generateExtensionLinks("cp")
    local pluginResults = mod.generateExtensionLinks("plugins")
    local hsResults = mod.generateExtensionLinks("hs")

    local result = ""

    if cpResults and pluginResults and hsResults then
        result = result .. "\n"
        result = result .. "## CommandPost API" .. "\n"
        result = result .. "\n"
        result = result .. "* [cp](api/cp/cp.md)" .. "\n"
        result = result .. cpResults .. "\n"
        result = result .. "## Bundled Plugins API" .. "\n"
        result = result .. "\n"
        result = result .. "* [plugins](api/plugins/index.md)" .. "\n"
        result = result .. pluginResults .. "\n"
        result = result .. "## Hammerspoon API" .. "\n"
        result = result .. "\n"
        result = result .. "* [hs](api/hs/hs.md)" .. "\n"
        result = result .. hsResults
    end

    local file = io.open(summaryPath, "r")
    if not file then
        log.ef("Could not open file: %s", summaryPath)
        return
    end

    local contents = file:read("*a")
    if not contents then
        log.ef("Could not read file: %s", summaryPath)
        return
    end

    file:close()

    local breakPoint = string.find(contents, "## CommandPost API")

    if not breakPoint then
        log.ef("Could not find '## CommandPost API' in SUMMARY.md.")
        return
    end

    local newContents = string.sub(contents, 1, breakPoint - 2) .. result

    local newFile = io.open(summaryPath, "w+")
    if not newFile then
        log.ef("Could not open file: %s", summaryPath)
        return
    end

    io.output(newFile)
    io.write(newContents)
    io.close(newFile)

    return true

end

--- cp.docs.generateExtensionLinks(folder) -> none
--- Function
--- Returns markup of all of the API links for a specific group of extensions.
---
--- Parameters:
---  * folder - The folder you want to process (i.e. "cp", "plugins" or "hs").
---
--- Returns:
---  * The result as a string, otherwise `nil` if an error occurs.
function mod.generateExtensionLinks(folder)

    if not folder then
        log.ef("Folder needs to be supplied.")
        return
    end

    local path = config.basePath .. "/../../CommandPost-DeveloperGuide/"
    local cpAPIPath = path .. "api/" .. folder .. "/index.md"

    if not tools.doesFileExist(cpAPIPath) then
        log.ef("File could not be found: %s", cpAPIPath)
        return
    end

    local file = io.open(cpAPIPath, "r")
    if not file then
        log.ef("Could not open file: %s", cpAPIPath)
        return
    end

    local contents = file:read("*a")
    if not contents then
        log.ef("Could not read file: %s", cpAPIPath)
        return
    end

    file:close()

    local result = ""
    local lines = tools.lines(contents)

    for i, v in pairs(lines) do
        if string.sub(v, 1, 4 + string.len(folder)) == "| [" .. folder .. "." then

            local endBracketLocation = string.find(v, "]")
            if not endBracketLocation then
                log.ef("Failed to find end bracket on line: %s", i)
                return
            end

            local extension = string.sub(v, 4, endBracketLocation - 1)
            local startPosition = string.find(extension, "%.[^%.]*$")
            local _, dotCount = string.gsub(extension, "%.", "")
            local depthString = string.rep(" ", dotCount) or ""

            result = result .. depthString .. "* [" .. string.sub(extension, startPosition + 1) .. "](api/" .. folder .. "/" .. extension .. ".md)\n"

        end
    end

    return result
end

return mod
