--- === cp.websocket.event ===
---
--- The set of event types received from websocket connections.

--- cp.websocket.event.opening <string>
--- Constant
--- The socket is attempting to open.

--- cp.websocket.event.opened <string>
--- Constant
--- The socket has opened.

--- cp.websocket.event.closing <string>
--- Constant
--- The socket is attempting to close.

--- cp.websocket.event.closed <string>
--- Constant
--- The socket has closed.

--- cp.websocket.event.error <string>
--- Constant
--- There was an error. The connection may still be open.

--- cp.websocket.event.message <string>
--- Constant
--- The socket has sent a message.

return {
    opening = "opening",
    opened = "opened",
    closing = "closing",
    closed = "closed",
    error = "error",
    message = "message",
}