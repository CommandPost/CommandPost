hs._asm.guitk.element.colorwell
===============================

Provides acolorwell element `hs._asm.guitk`. A colorwell is a rectangular swatch of color which the user can click on to pop up the color picker for choosing a new color.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
colorwell = require("hs._asm.guitk").element.colorwell
~~~

### Contents

##### Module Constructors
* <a href="#new">colorwell.new([frame]) -> colorwellObject</a>

##### Module Functions
* <a href="#ignoresAlpha">colorwell.ignoresAlpha([state]) -> boolean</a>
* <a href="#panelVisible">colorwell.panelVisible([state]) -> boolean</a>

##### Module Methods
* <a href="#active">colorwell:active([state]) -> colorwellObject | boolean</a>
* <a href="#bordered">colorwell:bordered([enabled]) -> colorwellObject | boolean</a>
* <a href="#callback">colorwell:callback([fn | nil]) -> colorwellObject | fn | nil</a>
* <a href="#color">colorwell:color([color]) -> colorwellObject | table</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
colorwell.new([frame]) -> colorwellObject
~~~
Creates a new colorwell element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the element.

Returns:
 * the colorwellObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * The colorwell element does not have a default height or width; when assigning the element to an `hs._asm.guitk.manager`, be sure to specify them in the frame details or the element may not be visible.

### Module Functions

<a name="ignoresAlpha"></a>
~~~lua
colorwell.ignoresAlpha([state]) -> boolean
~~~
Get or set whether or not the alpha component is ignored in the color picker.

Parameters:
 * `state` - an optional boolean, default true, indicating whether or not the alpha channel should ignored (suppressed) in the color picker.

Returns:
 * a boolean representing the, possibly new, state.

Note:
 * When set to true, the alpha channel is not editable. If you assign a color that has an alpha component other than 1.0 with [hs._asm.guitk.element.colorwell:color](#color), the alpha component will be set to 1.0.

* The color picker is not unique to each element -- if you require the alpha channel for some colorwells but not others, make sure to call this function from the callback when the picker is opened for each specific colorwell element -- see [hs._asm.guitk.element.colorwell:callback](#callback).

- - -

<a name="panelVisible"></a>
~~~lua
colorwell.panelVisible([state]) -> boolean
~~~
Get or set whether the color picker panel is currently open and visible or not.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the color picker is currently visible, displaying or closing it as specified.

Returns:
 * a boolean representing the, possibly new, state

Notes:
 * if a colorwell is currently the active element, invoking this function with a false argument will trigger the colorwell's close callback -- see [hs._asm.guitk.element.colorwell:callback](#callback).

### Module Methods

<a name="active"></a>
~~~lua
colorwell:active([state]) -> colorwellObject | boolean
~~~
Get or set whether the colorwell element is the currently active element.

Parameters:
 * `state` - an optional boolean, specifying whether the colorwell element should be activated (true) or deactivated (false).

Returns:
 * if a value is provided, returns the colorwellObject ; otherwise returns the current value.

Notes:
 * if you pass true to this method and the color picker panel is not currently visible, it will be made visible.
 * however, it won't be dismissed when you pass false; to achieve this, use [hs._asm.guitk.element.colorwell:callback](#callback) like this:

 ~~~lua
 colorwell:callback(function(obj, msg, color)
     if msg == "didBeginEditing" then
        -- do what you want when the color picker is opened
      elseif msg == "colorDidChange" then
        -- do what you want with the color as it changes
      elseif msg == "didEndEditing" then
        hs._asm.guitk.element.colorwell.panelVisible(false)
        -- now do what you want with the newly chosen color
      end
 end)
 ~~~

- - -

<a name="bordered"></a>
~~~lua
colorwell:bordered([enabled]) -> colorwellObject | boolean
~~~
Get or set whether the colorwell element has a rectangular border around it.

Parameters:
 * `enabled` - an optional boolean, default true, specifying whether or not a border should be drawn around the colorwell element.

Returns:
 * if a value is provided, returns the colorwellObject ; otherwise returns the current value.

- - -

<a name="callback"></a>
~~~lua
colorwell:callback([fn | nil]) -> colorwellObject | fn | nil
~~~
Get or set the callback function which will be invoked when the user uses the color picker to modify the colorwell element.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user uses the color picker to modify the colorwell element.

Returns:
 * if a value is provided, returns the colorwellObject ; otherwise returns the current value.

Notes:
 * The callback function should expect arguments as described below and return none:
   * When the colorwell is activated the callback will receive the following arguments:
     * the colorwell userdata object
     * the message string "didBeginEditing" indicating that the colorwell element has become active
   * When the colorwell is deactivated the callback will receive the following arguments:
     * the colorwell userdata object
     * the message string "didEndEditing" indicating that the colorwell element is no longer active
     * a table describing the new color as defined by the `hs.drawing.color` module.
   * When the user selects or changes a color in the color picker, and `hs._asm.guitk.element._control:continuous` is true for the element, the callback will receive the following arguments:
     * the colorwell userdata object
     * the message string "colorDidChange" indicating that the user has selected or modified the color currently chosen in the color picker panel.
     * a table describing the currently selected color as defined by the `hs.drawing.color` module.

- - -

<a name="color"></a>
~~~lua
colorwell:color([color]) -> colorwellObject | table
~~~
Get or set the color currently being displayed by the colorwell element

Parameters:
 * an optional table defining a color as specified in the `hs.drawing.color` module to set the colorwell to.

Returns:
 * if a value is provided, returns the colorwellObject ; otherwise returns the current value.

Notes:
 * if assigning a new color and [hs._asm.guitk.element.colorwell.ignoresAlpha](#ignoresAlpha) is currently true, the alpha channel of the color will be ignored and internally changed to 1.0.

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


