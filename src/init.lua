-- Logger Level (defaults to 'warn' if not specified)
-- hs.logger.defaultLogLevel = 'debug'

-- Load FCPX Hacks:
require("hs.fcpxhacks")

-- TODO: Remove after testing. 
-- This will test that our global/local values are set up correctly by forcing a garbage collection.
hs.timer.doAfter(5, collectgarbage)