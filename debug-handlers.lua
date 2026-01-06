#!/usr/bin/env hs
-- Debug script to list all registered action handlers

local actionmanager = require "cp.action.manager"

print("=== All Registered Action Handlers ===")
print("Total handlers:", #actionmanager.handlerIds())

for _, id in ipairs(actionmanager.handlerIds()) do
    local handler = actionmanager.getHandler(id)
    if handler then
        print(string.format("  - %s (Group: %s, Label: %s)",
            id,
            handler:group() or "none",
            handler:label() or "none"))
    end
end

print("\n=== Handlers containing 'cmd' ===")
for _, id in ipairs(actionmanager.handlerIds()) do
    if id:lower():find("cmd") then
        print("  - " .. id)
    end
end

print("\n=== Handlers containing 'global' ===")
for _, id in ipairs(actionmanager.handlerIds()) do
    if id:lower():find("global") then
        print("  - " .. id)
    end
end
