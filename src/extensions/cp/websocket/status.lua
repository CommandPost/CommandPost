--- === cp.websocket.status ===
---
--- A `table` of statuses used by both `cp.websocket.serial` and `cp.websocket.http` to describe the connection status.

--- cp.websocket.status.opening <string>
--- Constant
--- The socket is attempting to open.

--- cp.websocket.status.open <string>
--- Constant
--- The socket is open.

--- cp.websocket.status.closing <string>
--- Constant
--- The socket is attempting to close.

--- cp.websocket.status.closed <string>
--- Constant
--- The socket is closed.

return {
    opening = "opening",
    open = "open",
    closing = "closing",
    closed = "closed",
}