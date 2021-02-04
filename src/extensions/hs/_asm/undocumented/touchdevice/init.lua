--- === hs._asm.undocumented.touchdevice ===
---
--- This module provides functionality for detecting and using touch information from Multi-Touch devices attached to your Mac.
---
--- Most of the functions and methods provided here rely on undocumented or private functionality provided by the MultitouchSupport framework.  As such thi module is considered experimental and may break at any time should Apple make changes to the framework.
---
--- Portions of this module have been influenced or inspired by code found at the following addresses:
---  * https://github.com/INRIA/libpointing/blob/master/pointing/input/osx/osxPrivateMultitouchSupport.h
---  * https://github.com/calftrail/Touch
---  * https://github.com/jnordberg/FingerMgmt
---  * https://github.com/artginzburg/MiddleClick-Catalina
---  * ...and I'm sure others that have slipped my mind.
---
--- If you feel that I have missed a particular site that should be referenced, or know of a site with additional information that can clarify or expand this module or any of its functions -- many of the informational methods are not fully understood and clarification would be greatly appreciated -- please do not hesitate to submit an issue or pull request at https://github.com/asmagill/hammerspoon_asm.undocumented for consideration.
---
--- Because this module relies on an undocumented framework, this documentation is based on the collection of observations made by a variety of people and shared on the internet and is a best guess -- nothing in here is guaranteed.  If you have more accurate information or observe something in variance with what is documented here, please submit an issue with as much detail as possible.

-- pacakge.loadlib("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", "*")

local USERDATA_TAG = "hs._asm.undocumented.touchdevice"
local module       = require(USERDATA_TAG..".internal")
module.forcetouch  = require(USERDATA_TAG..".forcetouch")
module.watcher     = require(USERDATA_TAG..".watcher")

local objectMT     = hs.getObjectMetatable(USERDATA_TAG)

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

-- local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

local inspect = require("hs.inspect")

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

--- hs._asm.undocumented.touchdevice:details() -> table
--- Method
--- Returns a table containing a summary of the information provided by the informational methods of this module for the the multi-touch device
---
--- Parameters:
---  * None
---
--- Returns:
---  * a table containing key-value pairs corresponding to most of the informational methods provided by this module for the multi-touch device represented by the touchdeviceObject.
---
--- Notes:
---  * The returned table uses the `hs.inspect` module as a `__tostring` metamethod allowing you to display it easily in the Hammerspoon console.
---  * This method is provided as a convenience -- because it invokes a method for each key in the table, when speed is a concern, you should invoke the individual methods for the specific information that you require.
objectMT.details = function(self)
    local detailTable = {
        deviceID                = self:deviceID(),
        builtin                 = self:builtin(),
        supportsForce           = self:supportsForce(),
        opaqueSurface           = self:opaqueSurface(),
        running                 = self:running(),
        alive                   = self:alive(),
        MTHIDDevice             = self:MTHIDDevice(),
        supportsPowerControl    = self:supportsPowerControl(),
        sensorDimensions        = self:sensorDimensions(),
        sensorSurfaceDimensions = self:sensorDimensions(true),
        familyID                = self:familyID(),
        driverType              = self:driverType(),
        GUID                    = self:GUID(),
        driverReady             = self:driverReady(),
        serialNumber            = self:serialNumber(),
        version                 = self:version(),
        productName             = self:productName(),
        forceResponseEnabled    = self:forceResponseEnabled(),
        supportsSilentClick     = self:supportsSilentClick(),
        supportsActuation       = self:supportsActuation(),
    }

    if objectMT.minDigitizerPressure   then detailTable.minDigitizerPressure   = self:minDigitizerPressure()   end
    if objectMT.maxDigitizerPressure   then detailTable.maxDigitizerPressure   = self:maxDigitizerPressure()   end
    if objectMT.digitizerPressureRange then detailTable.digitizerPressureRange = self:digitizerPressureRange() end

    return setmetatable(detailTable, { __tostring = inspect })
end

-- Return Module Object --------------------------------------------------

return module
