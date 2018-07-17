local bench 		= require("cp.bench")
local utf16			= require("cp.utf16")

local config		= require("cp.config")
local TEXT_PATH = config.scriptPath .. "/cp/utf16/unicode/"

local function readFile(filename)
    local file = io.open(filename)
    local content = file:read("*a")
    file:close()
    return content
end

local function run()
    local utf8Text 		= readFile(TEXT_PATH .. "lorem_utf8.txt")
    local utf16leText	= readFile(TEXT_PATH .. "lorem_utf16le.txt")
    local utf16beText	= readFile(TEXT_PATH .. "lorem_utf16be.txt")

    local repeats = 1000

    bench("utf8.codes(..) X "..repeats, function()
        for _ = 1,repeats do
            for _,_ in utf8.codes(utf8Text) do
                -- do nothing
            end
        end
    end)

    bench("utf16.codes(false, ...) X "..repeats, function()
        for _ = 1,repeats do
            for _,_ in utf16.codes(false, utf16leText) do
                -- do nothing
            end
        end
    end)

    bench("utf16.codes(true, ...) X "..repeats, function()
        for _ = 1,repeats do
            for _,_ in utf16.codes(true, utf16beText) do
                -- do nothing
            end
        end
    end)
end

return run