#!/usr/bin/env lua

---Simple command line test parser - applies handler[s] specified
-- to XML file (or STDIN) and dumps results<br/>
--

local xml2lua = require("xml2lua")
local treeHandler = require("xmlhandler/tree")
local domHandler = require("xmlhandler/dom")
local printHandler = require("xmlhandler/print")

-- Defaults
_print = nil
_simpletree = nil
_dom = nil 
_file = nil
_debug = nil
_ws = nil
_noentity = nil

_usage = [[
testxml.lua [-print] [-simpletree] [-dom] [-debug] 
            [-ws] [-noentity] [-help] [file]
]]

_help = [[
testxml.lua - Simple command line XML processor

Options:

    -print          : Generate event dump (default)
    -simpletree     : Generate simple tree
    -dom            : Generate DOM-like tree
    -debug          : Print debug info (filename/text)
    -ws             : Do not strip whitespace
    -noentity       : Do not expand entities
    -help           : Print help
    file            : XML File (parse stdin in nil)
]]

index = 1

function setOptions(x)
    if _ws then
        x.options.stripWS = nil
    end
    if _noentity then
        x.options.expandEntities = nil
    end
end

if #arg == 0 then
    print(_usage)
    return
end

while arg[index] do
    --print (arg[index])
    if (string.sub(arg[index],1,1)=='-') then
        if arg[index] == "-print" then
            _print = 1
        elseif arg[index] == "-simpletree" then
            _simpletree= 1
        elseif arg[index] == "-dom" then
            _dom= 1
        elseif arg[index] == "-debug" then
            _debug = 1
        elseif arg[index] == "-ws" then
            _ws = 1
        elseif arg[index] == "-noentity" then
            _noentity = 1
        elseif arg[index] == "-help" then
            print(_usage)
            return
        else 
            print(_usage)
            return
        end
    else 
        -- Filename is last argument if present
        if arg[index+1] then
            print(_usage)
            return
        else 
            _file = arg[index]
        end
    end
    index = index + 1
end

if _file then
    print("File",_file)
    if (_debug) then
        io.write ( "File: ".._file.."\n" )
    end
    --xml = read(openfile(_file,"r"),"*a")

    xml = xml2lua.loadFile(_file)
else
    print(_usage)
    return
end

if _debug then
    io.write ( "----------- XML\n" )
    io.write (xml.."\n")
end

if _print or not (_print or _dom or _simpletree or _print) then
    io.write ( "----------- Print\n" )
    h = printHandler
    x = xml2lua.parser(h)
    setOptions(x)
    x:parse(xml)
end

if _simpletree then
    io.write ( "----------- SimpleTree\n" )
    h = treeHandler
    x = xml2lua.parser(h)
    setOptions(x)
    x:parse(xml)
    xml2lua.printable(h.root)
end

if _dom then
    io.write ( "----------- Dom\n" )
    h = domHandler
    x = xml2lua.parser(h)
    setOptions(x)
    x:parse(xml)
    xml2lua.printable(h.root)
    io.write( "-----------\n")
end
