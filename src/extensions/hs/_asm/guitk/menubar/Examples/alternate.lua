local mb = require("hs._asm.guitk.menubar")

local m   = mb.menu.new("myMenu"):callback(function(...) print("m", timestamp(), finspect(...)) end)

si  = mb.statusitem.new(true):callback(function(...) print("si", timestamp(), finspect(...)) end)
                             :title(hs.styledtext.new("yes", { color = { green = 1 } }))
                             :alternateTitle(hs.styledtext.new("no", { color = { red = 1 } }))
                             :menu(m)

local i = 0
for k, v in hs.fnutils.sortByKeys(mb.menu.item._characterMap) do
--     m:insert(mb.menu.item.new(k):callback(function(...) print("i", timestamp(), finspect(...)) end)
--                                 :keyEquivalent(k)
--     )
    m[#m + 1] = {
        title         = k,
        callback      = (function(...) print("i", timestamp(), finspect(...)) end),
        keyEquivalent = k,
    }

--     m:insert(mb.menu.item.new("Alt " .. k):callback(function(...) print("i", timestamp(), finspect(...)) end)
--                                           :keyEquivalent(k)
--                                           :alternate(true)
--                                           :keyModifiers{ alt = true }
--     )
    m[#m + 1] = {
        title         = "Alt " .. k,
        callback      = (function(...) print("i", timestamp(), finspect(...)) end),
        keyEquivalent = k,
        alternate     = true,
        keyModifiers  = { alt = true },
    }

--     m:insert(mb.menu.item.new("Shift " .. k):callback(function(...) print("i", timestamp(), finspect(...)) end)
--                                             :keyEquivalent(k)
--                                             :alternate(true)
--                                             :keyModifiers{ shift = true }
--     )
    m[#m + 1] = {
        title         = "Shift " .. k,
        callback      = (function(...) print("i", timestamp(), finspect(...)) end),
        keyEquivalent = k,
        alternate     = true,
        keyModifiers  = { shift = true },
    }

    i = (i + 1) % 10
    if i == 0 then m:insert(mb.menu.item.new("-")) end
end
