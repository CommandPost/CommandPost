hs._asm.guitk.element.progress
==============================

Provides spinning and bar progress indicator elements for use with `hs._asm.guitk`.

* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
progress = require("hs._asm.guitk").element.progress
~~~

### Contents

##### Module Constructors
* <a href="#new">progress.new([frame]) -> progressIndicatorObject</a>

##### Module Methods
* <a href="#bezeled">progress:bezeled([flag]) -> progressObject | boolean</a>
* <a href="#circular">progress:circular([flag]) -> progressObject | boolean</a>
* <a href="#color">progress:color(color) -> progressObject | table | nil</a>
* <a href="#increment">progress:increment(value) -> progressObject</a>
* <a href="#indeterminate">progress:indeterminate([flag]) -> progressObject | boolean</a>
* <a href="#indicatorSize">progress:indicatorSize([size]) -> progressObject | string</a>
* <a href="#max">progress:max([value]) -> progressObject | number</a>
* <a href="#min">progress:min([value]) -> progressObject | number</a>
* <a href="#start">progress:start() -> progressObject</a>
* <a href="#stop">progress:stop() -> progressObject</a>
* <a href="#threaded">progress:threaded([flag]) -> progressObject | boolean</a>
* <a href="#tint">progress:tint([tint]) -> progressObject | string</a>
* <a href="#value">progress:value([value]) -> progressObject | number</a>
* <a href="#visibleWhenStopped">progress:visibleWhenStopped([flag]) -> progressObject | boolean</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
progress.new([frame]) -> progressIndicatorObject
~~~
Creates a new Progress Indicator element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the progress indicator object.

Returns:
 * the progressIndicatorObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * The bar progress indicator type does not have a default width; if you are assigning the progress element to an `hs._asm.guitk.manager`, be sure to specify a width in the frame details or the element may not be visible.

### Module Methods

<a name="bezeled"></a>
~~~lua
progress:bezeled([flag]) -> progressObject | boolean
~~~
Get or set whether or not the progress indicator’s frame has a three-dimensional bezel.

Parameters:
 * `flag` - an optional boolean indicating whether or not the indicator's frame is bezeled.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is true.
 * In my testing, this setting does not seem to have much, if any, effect on the visual aspect of the indicator and is provided in this module in case this changes in a future OS X update (there are some indications that it may have had a greater effect in previous versions).

- - -

<a name="circular"></a>
~~~lua
progress:circular([flag]) -> progressObject | boolean
~~~
Get or set whether or not the progress indicator is circular or a in the form of a progress bar.

Parameters:
 * `flag` - an optional boolean indicating whether or not the indicator is circular (true) or a progress bar (false)

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is false.
 * An indeterminate circular indicator is displayed as the spinning star seen during system startup.
 * A determinate circular indicator is displayed as a pie chart which fills up as its value increases.
 * An indeterminate progress indicator is displayed as a rounded rectangle with a moving pulse.
 * A determinate progress indicator is displayed as a rounded rectangle that fills up as its value increases.

- - -

<a name="color"></a>
~~~lua
progress:color(color) -> progressObject | table | nil
~~~
Get or set the fill color for a progress indicator.

Parameters:
 * `color` - an optional table specifying a color as defined in `hs.drawing.color` indicating the color to use for the progress indicator, or an explicit nil to reset the behavior to macOS default.

Returns:
 * the progress indicator object

Notes:
 * This method is not based upon the methods inherent in the NSProgressIndicator Objective-C class, but rather on code found at http://stackoverflow.com/a/32396595 utilizing a CIFilter object to adjust the view's output.
 * When a color is applied to a bar indicator, the visible pulsing of the bar is no longer visible; this is a side effect of applying the filter to the view and no workaround is currently known.

- - -

<a name="increment"></a>
~~~lua
progress:increment(value) -> progressObject
~~~
Increment the current value of a progress indicator's progress by the amount specified.

Parameters:
 * `value` - the value by which to increment the progress indicator's current value.

Returns:
 * the progress indicator object

Notes:
 * Programmatically, this is equivalent to `hs._asm.guitk.element.progress:value(hs._asm.guitk.element.progress:value() + value)`, but is faster.

- - -

<a name="indeterminate"></a>
~~~lua
progress:indeterminate([flag]) -> progressObject | boolean
~~~
Get or set whether or not the progress indicator is indeterminate.  A determinate indicator displays how much of the task has been completed. An indeterminate indicator shows simply that the application is busy.

Parameters:
 * `flag` - an optional boolean indicating whether or not the indicator is indeterminate.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is true.
 * If this setting is set to false, you should also take a look at [hs._asm.guitk.element.progress:min](#min) and [hs._asm.guitk.element.progress:max](#max), and periodically update the status with [hs._asm.guitk.element.progress:value](#value) or [hs._asm.guitk.element.progress:increment](#increment)

- - -

<a name="indicatorSize"></a>
~~~lua
progress:indicatorSize([size]) -> progressObject | string
~~~
Get or set the indicator's size.

Parameters:
 * `size` - an optional string specifying the size of the progress indicator object.  May be one of "regular", "small", or "mini".

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is "regular".
 * For circular indicators, the sizes seem to be 32x32, 16x16, and 10x10 in 10.11.
 * For bar indicators, the height seems to be 20 and 12; the mini size seems to be ignored, at least in 10.11.

- - -

<a name="max"></a>
~~~lua
progress:max([value]) -> progressObject | number
~~~
Get or set the maximum value (the value at which the progress indicator should display as full) for the progress indicator.

Parameters:
 * `value` - an optional number indicating the maximum value.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default value for this is 100.0
 * This value has no effect on the display of an indeterminate progress indicator.
 * For a determinate indicator, the behavior is undefined if this value is less than [hs._asm.guitk.element.progress:min](#min).

- - -

<a name="min"></a>
~~~lua
progress:min([value]) -> progressObject | number
~~~
Get or set the minimum value (the value at which the progress indicator should display as empty) for the progress indicator.

Parameters:
 * `value` - an optional number indicating the minimum value.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default value for this is 0.0
 * This value has no effect on the display of an indeterminate progress indicator.
 * For a determinate indicator, the behavior is undefined if this value is greater than [hs._asm.guitk.element.progress:max](#max).

- - -

<a name="start"></a>
~~~lua
progress:start() -> progressObject
~~~
If the progress indicator is indeterminate, starts the animation for the indicator.

Parameters:
 * None

Returns:
 * the progress indicator object

Notes:
 * This method has no effect if the indicator is not indeterminate.

- - -

<a name="stop"></a>
~~~lua
progress:stop() -> progressObject
~~~
If the progress indicator is indeterminate, stops the animation for the indicator.

Parameters:
 * None

Returns:
 * the progress indicator object

Notes:
 * This method has no effect if the indicator is not indeterminate.

- - -

<a name="threaded"></a>
~~~lua
progress:threaded([flag]) -> progressObject | boolean
~~~
Get or set whether or not the animation for an indicator occurs in a separate process thread.

Parameters:
 * `flag` - an optional boolean indicating whether or not the animation for the indicator should occur in a separate thread.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is true.
 * If this flag is set to false, the indicator animation speed may fluctuate as Hammerspoon performs other activities, though not reliably enough to provide an "activity level" feedback indicator.

- - -

<a name="tint"></a>
~~~lua
progress:tint([tint]) -> progressObject | string
~~~
Get or set the indicator's tint.

Parameters:
 * `tint` - an optional string specifying the tint of the progress indicator.  May be one of "default", "blue", "graphite", or "clear".

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is "default".
 * In my testing, this setting does not seem to have much, if any, effect on the visual aspect of the indicator and is provided in this module in case this changes in a future OS X update (there are some indications that it may have had an effect in previous versions).

- - -

<a name="value"></a>
~~~lua
progress:value([value]) -> progressObject | number
~~~
Get or set the current value of the progress indicator's completion status.

Parameters:
 * `value` - an optional number indicating the current extent of the progress.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default value for this is 0.0
 * This value has no effect on the display of an indeterminate progress indicator.
 * For a determinate indicator, this will affect how "filled" the bar or circle is.  If the value is lower than [hs._asm.guitk.element.progress:min](#min), then it will be set to the current minimum value.  If the value is greater than [hs._asm.guitk.element.progress:max](#max), then it will be set to the current maximum value.

- - -

<a name="visibleWhenStopped"></a>
~~~lua
progress:visibleWhenStopped([flag]) -> progressObject | boolean
~~~
Get or set whether or not the progress indicator is visible when animation has been stopped.

Parameters:
 * `flag` - an optional boolean indicating whether or not the progress indicator is visible when animation has stopped.

Returns:
 * if a value is provided, returns the progress indicator object ; otherwise returns the current value.

Notes:
 * The default setting for this is true.

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


