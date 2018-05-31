hs._asm.guitk
=============

This module provides a window or panel which can be used to display a variety of graphical elements defined in the submodules or other Hammerspoon modules.

In the macOS, all visual elements are contained within a "window", though many of these windows have no extra decorations (title bar, close button, etc.). This module and its submodules is an attempt to provide a generic toolkit so that you can develop whatever type of visual interface you wish from a single set of tools rather then replicating code across multiple modules. Ultimately this module should be able to replace the other drawing or user interface modules and allow you to mix their components or even create completely new ones.

By itself, this module just creates the "window" and its methods describe how (or if) it should be visible, movable, etc. and provides a notification callback for potentially interesting events, for example when the "window" becomes visible, is moved, etc.

See `hs._asm.guitk.manager` for more information on how to populate a guitkObject with visual elements and `hs._asm.guitk.element` for a description of the currently supported visual elements which can included in a guitk window.


### Installation

A precompiled version of this module and its submodules can be found in this directory with a name along the lines of `guitk-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/guitk-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to build this module and its submodules yourself, and have XCode installed on your Mac, the best way (you are welcome to clone the entire repository if you like, but no promises on the current state of anything) is to do the following:

~~~sh
$ svn export https://github.com/asmagill/hammerspoon_asm/trunk/guitk
$ cd guitk
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
$ cd manager
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
$ cd ../element
$ [HS_APPLICATION=/Applications] [PREFIX=~/.hammerspoon] make docs install
~~~

If your Hammerspoon application is located in `/Applications`, you can leave out the `HS_APPLICATION` environment variable, and if your Hammerspoon files are located in their default location, you can leave out the `PREFIX` environment variable.  For most people it will be sufficient to just type `make docs install` in each of the directories specified above.

As always, whichever method you chose, if you are updating from an earlier version it is recommended to fully quit and restart Hammerspoon after installing this module to ensure that the latest version of the module is loaded into memory.

Examples of this module and some of the elements can be found in the [Examples](Examples) subdirectory.

### Usage
~~~lua
guitk = require("hs._asm.guitk")
~~~

### Contents

##### Module Constructors
* <a href="#new">guitk.new(rect, [styleMask]) -> guitkObject</a>
* <a href="#newCanvas">guitk.newCanvas([rect]) -> guitkObject</a>

##### Module Methods
* <a href="#accessibilitySubrole">guitk:accessibilitySubrole([label | nil]) -> guitkObject | string | nil</a>
* <a href="#activeElement">guitk:activeElement([view | nil]) -> boolean | userdata</a>
* <a href="#allowTextEntry">guitk:allowTextEntry([value]) -> guitkObject | boolean</a>
* <a href="#alpha">guitk:alpha([alpha]) -> guitkObject | number</a>
* <a href="#animationBehavior">guitk:animationBehavior([behavior]) -> guitkObject | string</a>
* <a href="#animationDuration">guitk:animationDuration([duration | nil]) -> guitkObject | number | nil</a>
* <a href="#appearance">guitk:appearance([appearance]) -> guitkObject | string</a>
* <a href="#backgroundColor">guitk:backgroundColor([color]) -> guitkObject | color table</a>
* <a href="#bringToFront">guitk:bringToFront([aboveEverything]) -> guitkObject</a>
* <a href="#closeOnEscape">guitk:closeOnEscape([flag]) -> guitkObject | boolean</a>
* <a href="#collectionBehavior">guitk:collectionBehavior([behaviorMask]) -> guitkObject | integer</a>
* <a href="#contentManager">guitk:contentManager([view | nil]) -> guitkObject | manager/element userdata</a>
* <a href="#delete">guitk:delete([fadeOut]) -> none</a>
* <a href="#deleteOnClose">guitk:deleteOnClose([value]) -> guitkObject | boolean</a>
* <a href="#frame">guitk:frame([rect], [animated]) -> guitkObject | rect-table</a>
* <a href="#hasShadow">guitk:hasShadow([state]) -> guitkObject | boolean</a>
* <a href="#hide">guitk:hide([fadeOut]) -> guitkObject</a>
* <a href="#ignoresMouseEvents">guitk:ignoresMouseEvents([state]) -> guitkObject | boolean</a>
* <a href="#isOccluded">guitk:isOccluded() -> boolean</a>
* <a href="#isShowing">guitk:isShowing() -> boolean</a>
* <a href="#isVisible">guitk:isVisible() -> boolean</a>
* <a href="#level">guitk:level([theLevel]) -> guitkObject | integer</a>
* <a href="#notificationCallback">guitk:notificationCallback([fn | nil]) -> guitkObject | fn</a>
* <a href="#notificationMessages">guitk:notificationMessages([notifications, [replace]]) -> guitkObject | table</a>
* <a href="#opaque">guitk:opaque([state]) -> guitkObject | boolean</a>
* <a href="#orderAbove">guitk:orderAbove([guitk2]) -> guitkObject</a>
* <a href="#orderBelow">guitk:orderBelow([guitk2]) -> guitkObject</a>
* <a href="#passthroughCallback">guitk:passthroughCallback([fn | nil]) -> guitkObject | fn | nil</a>
* <a href="#sendToBack">guitk:sendToBack() -> guitkObject</a>
* <a href="#show">guitk:show([fadeIn]) -> guitkObject</a>
* <a href="#simplifiedWindowCallback">guitk:simplifiedWindowCallback([fn]) -> guitkObject</a>
* <a href="#size">guitk:size([size], [animated]) -> guitkObject | rect-table</a>
* <a href="#styleMask">guitk:styleMask([mask]) -> guitkObject | integer</a>
* <a href="#title">guitk:title([title]) -> guitkObject | string</a>
* <a href="#titlebarAppearsTransparent">guitk:titlebarAppearsTransparent([state]) -> guitkObject | boolean</a>
* <a href="#titleVisibility">guitk:titleVisibility([state]) -> guitkObject | currentValue</a>
* <a href="#topLeft">guitk:topLeft([point], [animated]) -> guitkObject | rect-table</a>

##### Module Constants
* <a href="#levels">guitk.levels</a>
* <a href="#masks">guitk.masks[]</a>
* <a href="#notifications">guitk.notifications[]</a>
* <a href="#windowBehaviors">guitk.windowBehaviors[]</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
guitk.new(rect, [styleMask]) -> guitkObject
~~~
Creates a new empty guitk window.

Parameters:
 * `rect`     - a rect-table specifying the initial location and size of the guitk window.
 * `styleMask` - an optional integer specifying the style mask for the window as a combination of logically or'ed values from the [hs._asm.guitk.masks](#masks) table.  Defaults to `titled | closable | resizable | miniaturizable` (a standard macOS window with the appropriate titlebar and decorations).

Returns:
 * the guitk object, or nil if there was an error creating the window.

Notes:
 * a rect-table is a table with key-value pairs specifying the top-left coordinate on the screen of the guitk window (keys `x`  and `y`) and the size (keys `h` and `w`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

- - -

<a name="newCanvas"></a>
~~~lua
guitk.newCanvas([rect]) -> guitkObject
~~~
Creates a new empty guitk window that is transparent and has no decorations.

Parameters:
 * `rect` - an optional rect-table specifying the initial location and size of the guitk window.

Returns:
 * the guitk object, or nil if there was an error creating the window.

Notes:
 * a rect-table is a table with key-value pairs specifying the top-left coordinate on the screen of the guitk window (keys `x`  and `y`) and the size (keys `h` and `w`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * this constructor creates an "invisible" container which is intended to display visual information only and does not accept user interaction by default, similar to an empty canvas created with `hs.canvas.new`. This is a shortcut for the following:
~~~lua
hs._asm.guitk.new(rect, hs._asm.guitk.masks.borderless):backgroundColor{ alpha = 0 }
                                                       :opaque(false)
                                                       :hasShadow(false)
                                                       :ignoresMouseEvents(true)
                                                       :allowTextEntry(false)
                                                       :animationBehavior("none")
                                                       :level(hs._asm.guitk.levels.screenSaver)
~~~
 * If you do not specify `rect`, then the window will have no height or width and will not be able to display its contents; make sure to adjust this with [hs._asm.guitk:frame](#frame) or [hs._asm.guitk:size](#size) once content has been assigned to the window.

### Module Methods

<a name="accessibilitySubrole"></a>
~~~lua
guitk:accessibilitySubrole([label | nil]) -> guitkObject | string | nil
~~~
Get or set the accessibility subrole value this window will report via the Accessibility API when queried.

Parameters:
 * `label` - an optional string or nil, default nil, specifying the accessibility subrole value this guitk window should report. See the notes below.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * The subrole value of a window may be used by accessibility aware applications and Hammerspoon's own `hs.window.filter` to make decisions about how to treat the window.

 * If you specify a non-empty string for this value, the value provided will be reported when this window's subrole is queried.
 * If you specify an empty string (e.g. ""), the default value for this window based upon its properties will be returned when queried.
 * If you specify nil (the default), then the default value for this window based upon its properties will have ".Hammerspoon" appended to the string and this combined value will be returned when queried.

- - -

<a name="activeElement"></a>
~~~lua
guitk:activeElement([view | nil]) -> boolean | userdata
~~~
Get or set the active element for the guitk window.

Parameters:
 * `view` - a userdata representing an element in the guitk window to make the active element, or an explcit nil to make no element active.

Returns:
 * If an argument is provided, returns true or false indicating whether or not the current active element (if any) relinquished focus; otherwise the current value.

Notes:
 * The active element of a window is the element which is currently receiving mouse or keyboard activity from the user when the window is focused.

 * Not all elements can become the active element, for example textfield elements which are neither editable or selectable. If you try to make such an element active, the content manager or guitk window itself will become the active element.
 * Passing an explicit nil to this method will make the content manager or guitk window itself the active element.
   * Making the content manager or guitk window itself the active element has the visual effect of making no element active but leaving the window focus unchanged.

- - -

<a name="allowTextEntry"></a>
~~~lua
guitk:allowTextEntry([value]) -> guitkObject | boolean
~~~
Get or set whether or not the guitk object can accept keyboard entry. Defaults to true.

Parameters:
 * `value` - an optional boolean, default true, which sets whether or not the guitk will accept keyboard input.

Returns:
 * If a value is provided, then this method returns the guitk object; otherwise the current value

Notes:
 * Most controllable elements require keybaord focus even if they do not respond directly to keyboard input.

- - -

<a name="alpha"></a>
~~~lua
guitk:alpha([alpha]) -> guitkObject | number
~~~
Get or set the alpha level of the window representing the guitk object.

Parameters:
 * `alpha` - an optional number, default 1.0, specifying the alpha level (0.0 - 1.0, inclusive) for the window.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="animationBehavior"></a>
~~~lua
guitk:animationBehavior([behavior]) -> guitkObject | string
~~~
Get or set the macOS animation behavior used when the guitk window is shown or hidden.

Parameters:
 * `behavior` - an optional string specifying the animation behavior. The string should be one of the following:
   * "default"        - The automatic animation that’s appropriate to the window type.
   * "none"           - No automatic animation used. This is the default which makes window appearance immediate unless you use the fade time argument with [hs._asm.guitk:show](#show), [hs._asm.guitk:hide](#hide), or [hs._asm.guitk:delete](#delete).
   * "documentWindow" - The animation behavior that’s appropriate to a document window.
   * "utilityWindow"  - The animation behavior that’s appropriate to a utility window.
   * "alertPanel"     - The animation behavior that’s appropriate to an alert window.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * This animation is separate from the fade-in and fade-out options provided with the [hs._asm.guitk:show](#show), [hs._asm.guitk:hide](#hide), and [hs._asm.guitk:delete](#delete) methods and is provided by the macOS operating system itself.

- - -

<a name="animationDuration"></a>
~~~lua
guitk:animationDuration([duration | nil]) -> guitkObject | number | nil
~~~
Get or set the macOS animation duration for smooth frame transitions used when the guitk window is moved or resized.

Parameters:
 * `duration` - a number or nil, default nil, specifying the time in seconds to move or resize by 150 pixels when the `animated` flag is set for [hs._asm.guitk:frame](#frame), [hs._asm.guitk:topLeft](#topLeft), or [hs._asm.guitk:size](#size). An explicit `nil` defaults to the macOS default, which is currently 0.2.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="appearance"></a>
~~~lua
guitk:appearance([appearance]) -> guitkObject | string
~~~
Get or set the appearance name applied to the window decorations for the guitk window.

Parameters:
 * `appearance` - an optional string specifying the name of the appearance style to apply to the window frame and decorations.  Should be one of "aqua", "light", or "dark".

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * Other string values are allowed for forwards compatibility if Apple or third party software adds additional themes.
 * The built in labels are actually shortcuts:
   * "aqua"  is shorthand for "NSAppearanceNameAqua" and is the default.
   * "light" is shorthand for "NSAppearanceNameVibrantLight"
   * "dark"  is shorthand for "NSAppearanceNameVibrantDark" and can be used to mimic the macOS dark mode.
 * This method will return an error if the string provided does not correspond to a recognized appearance theme.

- - -

<a name="backgroundColor"></a>
~~~lua
guitk:backgroundColor([color]) -> guitkObject | color table
~~~
Get or set the color for the background of guitk window.

Parameters:
* `color` - an optional table containing color keys as described in `hs.drawing.color`

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="bringToFront"></a>
~~~lua
guitk:bringToFront([aboveEverything]) -> guitkObject
~~~
Places the guitk window on top of normal windows

Parameters:
 * `aboveEverything` - An optional boolean value that controls how far to the front the guitk window should be placed. True to place the window on top of all windows (including the dock and menubar and fullscreen windows), false to place the webview above normal windows, but below the dock, menubar and fullscreen windows. Defaults to false.

Returns:
 * The webview object

Notes:
 * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.

- - -

<a name="closeOnEscape"></a>
~~~lua
guitk:closeOnEscape([flag]) -> guitkObject | boolean
~~~
If the guitk window is closable, this will get or set whether or not the Escape key is allowed to close the guitk window.

Parameters:
 * `flag` - an optional boolean value which indicates whether the guitk window, when it's style includes `closable` (see [hs._asm.guitk:styleMask](#styleMask)), should allow the Escape key to be a shortcut for closing the window.  Defaults to false.

Returns:
 * If a value is provided, then this method returns the guitk object; otherwise the current value

Notes:
 * If this is set to true, Escape will only close the window if no other element responds to the Escape key first (e.g. if you are editing a textfield element, the Escape will be captured by the text field, not by the guitk window.)

- - -

<a name="collectionBehavior"></a>
~~~lua
guitk:collectionBehavior([behaviorMask]) -> guitkObject | integer
~~~
Get or set the guitk window collection behavior with respect to Spaces and Exposé.

Parameters:
 * `behaviorMask` - if present, this mask should be a combination of values found in [hs._asm.guitk.behaviors](#behaviors) describing the collection behavior.  The mask should be provided as one of the following:
   * integer - a number representing the desired behavior which can be created by combining values found in [hs._asm.guitk.behaviors](#behaviors) with the logical or operator (e.g. `value1 | value2 | ... | valueN`).
   * string  - a single key from [hs._asm.guitk.behaviors](#behaviors) which will be toggled in the current collection behavior.
   * table   - a list of keys from [hs._asm.guitk.behaviors](#behaviors) which will be combined to make the final collection behavior by combining their values with the logical or operator.

Returns:
 * if a parameter is specified, returns the guitk object, otherwise the current value

Notes:
 * Collection behaviors determine how the guitk window is handled by Spaces and Exposé. See [hs._asm.guitk.behaviors](#behaviors) for more information.

- - -

<a name="contentManager"></a>
~~~lua
guitk:contentManager([view | nil]) -> guitkObject | manager/element userdata
~~~
Get or set the content manager for the guitk window.

Parameters:
 * `view` - a userdata representing a content manager or content element, or an explcit nil to remove, to assign to the guitk window.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * This module provides the window or "frame" for displaying visual or user interface elements, however the content itself is provided by other modules. This method allows you to assign a manager or single element directly to the window for display and user interaction.

 * A manager allows for attaching multiple elements to the same window, for example a series of buttons and text fields for user input. Currently the only supported manager is found in `hs._asm.guitk.manager` and you should review this module for details on how to assign multiple elements to the window for display.

 * If the window is being used to display a single element, you can by skip using the manager and assign the element directly with this method. This works especially well for fully contained elements like `hs._asm.guitk.element.avplayer` or `hs.canvas`, but may be useful at times with other elements as well.  The following should be kept in mind when not using a manager:
   * The element's size is the window's size -- you cannot specify a specific location for the element within the window or make it smaller than the window to give it a visual border.
   * Only one element can be assigned at a time. For canvas, which has its own methods for handling multiple visual elements, this isn't necessarily an issue.

- - -

<a name="delete"></a>
~~~lua
guitk:delete([fadeOut]) -> none
~~~
Destroys the guitk object, optionally fading it out first (if currently visible).

Parameters:
 * `fadeOut` - An optional number of seconds over which to fade out the guitk object. Defaults to zero (i.e. immediate).

Returns:
 * None

Notes:
 * This method is automatically called during garbage collection, notably during a Hammerspoon termination or reload, with a fade time of 0.

- - -

<a name="deleteOnClose"></a>
~~~lua
guitk:deleteOnClose([value]) -> guitkObject | boolean
~~~
Get or set whether or not the guitk window should delete itself when its window is closed.

Parameters:
 * `value` - an optional boolean, default false, which sets whether or not the guitk will delete itself when its window is closed by any method.

Returns:
 * If a value is provided, then this method returns the guitk object; otherwise the current value

Notes:
 * setting this to true allows Lua garbage collection to release the window resources when the user closes the window.

- - -

<a name="frame"></a>
~~~lua
guitk:frame([rect], [animated]) -> guitkObject | rect-table
~~~
Get or set the frame of the guitk window.

Parameters:
 * `rect`     - An optional rect-table containing the co-ordinates and size the guitk window should be moved and set to
 * `animated` - an optional boolean, default false, indicating whether the frame change should be performed with a smooth transition animation (true) or not (false).

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * a rect-table is a table with key-value pairs specifying the new top-left coordinate on the screen of the guitk window (keys `x`  and `y`) and the new size (keys `h` and `w`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * See also [hs._asm.guitk:animationDuration](#animationDuration).

- - -

<a name="hasShadow"></a>
~~~lua
guitk:hasShadow([state]) -> guitkObject | boolean
~~~
Get or set whether the guitk window displays a shadow.

Parameters:
 * `state` - an optional boolean, default true, specifying whether or not the window draws a shadow.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="hide"></a>
~~~lua
guitk:hide([fadeOut]) -> guitkObject
~~~
Hides the guitk object

Parameters:
 * `fadeOut` - An optional number of seconds over which to fade out the guitk object. Defaults to zero (i.e. immediate).

Returns:
 * The guitk object

- - -

<a name="ignoresMouseEvents"></a>
~~~lua
guitk:ignoresMouseEvents([state]) -> guitkObject | boolean
~~~
Get or set whether the guitk window ignores mouse events.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the window receives mouse events.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * Setting this to true will prevent elements in the window from receiving mouse button events or mouse movement events which affect the focus of the window or its elements. For elements which accept keyboard entry, this *may* also prevent the user from focusing the element for keyboard input unless the element is focused programmatically with [hs._asm.guitk:activeElement](#activeElement).
 * Mouse tracking events (see `hs._asm.guitk.manager:mouseCallback`) will still occur, even if this is true; however if two windows at the same level (see [hs._asm.guitk:level](#level)) both occupy the current mouse location and one or both of the windows have this attribute set to false, spurious and unpredictable mouse callbacks may occur as the "frontmost" window changes based on which is acting on the event at that instant in time.

- - -

<a name="isOccluded"></a>
~~~lua
guitk:isOccluded() -> boolean
~~~
Returns whether or not the guitk window is currently occluded (hidden by other windows, off screen, etc).

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the guitk window is currently being occluded.

Notes:
 * If any part of the window is visible (even if that portion of the window does not contain any elements), then the window is not considered occluded.
 * a window which is completely covered by one or more opaque windows is considered occluded; however, if the windows covering the guitk window are not opaque, then the window is not occluded.
 * a window that is currently hidden or that has a height of 0 or a width of 0 is considered occluded.
 * See also [hs._asm.guitk:isShowing](#isShowing).

- - -

<a name="isShowing"></a>
~~~lua
guitk:isShowing() -> boolean
~~~
Returns whether or not the guitk window is currently being shown.

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the guitk window is currently being shown (true) or is currently hidden (false).

Notes:
 * This method only determines whether or not the window is being shown or is hidden -- it does not indicate whether or not the window is currently off screen or is occluded by other objects.
 * See also [hs._asm.guitk:isOccluded](#isOccluded).

- - -

<a name="isVisible"></a>
~~~lua
guitk:isVisible() -> boolean
~~~
Returns whether or not the guitk window is currently showing and is (at least partially) visible on screen.

Parameters:
 * None

Returns:
 * a boolean indicating whether or not the guitk window is currently visible.

Notes:
 * This is syntactic sugar for `not hs._asm.guitk:isOccluded()`.
 * See [hs._asm.guitk:isOccluded](#isOccluded) for more details.

- - -

<a name="level"></a>
~~~lua
guitk:level([theLevel]) -> guitkObject | integer
~~~
Get or set the guitk window level

Parameters:
 * `theLevel` - an optional parameter specifying the desired level as an integer or as a string matching a label in [hs._asm.guitk.levels](#levels)

Returns:
 * if a parameter is specified, returns the guitk object, otherwise the current value

Notes:
 * See the notes for [hs._asm.guitk.levels](#levels) for a description of the available levels.

 * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.

- - -

<a name="notificationCallback"></a>
~~~lua
guitk:notificationCallback([fn | nil]) -> guitkObject | fn
~~~
Get or set the notification callback for the guitk window.

Parameters:
 * `fn` - a function, or explicit nil to remove, that should be invoked whenever a registered notification concerning the guitk window occurs.  See [hs._asm.guitk:notificationMessages](#notificationMessages) for information on registering for specific notifications.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * The function should expect two arguments: the guitkObject itself and a string specifying the type of notification. See [hs._asm.guitk:notificationMessages](#notificationMessages) and [hs._asm.guitk.notifications](#notifications).
 * [hs._asm.guitk:simplifiedWindowCallback](#simplifiedWindowCallback) provides a wrapper to this method which conforms to the window notifications currently offered by `hs.webview`.

- - -

<a name="notificationMessages"></a>
~~~lua
guitk:notificationMessages([notifications, [replace]]) -> guitkObject | table
~~~
Get or set the specific notifications which should trigger a callback set with [hs._asm.guitk:notificationCallback](#notificationCallback).

Parameters:
 * `notifications` - a string, to specify one, or a table of strings to specify multiple notifications which are to trigger a callback when they occur.
 * `replace`       - an optional boolean, default false, specifying whether the notifications listed should be added to the current set (false) or replace the existing set with new values (true).

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * When a new guitkObject is created, the messages are initially set to `{ "didBecomeKey", "didResignKey", "didResize", "didMove" }`
 * See [hs._asm.guitk.notifications](#notifications) for possible notification messages that can be watched for.

- - -

<a name="opaque"></a>
~~~lua
guitk:opaque([state]) -> guitkObject | boolean
~~~
Get or set whether the guitk window is opaque.

Parameters:
 * `state` - an optional boolean, default true, specifying whether or not the window is opaque.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="orderAbove"></a>
~~~lua
guitk:orderAbove([guitk2]) -> guitkObject
~~~
Moves the guitk window above guitk2, or all guitk windows in the same presentation level, if guitk2 is not given.

Parameters:
 * `guitk2` -An optional guitk window object to place the guitk window above.

Returns:
 * The guitk object

Notes:
 * If the guitk window and guitk2 are not at the same presentation level, this method will will move the window as close to the desired relationship as possible without changing the object's presentation level. See [hs._asm.guitk.level](#level).

- - -

<a name="orderBelow"></a>
~~~lua
guitk:orderBelow([guitk2]) -> guitkObject
~~~
Moves the guitk window below guitk2, or all guitk windows in the same presentation level, if guitk2 is not given.

Parameters:
 * `guitk2` -An optional guitk window object to place the guitk window below.

Returns:
 * The guitk object

Notes:
 * If the guitk window and guitk2 are not at the same presentation level, this method will will move the window as close to the desired relationship as possible without changing the object's presentation level. See [hs._asm.guitk.level](#level).

- - -

<a name="passthroughCallback"></a>
~~~lua
guitk:passthroughCallback([fn | nil]) -> guitkObject | fn | nil
~~~
Get or set the pass through callback for the guitk window.

Parameters:
 * `fn` - a function, or an explicit nil to remove, specifying the callback to invoke for elements which do not have their own callbacks assigned.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * The pass through callback should expect one or two arguments and return none.

 * The pass through callback is designed so that elements which trigger a callback based on user interaction which do not have a specifically assigned callback can still report user interaction through a common fallback.
 * The arguments received by the pass through callback will be organized as follows:
   * the guitk window userdata object
   * a table containing the arguments from the content manager or element.
     * if a content manager is in place, this array will contain the following arguments:
       * the content manager userdata object
       * a table containing the arguments provided by the elements callback itself, usually the element userdata followed by any additional arguments as defined for the element's callback function.
     * if no content manager is in place and the element is directly assigned to the guitk window, then this table will contain the arguments provided by the elements callback itself, usually the element userdata followed by any additional arguments as defined for the element's callback function.

 * Note that elements which have a callback that returns a response cannot use this common pass through callback method; in such cases a specific callback must be assigned to the element directly as described in the element's documentation.

- - -

<a name="sendToBack"></a>
~~~lua
guitk:sendToBack() -> guitkObject
~~~
Places the guitk window behind normal windows, between the desktop wallpaper and desktop icons

Parameters:
 * None

Returns:
 * The guitk object

- - -

<a name="show"></a>
~~~lua
guitk:show([fadeIn]) -> guitkObject
~~~
Displays the guitk object

Parameters:
 * `fadeIn` - An optional number of seconds over which to fade in the guitk object. Defaults to zero (i.e. immediate).

Returns:
 * The guitk object

- - -

<a name="simplifiedWindowCallback"></a>
~~~lua
guitk:simplifiedWindowCallback([fn]) -> guitkObject
~~~
Set or clear a callback for updates to the guitk window using a simplified subset of the available notifications

Parameters:
 * `fn` - the function to be called when the guitk window is moved or closed. Specify an explicit nil to clear the current callback.  The function should expect 2 or 3 arguments and return none.  The arguments will be one of the following:

   * "closing", guitkObject - specifies that the guitk window is being closed, either by the user or with the [hs._asm.guitk:delete](#delete) method.
     * `action`      - in this case "closing", specifying that the guitk window is being closed
     * `guitkObject` - the guitk window that is being closed

   * "focusChange", guitkObject, state - indicates that the guitk window has either become or stopped being the focused window
     * `action`      - in this case "focusChange", specifying that the guitk window has changed focus
     * `guitkObject` - the guitk window which has changed focus
     * `state`       - a boolean, true if the guitk window has become the focused window, or false if it has lost focus

   * "frameChange", guitkObject, frame - indicates that the guitk window has been moved or resized
     * `action`      - in this case "frameChange", specifying that the guitk window's frame has changed
     * `guitkObject` - the guitk window which has had its frame changed
     * `frame`       - a rect-table containing the new co-ordinates and size of the guitk window

Returns:
 * The guitk object

Notes:
 * This method is a wrapper to the [hs._asm.guitk:notificationCallback](#notificationCallback) method which mimics the behavior for window changes first introduced with `hs.webview`. Setting or clearing a callback with this method is equivalent to doing the same with [hs._asm.guitk:notificationCallback](#notificationCallback) directly.

 * Setting a callback function with this method will reset the currently watched notifications to "willClose", "didBecomeKey", "didResignKey", "didResize", and "didMove".  You can add additional notifications after setting the callback function with [hs._asm.guitk:notificationMessages](#notificationMessages) and the following arguments will be passed to the callback when the additional notifications occur:
   * "other", guitkObject, message
     * `action`      - in this case "other" indicating that the notification is for something not recognized by the simplified wrapper.
     * `guitkObject` - the guitk window for which the notification has occurred.
     * `message`     - the name of the notification which has been triggered. See [hs._asm.guitk.notifications](#notifications).

- - -

<a name="size"></a>
~~~lua
guitk:size([size], [animated]) -> guitkObject | rect-table
~~~
Get or set the size of the guitk window.

Parameters:
 * `size`     - an optional size-table specifying the width and height the guitk window should be resized to
 * `animated` - an optional boolean, default false, indicating whether the frame change should be performed with a smooth transition animation (true) or not (false).

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * a size-table is a table with key-value pairs specifying the size (keys `h` and `w`) the guitk window should be resized to. The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * See also [hs._asm.guitk:animationDuration](#animationDuration).

- - -

<a name="styleMask"></a>
~~~lua
guitk:styleMask([mask]) -> guitkObject | integer
~~~
Get or set the window display style

Parameters:
 * `mask` - if present, this mask should be a combination of values found in [hs._asm.guitk.masks](#masks) describing the window style.  The mask should be provided as one of the following:
   * integer - a number representing the style which can be created by combining values found in [hs._asm.guitk.masks](#masks) with the logical or operator (e.g. `value1 | value2 | ... | valueN`).
   * string  - a single key from [hs._asm.guitk.masks](#masks) which will be toggled in the current window style.
   * table   - a list of keys from [hs._asm.guitk.masks](#masks) which will be combined to make the final style by combining their values with the logical or operator.

Returns:
 * if a parameter is specified, returns the guitk object, otherwise the current value

- - -

<a name="title"></a>
~~~lua
guitk:title([title]) -> guitkObject | string
~~~
Get or set the guitk window's title.

Parameters:
 * `title` - an optional string specifying the title to assign to the guitk window.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="titlebarAppearsTransparent"></a>
~~~lua
guitk:titlebarAppearsTransparent([state]) -> guitkObject | boolean
~~~
Get or set whether the guitk window's title bar draws its background.

Parameters:
 * `state` - an optional boolean, default true, specifying whether or not the guitk window's title bar draws its background.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

- - -

<a name="titleVisibility"></a>
~~~lua
guitk:titleVisibility([state]) -> guitkObject | currentValue
~~~
Get or set whether or not the title is displayed in the guitk window titlebar.

Parameters:
 * `state` - an optional string containing the text "visible" or "hidden", specifying whether or not the guitk window's title text appears.

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * NOT IMPLEMENTED YET - When a toolbar is attached to the guitk window (see the `hs.webview.toolbar` module documentation), this function can be used to specify whether the Toolbar appears underneath the window's title ("visible") or in the window's title bar itself, as seen in applications like Safari ("hidden").

- - -

<a name="topLeft"></a>
~~~lua
guitk:topLeft([point], [animated]) -> guitkObject | rect-table
~~~
Get or set the top left corner of the guitk window.

Parameters:
 * `point`     - An optional point-table specifying the new coordinate the top-left of the guitk window should be moved to
 * `animated` - an optional boolean, default false, indicating whether the frame change should be performed with a smooth transition animation (true) or not (false).

Returns:
 * If an argument is provided, the guitk object; otherwise the current value.

Notes:
 * a point-table is a table with key-value pairs specifying the new top-left coordinate on the screen of the guitk (keys `x`  and `y`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.

 * See also [hs._asm.guitk:animationDuration](#animationDuration).

### Module Constants

<a name="levels"></a>
~~~lua
guitk.levels
~~~
A table of predefined window levels usable with [hs._asm.guitk:level](#level)

Predefined levels are:
 * _MinimumWindowLevelKey - lowest allowed window level
 * desktop
 * desktopIcon            - [hs._asm.guitk:sendToBack](#sendToBack) is equivalent to this level - 1
 * normal                 - normal application windows
 * tornOffMenu
 * floating               - equivalent to [hs._asm.guitk:bringToFront(false)](#bringToFront); where "Always Keep On Top" windows are usually set
 * modalPanel             - modal alert dialog
 * utility
 * dock                   - level of the Dock
 * mainMenu               - level of the Menubar
 * status
 * popUpMenu              - level of a menu when displayed (open)
 * overlay
 * help
 * dragging
 * screenSaver            - equivalent to [hs._asm.guitk:bringToFront(true)](#bringToFront)
 * assistiveTechHigh
 * cursor
 * _MaximumWindowLevelKey - highest allowed window level

Notes:
 * These key names map to the constants used in CoreGraphics to specify window levels and may not actually be used for what the name might suggest. For example, tests suggest that an active screen saver actually runs at a level of 2002, rather than at 1000, which is the window level corresponding to kCGScreenSaverWindowLevelKey.

 * Each window level is sorted separately and [hs._asm.guitk:orderAbove](#orderAbove) and [hs._asm.guitk:orderBelow](#orderBelow) only arrange windows within the same level.

 * If you use Dock hiding (or in 10.11+, Menubar hiding) please note that when the Dock (or Menubar) is popped up, it is done so with an implicit orderAbove, which will place it above any items you may also draw at the Dock (or MainMenu) level.

 * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.

- - -

<a name="masks"></a>
~~~lua
guitk.masks[]
~~~
A table containing valid masks for the guitk window.

Table Keys:
 * `borderless`             - The window has no border decorations
 * `titled`                 - The window title bar is displayed
 * `closable`               - The window has a close button
 * `miniaturizable`         - The window has a minimize button
 * `resizable`              - The window is resizable
 * `texturedBackground`     - The window has a texturized background
 * `fullSizeContentView`    - If titled, the titlebar is within the frame size specified at creation, not above it.  Shrinks actual content area by the size of the titlebar, if present.
 * `utility`                - If titled, the window shows a utility panel titlebar (thinner than normal)
 * `nonactivating`          - If the window is activated, it won't bring other Hammerspoon windows forward as well
 * `HUD`                    - Requires utility; the window titlebar is shown dark and can only show the close button and title (if they are set)

The following are still being evaluated and may require additional support or specific methods to be in effect before use. Use with caution.
 * `unifiedTitleAndToolbar` -
 * `fullScreen`             -
 * `docModal`               -

Notes:
 * The Maximize button in the window title is enabled when Resizable is set.
 * The Close, Minimize, and Maximize buttons are only visible when the Window is also Titled.

 * Not all combinations of masks are valid and will through an error if set with [hs._asm.guitk:mask](#mask).

- - -

<a name="notifications"></a>
~~~lua
guitk.notifications[]
~~~
An array containing all of the notifications which can be enabled with [hs._asm.guitk:notificationMessages](#notificationMessages).

Array values:
 * `didBecomeKey`               - The window has become the key window; controls or elements of the window can now be manipulated by the user and keyboard entry (if appropriate) will be captured by the relevant elements.
 * `didBecomeMain`              - The window has become the main window of Hammerspoon. In most cases, this is equivalent to the window becoming key and both notifications may be sent if they are being watched for.
 * `didChangeBackingProperties` - The backing properties of the window have changed. This will be posted if the scaling factor of color space for the window changes, most likely because it moved to a different screen.
 * `didChangeOcclusionState`    - The window's occlusion state has changed (i.e. whether or not at least part of the window is currently visible)
 * `didChangeScreen`            - Part of the window has moved onto or off of the current screens
 * `didChangeScreenProfile`     - The screen the window is on has changed its properties or color profile
 * `didDeminiaturize`           - The window has been de-miniaturized
 * `didEndLiveResize`           - The user resized the window
 * `didEndSheet`                - The window has closed an attached sheet
 * `didEnterFullScreen`         - The window has entered full screen mode
 * `didEnterVersionBrowser`     - The window will enter version browser mode
 * `didExitFullScreen`          - The window has exited full screen mode
 * `didExitVersionBrowser`      - The window will exit version browser mode
 * `didExpose`                  - Posted whenever a portion of a nonretained window is exposed - may not be applicable to the way Hammerspoon manages windows; will have to evaluate further
 * `didFailToEnterFullScreen`   - The window failed to enter full screen mode
 * `didFailToExitFullScreen`    - The window failed to exit full screen mode
 * `didMiniaturize`             - The window was miniaturized
 * `didMove`                    - The window was moved
 * `didResignKey`               - The window has stopped being the key window
 * `didResignMain`              - The window has stopped being the main window
 * `didResize`                  - The window did resize
 * `didUpdate`                  - The window received an update message (a request to redraw all content and the content of its subviews)
 * `willBeginSheet`             - The window is about to open an attached sheet
 * `willClose`                  - The window is about to close; the window has not closed yet, so its userdata is still valid, even if it's set to be deleted on close, so do any clean up at this time.
 * `willEnterFullScreen`        - The window is about to enter full screen mode but has not done so yet
 * `willEnterVersionBrowser`    - The window will enter version browser mode but has not done so yet
 * `willExitFullScreen`         - The window will exit full screen mode but has not done so yet
 * `willExitVersionBrowser`     - The window will exit version browser mode but has not done so yet
 * `willMiniaturize`            - The window will miniaturize but has not done so yet
 * `willMove`                   - The window will move but has not done so yet
 * `willStartLiveResize`        - The window is about to be resized by the user

Notes:
 * Not all of the notifications here are currently fully supported and the specific details and support will change as this module and its submodules evolve and get fleshed out. Some may be removed if it is determined they will never be supported by this module while others may lead to additions when the need arises. Please post an issue or pull request if you would like to request specific support or provide additions yourself.

- - -

<a name="windowBehaviors"></a>
~~~lua
guitk.windowBehaviors[]
~~~
Array of window behavior labels for determining how an guitk is handled in Spaces and Exposé

* `default`                   - The window can be associated to one space at a time.
* `canJoinAllSpaces`          - The window appears in all spaces. The menu bar behaves this way.
* `moveToActiveSpace`         - Making the window active does not cause a space switch; the window switches to the active space.

Only one of these may be active at a time:

* `managed`                   - The window participates in Spaces and Exposé. This is the default behavior if windowLevel is equal to NSNormalWindowLevel.
* `transient`                 - The window floats in Spaces and is hidden by Exposé. This is the default behavior if windowLevel is not equal to NSNormalWindowLevel.
* `stationary`                - The window is unaffected by Exposé; it stays visible and stationary, like the desktop window.

Only one of these may be active at a time:

* `participatesInCycle`       - The window participates in the window cycle for use with the Cycle Through Windows Window menu item.
* `ignoresCycle`              - The window is not part of the window cycle for use with the Cycle Through Windows Window menu item.

Only one of these may be active at a time:

* `fullScreenPrimary`         - A window with this collection behavior has a fullscreen button in the upper right of its titlebar.
* `fullScreenAuxiliary`       - Windows with this collection behavior can be shown on the same space as the fullscreen window.

Only one of these may be active at a time (Available in OS X 10.11 and later):

* `fullScreenAllowsTiling`    - A window with this collection behavior be a full screen tile window and does not have to have `fullScreenPrimary` set.
* `fullScreenDisallowsTiling` - A window with this collection behavior cannot be made a fullscreen tile window, but it can have `fullScreenPrimary` set.  You can use this setting to prevent other windows from being placed in the window’s fullscreen tile.

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


