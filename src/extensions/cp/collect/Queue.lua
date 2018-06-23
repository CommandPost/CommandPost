--- === cp.collect.Queue ===
---
--- A "double-ended queue" implementation. This allows pushing and popping
--- values to the left or right side of the queue. This can be used for
--- classic 'stack' and 'queue' uses - for a stack, push and pop from one end,
--- for a queue, push and pop from opposite ends.
---
--- `#` will always return the size of the queue.
---
--- The left-most item in the queue wil always be at index `1`, the right-most
--- will be at index `#`.
---
--- You can iterate via `ipairs`, but as with all tables, the queue contains any
--- `nil` values, it will stop at that point. To iterate the whole queue, you
--- need to use the `#` operator. Eg:
---
--- ```lua
--- local q = Queue(1, nil, 3)
--- for i,v in ipairs(q) do print(v) end  -- Outputs "1"
--- for i = 1, #q do print(v) end -- Outputs "1", "nil", "3"
--- ```

-- local log               = require("hs.logger").new("Queue")
-- local inspect           = require("hs.inspect")

local Queue = {}

local DATA = {}

local function getdata(queue)
    local data = queue[DATA]
    if not data then
        error "Expected to receive a Queue"
    end
    return data
end

--- cp.collect.Queue.new([...]) -> cp.collect.Queue
--- Constructor
--- Creates a new Queue.
---
--- Parameters:
---  * ...      - The optional list of values to add to the right of the queue.
---
--- Returns:
---  * the new `Queue`.
---
--- Notes:
---  * You can also create a new queue by calling `Queue(..)` directly.
function Queue.new(...)
    return Queue.pushRight(setmetatable({[DATA] = {left = 0, right = -1}}, Queue.mt), ...)
end

--- cp.collect.Queue.pushLeft(queue, ...) -> cp.collect.Queue
--- Function
--- Pushes the values to the left side of the `queue`.
--- If there are multiple values, then they will be added from right to left.
--- That is to say, the left-most of the new values will be the left-most value of the queue.
---
--- Parameters:
---  * queue        - The queue to push into.
---  * ...          - The values to push.
---
--- Returns:
---  * The same `Queue` instance.
function Queue.pushLeft(queue, ...)
    local data = getdata(queue)
    for i = select("#", ...), 1, -1 do
        local value = select(i, ...)
        local left = data.left - 1
        data.left = left
        data[left] = value
    end
    return queue
end

--- cp.collect.Queue.pushRight(queue, ...) -> cp.collect.Queue
--- Function
--- Pushes the values to the right side of the `queue`.
--- If there are multiple values, then they will be added from left to right.
--- That is to say, the right-most of the new values will be the right-most value of the queue.
---
--- Parameters:
---  * queue        - The queue to push into.
---  * ...          - The values to push.
---
--- Returns:
---  * The same `Queue` instance.
function Queue.pushRight(queue, ...)
    local data = getdata(queue)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        local right = data.right + 1
        data.right = right
        data[right] = value
    end
    return queue
end

--- cp.collect.Queue.popLeft(queue) -> anything
--- Function
--- Removes the left-most value from the `queue` and returns it.
---
--- Parameters:
---  * queue        - The queue to pop from.
---
--- Returns:
---  * The left-most value of the `Queue`.
function Queue.popLeft(queue)
    local data = getdata(queue)
    local left = data.left
    if left > data.right then
        error("Queue is empty")
    end
    local value = data[left]
    data[left] = nil -- to allow garbage collection
    data.left = left + 1
    return value
end

--- cp.collect.Queue.popRight(queue) -> anything
--- Function
--- Removes the right-most value from the `queue` and returns it.
---
--- Parameters:
---  * queue        - The queue to pop from.
---
--- Returns:
---  * The right-most value of the `Queue`.
function Queue.popRight(queue)
    local data = getdata(queue)
    local right = data.right
    if data.left > right then
        error("Queue is empty")
    end
    local value = data[right]
    data[right] = nil -- to allow garbage collection
    data.right = right - 1
    return value
end

--- cp.collect.Queue.peekLeft(queue) -> anything
--- Function
--- Returns the left-most value from the `queue` without removig it.
---
--- Parameters:
---  * queue        - The queue to peek into.
---
--- Returns:
---  * The left-most value of the `Queue`.
function Queue.peekLeft(queue)
    local data = getdata(queue)
    if data.left > data.right then
        error("Queue is empty")
    end
    return data[data.left]
end

--- cp.collect.Queue.peekRight(queue) -> anything
--- Function
--- Returns the right-most value from the `queue` without removig it.
---
--- Parameters:
---  * queue        - The queue to peek into.
---
--- Returns:
---  * The right-most value of the `Queue`.
function Queue.peekRight(queue)
    local data = getdata(queue)
    if data.left > data.right then
        error("Queue is empty")
    end
    return data[data.right]
end

--- cp.collect.Queue.removeItem(queue, item) -> number
--- Function
--- Attempts to remove the specified item from the queue.
--- If the item was found, the index it was found at is returned.
--- If not, `nil` is returned.
---
--- Parameters:
---  * queue        - The queue to modify.
---  * item         - The item to remove, if present.
---
--- Returns:
---  * The index of the item, or `nil` if not found.
---
--- Note:
---  * This call may be very expensive if there are many items in the queue after the specified item.
function Queue.removeItem(queue, item)
    local data = getdata(queue)
    local index = nil
    -- find it...
    for i = data.left,data.right do
        if data[i] == item then
            index = i
            break
        end
    end
    if index then
        -- table.remove is faster, but only works when i > 0
        local right = math.min(0, data.right)
        for i = index,right do
            data[i] = data[i+1]
        end
        if data.right > 0 then
            table.remove(data, math.max(1, data.left))
        end
        data.right = data.right - 1

        -- shift the index relative to the queue
        return index - data.left + 1
    else
        return nil
    end
end

--- cp.collect.Queue.len(queue) -> anything
--- Function
--- Returns the number of items in the queue.
---
--- Parameters:
---  * queue        - The queue to check.
---
--- Returns:
---  * The total number of items.
function Queue.len(queue)
    local data = getdata(queue)
    return data.right - data.left + 1
end

-- the metatable for Queues.
Queue.mt = {
--- cp.collect.Queue:pushLeft(...) -> cp.collect.Queue
--- Method
--- Pushes the values to the left side of the `queue`.
--- If there are multiple values, then they will be added from right to left.
--- That is to say, the left-most of the new values will be the left-most value of the queue.
---
--- Parameters:
---  * ...          - The values to push.
---
--- Returns:
---  * The same `Queue` instance.
    pushLeft = Queue.pushLeft,

--- cp.collect.Queue:pushRight(...) -> cp.collect.Queue
--- Method
--- Pushes the values to the right side of the `queue`.
--- If there are multiple values, then they will be added from left to right.
--- That is to say, the right-most of the new values will be the right-most value of the queue.
---
--- Parameters:
---  * ...          - The values to push.
---
--- Returns:
---  * The same `Queue` instance.
    pushRight = Queue.pushRight,

--- cp.collect.Queue:popLeft() -> anything
--- Method
--- Removes the left-most value from the `queue` and returns it.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The left-most value of the `Queue`.
    popLeft = Queue.popLeft,

--- cp.collect.Queue:popRight() -> anything
--- Method
--- Removes the right-most value from the `queue` and returns it.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The right-most value of the `Queue`.
    popRight = Queue.popRight,

--- cp.collect.Queue:peekLeft() -> anything
--- Method
--- Returns the left-most value from the `queue` without removig it.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The left-most value of the `Queue`.
    peekLeft = Queue.peekLeft,

--- cp.collect.Queue:peekRight() -> anything
--- Method
--- Returns the right-most value from the `queue` without removig it.
---
--- Parameters:
---  * queue        - The queue to peek into.
---
--- Returns:
---  * The right-most value of the `Queue`.
    peekRight = Queue.peekRight,

--- cp.collect.Queue:removeItem(item) -> number
--- Function
--- Attempts to remove the specified item from the queue.
--- If the item was found, the index it was found at is returned.
--- If not, `nil` is returned.
---
--- Parameters:
---  * item         - The item to remove, if present.
---
--- Returns:
---  * The index of the item, or `nil` if not found.
---
--- Note:
---  * This call may be very expensive if there are many items in the queue after the specified item.
    removeItem = Queue.removeItem,

--- cp.collect.Queue:len(queue) -> anything
--- Method
--- Returns the number of items in the queue.
---
--- Parameters:
---  * queue        - The queue to check.
---
--- Returns:
---  * The total number of items.
    len = Queue.len,

    -- metamethods:

    __len = Queue.len,
    -- disallow setting values directly

    __index = function(self, key)
        local value = Queue.mt[key]
        if not value then
            local data = getdata(self)
            if type(key) == "number" then
                value = data[key + data.left - 1]
            end
        end
        return value
    end,

    __newindex = function()
        error "Items in the queue cannot be set directly."
    end,

    __pairs = function(self)
        local function stateless_iter(tbl, k)
            local v
            repeat
                k, v = next(tbl, k)
            until k == nil or type(k) == "number"
            if v then return k,v end
        end

        -- Return an iterator function, the table, starting point
        return stateless_iter, self, nil
      end,

    __tostring = function() return "Queue" end
}

setmetatable(Queue, {
    -- allow creating new Queues via `Queue(...)`
    __call = function(_, ...)
        return Queue.new(...)
    end
})

return Queue
