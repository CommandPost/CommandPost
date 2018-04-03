local plugin = {
    id = "core.tangent.global",
    group = "core",
    dependencies = {
        ["core.tangent.manager"]    = "tangentManager",
    }
}

function plugin.init(deps)
    local globalMode = deps.tangentManager.addMode(0x0000000A, i18n("global"))
    return globalMode
end

return plugin