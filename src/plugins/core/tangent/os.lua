local plugin = {
    id = "core.tangent.os",
    group = "core",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    return deps.tangentManager.controls:group(i18n("macOS"))
end

return plugin