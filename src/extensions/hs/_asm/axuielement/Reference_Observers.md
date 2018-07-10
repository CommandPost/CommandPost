hs._asm.axuielement.observer
============================

This submodule allows you to create observers for accessibility elements and be notified when they trigger notifications. Not all notifications are supported by all elements and not all elements support notifications, so some trial and error will be necessary, but for compliant applications, this can allow your code to be notified when an application's user interface changes in some way.

This is very much a work in progress, so bugs and comments are welcome.

For a very basic example, with Safari running, enter the following into your Hammerspoon console:

~~~lua
ax = require("hs._asm.axuielement")
o = ax.observer.new(hs.application("Safari"):pid())
    :callback(function(...) print(hs.inspect(table.pack(...), { newline = " ", indent = "" })) end)
    :addWatcher(ax.windowElement(hs.application("Safari"):allWindows()[1]), "AXTitleChanged")
    :start()
~~~

Now, click on a link or select a bookmark to trigger the callback as the window's title changes.

If you do observe unexpected behavior with the observer submodule (that didn't result in a crash), when submitting a bug report please include the results of `hs.inspect(require("hs._asm.axuielement").observer._internals())` if possible.

### Usage
~~~lua
observer = require("hs._asm.axuielement").observer
~~~

### Contents


##### Module Constructors
* <a href="#new">observer.new(pid) -> observerObject</a>

##### Module Methods
* <a href="#addWatcher">observer:addWatcher(element, notification) -> observerObject</a>
* <a href="#callback">observer:callback([fn | nil]) -> observerObject | fn | nil</a>
* <a href="#isRunning">observer:isRunning() -> boolean</a>
* <a href="#removeWatcher">observer:removeWatcher(element, notification) -> observerObject</a>
* <a href="#start">observer:start() -> observerObject</a>
* <a href="#stop">observer:stop() -> observerObject</a>
* <a href="#watching">observer:watching([element]) -> table</a>

##### Module Constants
* <a href="#notifications">observer.notifications[]</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
observer.new(pid) -> observerObject
~~~
Creates a new observer object for the application with the specified process ID.

Parameters:
 * `pid` - the process ID of the application.

Returns:
 * a new observerObject; generates an error if the pid does not exist or if the object cannot be created.

Notes:
 * If you already have the `hs.application` object for an application, you can get its process ID with `hs.application:pid()`
 * If you already have an `hs._asm.axuielement` from the application you wish to observe (it doesn't have to be the application axuielement object, just one belonging to the application), you can get the process ID with `hs._asm.axuielement:pid()`.

### Module Methods

<a name="addWatcher"></a>
~~~lua
observer:addWatcher(element, notification) -> observerObject
~~~
Registers the specified notification for the specified accesibility element with the observer.

Parameters:
 * `element`      - the `hs._asm.axuielement` representing an accessibility element of the application the observer was created for.
 * `notification` - a string specifying the notification.

Returns:
 * the observerObject; generates an error if watcher cannot be registered

Notes:
 * multiple notifications for the same accessibility element can be registered by invoking this method multiple times with the same element but different notification strings.
 * if the specified element and notification string are already registered, this method does nothing.
 * the notification string is application dependent and can be any string that the application developers choose; some common ones are found in `hs._asm.axuielement.observer.notifications`, but the list is not exhaustive nor is an application or element required to provide them.

- - -

<a name="callback"></a>
~~~lua
observer:callback([fn | nil]) -> observerObject | fn | nil
~~~
Get or set the callback for the observer.

Parameters:
 * `fn` - a function, or an explicit nil to remove, specifying the callback to the observer will invoke when the assigned elements generate notifications.

Returns:
 * If an argument is provided, the observerObject; otherwise the current value.

Notes:
 * the callback should expect 4 arguments and return none. The arguments passed to the callback will be as follows:
   * the observerObject itself
   * the `hs._asm.axuielement` object for the accessibility element which generated the notification
   * a string specifying the specific notification which was received
   * a table containing key-value pairs with more information about the notification, if the element and notification type provide it. Commonly this will be an empty table indicating that no additional detail was provided.

- - -

<a name="isRunning"></a>
~~~lua
observer:isRunning() -> boolean
~~~
Returns true or false indicating whether the observer is currently watching for notifications and generating callbacks.

Parameters:
 * None

Returns:
 * a boolean value indicating whether or not the observer is currently active.

- - -

<a name="removeWatcher"></a>
~~~lua
observer:removeWatcher(element, notification) -> observerObject
~~~
Unregisters the specified notification for the specified accessibility element from the observer.

Parameters:
 * `element`      - the `hs._asm.axuielement` representing an accessibility element of the application the observer was created for.
 * `notification` - a string specifying the notification.

Returns:
 * the observerObject; generates an error if watcher cannot be unregistered

Notes:
 * if the specified element and notification string are not currently registered with the observer, this method does nothing.

- - -

<a name="start"></a>
~~~lua
observer:start() -> observerObject
~~~
Start observing the application and trigger callbacks for the elements and notifications assigned.

Parameters:
 * None

Returns:
 * the observerObject

Notes:
 * This method does nothing if the observer is already running

- - -

<a name="stop"></a>
~~~lua
observer:stop() -> observerObject
~~~
Stop observing the application; no further callbacks will be generated.

Parameters:
 * None

Returns:
 * the observerObject

Notes:
 * This method does nothing if the observer is not currently running

- - -

<a name="watching"></a>
~~~lua
observer:watching([element]) -> table
~~~
Returns a table of the notifications currently registered with the observer.

Parameters:
 * `element` - an optional `hs._asm.axuielement` to return a list of registered notifications for.

Returns:
 * a table containing the currently registered notifications

Notes:
 * If an element is specified, then the table returned will contain a list of strings specifying the specific notifications that the observer is watching that element for.
 * If no argument is specified, then the table will contain key-value pairs in which each key will be an `hs._asm.axuielement` that is being observed and the corresponding value will be a table containing a list of strings specifying the specific notifications that the observer is watching for from from that element.

### Module Constants

<a name="notifications"></a>
~~~lua
observer.notifications[]
~~~
A table of common accessibility object notification names, provided for reference.

Notes:
 * Notifications are application dependent and can be any string that the application developers choose; this list provides the suggested notification names found within the macOS Framework headers, but the list is not exhaustive nor is an application or element required to provide them.

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2017 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>


