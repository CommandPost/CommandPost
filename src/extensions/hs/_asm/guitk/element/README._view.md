hs._asm.guitk.element._view
===========================

Common methods inherited by all elements defined as submodules. This does not include elements which come from other Hammerspoon modules (currently this is limited to canvas objects, but may be extended to include webview and possibly chooser.)

macOS Developer Note: Understanding this is not required for use of the methods provided by this submodule, but for those interested, `hs._asm.guitk` works by providing a framework for displaying macOS objects which are subclasses of the NSView class; macOS methods which belong to NSView and are not overridden or superseded by more specific or appropriate element specific methods are defined here so that they can be used by all elements which share this common ancestor.

### Usage

This module should not be loaded directly; it is automatically added to elements which inherit these methods when `hs._asm.guitk` is loaded.

### Contents

##### Module Methods
* <a href="#_nextResponder">element:_nextResponder() -> userdata</a>
* <a href="#alphaValue">element:alphaValue([alpha]) -> elementObject | number</a>
* <a href="#fittingSize">element:fittingSize() -> table</a>
* <a href="#focusRingType">element:focusRingType([type]) -> elementObject | string</a>
* <a href="#frameSize">element:frameSize([size]) -> elementObject | table</a>
* <a href="#hidden">element:hidden([state | nil]) -> elementObject | boolean</a>
* <a href="#rotation">element:rotation([angle]) -> elementObject | number</a>
* <a href="#tooltip">element:tooltip([tooltip]) -> elementObject | string</a>

- - -

### Module Methods

<a name="_nextResponder"></a>
~~~lua
element:_nextResponder() -> userdata
~~~
Get the parent of the current element, usually a `hs._asm.guitk.manager` or `hs._asm.guitk` userdata object.

Parameters:
 * None

Returns:
 * the userdata representing the parent container of the element, usually a `hs._asm.guitk.manager` or `hs._asm.guitk` userdata object or nil if the element is currently not assigned to a window or manager or if the parent is not controllable through Hammerspoon.

Notes:
 * The metamethods for `hs._asm.guitk.element` are designed so that you usually shouldn't need to access this method directly very often.
 * The name "nextResponder" comes from the macOS user interface internal organization and refers to the object which is further up the responder chain when determining the target for user activity.

- - -

<a name="alphaValue"></a>
~~~lua
element:alphaValue([alpha]) -> elementObject | number
~~~
Get or set the alpha level of the element.

Parameters:
 * `alpha` - an optional number, default 1.0, specifying the alpha level (0.0 - 1.0, inclusive) for the element.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

- - -

<a name="fittingSize"></a>
~~~lua
element:fittingSize() -> table
~~~
Returns a table with `h` and `w` keys specifying the element's fitting size as defined by macOS and the element's current properties.

Parameters:
 * None

Returns:
 * a table with `h` and `w` keys specifying the elements fitting size

Notes:
 * The dimensions provided can be used to determine a minimum size for the element to display fully based on its current properties and may change as these change.
 * Not all elements provide one or both of these fields; in such a case, the value for the missing or unspecified field will be 0.
 * If you do not specify an elements height or width with `hs._asm.guitk.manager:elementFrameDetails`, with the elements constructor, or with [hs._asm.guitk.element._view:frameSize](#frameSize), the value returned by this method will be used instead; in cases where a specific dimension is not defined by this method, you should make sure to specify it or the element may not be visible.

- - -

<a name="focusRingType"></a>
~~~lua
element:focusRingType([type]) -> elementObject | string
~~~
Get or set the focus ring type for the element

Parameters:
 * `type` - an optional string specifying the focus ring type for the element.  Valid strings are as follows:
   * "default"  - The default focus ring behavior for the element will be used when the element is the input focus; usually this is identical to "exterior".
   * "none"     - No focus ring will be drawn around the element when it is the input focus
   * "Exterior" - The standard Aqua focus ring will be drawn around the element when it is the input focus

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * Setting this for an element that cannot be an active element has no effect.
 * When an element is rotated with [hs._asm.guitk.element._view:rotation](#rotation), the focus ring may not appear properly; if you are using angles other then the four cardinal directions (0, 90, 180, or 270), it may be visually more appropriate to set this to "none".

- - -

<a name="frameSize"></a>
~~~lua
element:frameSize([size]) -> elementObject | table
~~~
Get or set the frame size of the element.

Parameters:
 * `size` - a size-table specifying the height and width of the element's frame

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * a size-table is a table with key-value pairs specifying the size (keys `h` and `w`) the element should be resized to.
 * if the element is assigned directly to an `hs._asm.guitk` window object, setting the frame will have no effect.

 * in general, it is more useful to adjust the element's size with `hs._asm.guitk.manager:elementFrameDetails` because this supports percentages and auto-resizing based on the size of the element's parent.  This method may be useful, however, when pre-building content before it has been added to a manager and the size cannot be assigned with its constructor.

- - -

<a name="hidden"></a>
~~~lua
element:hidden([state | nil]) -> elementObject | boolean
~~~
Get or set whether or not the element is currently hidden

Parameters:
 * `state` - an optional boolean specifying whether the element should be hidden. If you specify an explicit nil, this method will return whether or not this element *or any of its parents* are currently hidden.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * If no argument is provided, this method will return whether or not the element itself has been explicitly hidden; when an explicit nil is provided as the argument, this method will return whether or not this element or any of its parent objects are hidden, since hiding the parent will also hide all of the elements of the parent.

 * When used as a property through the `hs._asm.guitk.manager` metamethods, this property can only get or set whether or not the element itself is explicitly hidden.

- - -

<a name="rotation"></a>
~~~lua
element:rotation([angle]) -> elementObject | number
~~~
Get or set the rotation of the element about its center.

Parameters:
 * `angle` - an optional number representing the number of degrees the element should be rotated clockwise around its center

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * Not all elements rotate cleanly, e.g. button elements with an image in them may skew the image or alter its size depending upon the specific angle of rotation. At this time it is not known if this can be easily addressed or not.

- - -

<a name="tooltip"></a>
~~~lua
element:tooltip([tooltip]) -> elementObject | string
~~~
Get or set the tooltip for the element

Parameters:
 * `tooltip` - a string, or nil to remove, specifying the tooltip to display when the mouse pointer hovers over the element

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * Tooltips are displayed when the window is active and the mouse pointer hovers over an element.

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


