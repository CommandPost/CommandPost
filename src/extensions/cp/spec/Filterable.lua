local Filterable = {}

--- cp.spec.Filterable:filter(...)
--- 
function Filterable:filter(...)
    self._filters = table.pack(...)
end

return Filterable