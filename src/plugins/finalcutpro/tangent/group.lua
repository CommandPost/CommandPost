local plugin = {
    id = "finalcutpro.tangent.group",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager
    local fcpGroup = tangentManager.controls:group(i18n("finalCutPro"))

    return fcpGroup
end

return plugin