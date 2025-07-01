--- === plugins.core.mpc ===
---
--- Provides a simple Model Context Protocol (MPC) server that exposes
--- CommandPost actions over HTTP.
---
--- This is an experimental feature for connecting external tools
--- to CommandPost via the Actions API.

local require = require

local hsminweb = require "hs.httpserver.hsminweb"
local json     = require "cp.json"

local mod = {}
mod._server = nil
mod._actionmanager = nil

local function handleRequest(method, path, headers, body)
    if path == "/actions" then
        local ids = mod._actionmanager.handlerIds()
        return json.encode(ids), 200, { ["Content-Type"] = "application/json" }
    end

    local handlerId = path:match("^/actions/(.+)")
    if handlerId then
        local handler = mod._actionmanager.getHandler(handlerId)
        if handler then
            local actions = {}
            for _,choice in ipairs(handler.choices()) do
                table.insert(actions, {
                    text = choice.text,
                    id = handler:actionId(choice.params),
                    params = choice.params
                })
            end
            return json.encode(actions), 200, { ["Content-Type"] = "application/json" }
        else
            return "unknown handler", 404, {}
        end
    end

    if path == "/execute" and method == "POST" then
        local ok, params = pcall(json.decode, body)
        if ok and params.handler and params.params then
            local handler = mod._actionmanager.getHandler(params.handler)
            if handler then
                handler:execute(params.params)
                return "ok", 200, {}
            end
        end
        return "bad request", 400, {}
    end

    return "mpc server", 200, { ["Content-Type"] = "text/plain" }
end

function mod.start(port)
    if mod._server then return mod end
    mod._server = hsminweb.new():setCallback(handleRequest)
    if port then mod._server:port(port) end
    mod._server:start()
    return mod
end

function mod.stop()
    if mod._server then
        mod._server:stop()
        mod._server = nil
    end
end

local plugin = {
    id = "core.mpc",
    group = "core",
    dependencies = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod.start(51234)
end

return plugin
