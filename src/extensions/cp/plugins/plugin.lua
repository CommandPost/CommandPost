local plugin = {}
plugin.__index = plugin

function plugin.init(pluginTable, status, scriptFile)
	pluginTable._status = status
	pluginTable._scriptFile = scriptFile
	return setmetatable(pluginTable, plugin)
end

function plugin:getGroup()
	return self.group
end

function plugin:getStatus()
	return self._status
end

function plugin:setStatus(status)
	self._status = status
end

function plugin:getScriptFile()
	return self._scriptFile
end

function plugin:setModule(module)
	self._module = module
end

function plugin:getModule()
	return self._module
end

function plugin:setRootPath(rootPath)
	self._rootPath = rootPath
end

function plugin:getRootPath()
	return self._rootPath
end

function plugin:setDependencies(dependencies)
	self._dependencies = dependencies
end

function plugin:getDependencies()
	return self._dependencies
end

function plugin:addDependent(dependentPlugin)
	if not self._dependents then
		self._dependents = {}
	end
	self._dependents[#self._dependents+1] = dependentPlugin
end

function plugin:getDependents()
	return self._dependents
end

return plugin