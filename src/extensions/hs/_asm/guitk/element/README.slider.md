hs._asm.guitk.element.slider
============================

Provides a slider element for use with `hs._asm.guitk`. Sliders are horizontal or vertical bars representing a range of numeric values which can be selected by adjusting the position of the knob on the slider.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
slider = require("hs._asm.guitk").element.slider
~~~

### Contents

##### Module Constructors
* <a href="#new">slider.new([frame]) -> sliderObject</a>

##### Module Methods
* <a href="#altClickIncrement">slider:altClickIncrement([value]) -> sliderObject | number</a>
* <a href="#callback">slider:callback([fn | nil]) -> sliderObject | fn | nil</a>
* <a href="#closestTickMark">slider:closestTickMark(value) -> integer</a>
* <a href="#closestTickMarkValue">slider:closestTickMarkValue(value) -> number</a>
* <a href="#indexOfTickMarkAt">slider:indexOfTickMarkAt(point) -> integer | nil</a>
* <a href="#knobThickness">slider:knobThickness() -> number</a>
* <a href="#max">slider:max([value]) -> sliderObject | number</a>
* <a href="#min">slider:min([value]) -> sliderObject | number</a>
* <a href="#rectOfTickMark">slider:rectOfTickMark(index) -> table</a>
* <a href="#tickMarkLocation">slider:tickMarkLocation([location]) -> sliderObject | string</a>
* <a href="#tickMarkValue">slider:tickMarkValue(mark) -> number</a>
* <a href="#tickMarks">slider:tickMarks([marks]) -> sliderObject | integer</a>
* <a href="#tickMarksOnly">slider:tickMarksOnly([state]) -> sliderObject | boolean</a>
* <a href="#trackFillColor">slider:trackFillColor([color]) -> sliderObject | table</a>
* <a href="#type">slider:type([type]) -> sliderObject | string</a>
* <a href="#value">slider:value([value]) -> sliderObject | number</a>
* <a href="#vertical">slider:vertical([state]) -> sliderObject | boolean</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
slider.new([frame]) -> sliderObject
~~~
Creates a new slider element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the element.

Returns:
 * the sliderObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

### Module Methods

<a name="altClickIncrement"></a>
~~~lua
slider:altClickIncrement([value]) -> sliderObject | number
~~~
Get or set the amount the slider will move if the user holds down the alt (option) key while clicking on it.

Parameters:
 * `value` - an optional number greater than or equal to 0 specifying the amount the slider will move when the user holds down the alt (option) key while clicking on it.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * If this value is 0, holding down the alt (option) key while clicking on the slider has the same effect that not holding down the modifier does: the slider jumps to the position where the click occurs.

- - -

<a name="callback"></a>
~~~lua
slider:callback([fn | nil]) -> sliderObject | fn | nil
~~~
Get or set the callback function which will be invoked whenever the user clicks on the slider element.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user clicks on the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * The slider callback will receive two arguments and should return none. The arguments will be the sliderObject userdata and the value represented by the sliders new position -- see [hs._asm.guitk.element.slider:value](#value)

- - -

<a name="closestTickMark"></a>
~~~lua
slider:closestTickMark(value) -> integer
~~~
Get the index of the tick mark closest to the specified value.

Parameters:
 * `value` - the number to find the closest tick mark to.

Returns:
 * the index of the the tick mark closest to the value provided to this method.

Notes:
 * Returns 0 if the slider has no tick marks
 * See also [hs._asm.guitk.element.slider:closestTickMarkValue](#closestTickMarkValue)

- - -

<a name="closestTickMarkValue"></a>
~~~lua
slider:closestTickMarkValue(value) -> number
~~~
Get the value of the tick mark closest to the specified value.

Parameters:
 * `value` - the number to find the closest tick mark to.

Returns:
 * the number represented by the tick mark closest to the value provided to this method.

Notes:
 * Returns `value` if the slider has no tick marks
 * See also [hs._asm.guitk.element.slider:closestTickMark](#closestTickMark)

- - -

<a name="indexOfTickMarkAt"></a>
~~~lua
slider:indexOfTickMarkAt(point) -> integer | nil
~~~
Get the index of the tick mark closest to the specified point

Parameters:
 * `point` - a point table containing `x` and `y` coordinates of a point within the slider element's frame

Returns:
 * If the specified point is within the frame of a tick mark, returns the index of the matching tick mark; otherwise returns nil.

Notes:
 * It is currently not possible to invoke mouse tracking on just a single element; instead you must enable it for the manager the slider belongs to and calculate the point to compare by adjusting it to be relative to the slider elements top left point, e.g.
~~~lua
   g = require("hs._asm.guitk")
   w = g.new{ x = 100, y = 100, h = 100, w = 300 }:contentManager(g.manager.new()):show()
   m = w:contentManager():mouseCallback(function(mgr, message, point)
                             local geomPoint   = hs.geometry.new(point)
                             local slider      = mgr(1)
                             local sliderFrame = slider:frameDetails()._effective
                             if message == "move" and geomPoint:inside(sliderFrame) then
                                 local index = slider:indexOfTickMarkAt{
                                     x = point.x - sliderFrame.x,
                                     y = point.y - sliderFrame.y
                                 }
                                 if index then print("hovering over", index) end
                             end
                         end):trackMouseMove(true)
   m[1] = {
       _element = g.element.slider.new():tickMarks(10),
       frameDetails = { h = 100, w = 300 }
   }
~~~
 * A more efficient solution is being considered that would allow limiting tracking to only those elements one is interested in but there is no specific eta at this point.

- - -

<a name="knobThickness"></a>
~~~lua
slider:knobThickness() -> number
~~~
Get the thickness of the knob on the slider.

Parameters:
 * None

Returns:
 * a number specifying the thickness of the slider's knob in pixels.

Notes:
 * The thickness is defined to be the extent of the knob along the long dimension of the bar. In a vertical slider, a knob’s thickness is its height; in a horizontal slider, a knob’s thickness is its width.

- - -

<a name="max"></a>
~~~lua
slider:max([value]) -> sliderObject | number
~~~
Get or set the maximum value the slider can represent.

Parameters:
 * `value` - an optional number (default 1.0) specifying the maximum value for the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * If this value is less than [hs._asm.guitk.element.slider:min](#min), the behavior of the slider is undefined.

- - -

<a name="min"></a>
~~~lua
slider:min([value]) -> sliderObject | number
~~~
Get or set the minimum value the slider can represent.

Parameters:
 * `value` - an optional number (default 0.0) specifying the minimum value for the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * If this value is greater than [hs._asm.guitk.element.slider:max](#max), the behavior of the slider is undefined.

- - -

<a name="rectOfTickMark"></a>
~~~lua
slider:rectOfTickMark(index) -> table
~~~
Get the frame table of the tick mark at the specified index

Parameters:
 * `index` - an integer specifying the index of the tick mark to get the frame of

Returns:
 * a frame table specifying the tick mark's location within the element's frame. The frame coordinates will be relative to the top left corner of the slider's frame in it's parent.

- - -

<a name="tickMarkLocation"></a>
~~~lua
slider:tickMarkLocation([location]) -> sliderObject | string
~~~
Get or set where tick marks are displayed for the slider.

Parameters:
 * `location` - an optional string, default "trailing", specifying whether the tick marks are displayed to the left/below ("trailing") the slider or to the right/above ("leading") the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * This method has no effect on a circular slider -- see [hs._asm.guitk.element.slider:type](#type).
 * If [hs._asm.guitk.element.slider:tickMarks](#tickMarks) is 0, this method has no effect.

- - -

<a name="tickMarkValue"></a>
~~~lua
slider:tickMarkValue(mark) -> number
~~~
Get the value represented by the specified tick mark.

Parameters:
 * `mark` - an integer, between 1 and [hs._asm.guitk.element.slider:tickMarks](#tickMarks), specifying the tick mark to get the slider value of.

Returns:
 * the number represented by the specified tick mark.

- - -

<a name="tickMarks"></a>
~~~lua
slider:tickMarks([marks]) -> sliderObject | integer
~~~
Get or set the number of tick marks for the slider.

Parameters:
 * `marks` - an optional integer (default 0) specifying the number of tick marks for the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * If the slider is linear, the tick marks will be arranged at equal intervals along the slider. If the slider is circular, a single tick mark will be displayed at the top of the slider for any number passed in that is greater than 0 -- see [hs._asm.guitk.element.slider:type](#type).
 * A circular slider with [hs._asm.guitk.element.slider:tickMarksOnly](#tickMarksOnly) set to true will still be limited to the number of discrete intervals specified by the value set by this method, even though the specific tick marks are not visible.

- - -

<a name="tickMarksOnly"></a>
~~~lua
slider:tickMarksOnly([state]) -> sliderObject | boolean
~~~
Get or set whether the slider limits values to those specified by tick marks or allows selecting a value between tick marks.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the slider is limited to discrete values indicated by the tick marks (true) or allows values in between as well (false).

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * has no effect if [hs._asm.guitk.element.slider:tickMarks](#tickMarks) is 0

- - -

<a name="trackFillColor"></a>
~~~lua
slider:trackFillColor([color]) -> sliderObject | table
~~~
Get or set the color of the slider track in appearances that support it.

Parameters:
 * `color` - a color table as defined in `hs.drawing.color`, or explicit nil to reset to the default, specifying the color of the track for the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * This method is only available in macOS 10.12.1 and newer.
 * This method currently appears to have no effect on the visual appearance on the slider; as it was added to the macOS API in 10.12.1, it is suspected that this may be supported in the future and is included here for when that happens.

- - -

<a name="type"></a>
~~~lua
slider:type([type]) -> sliderObject | string
~~~
Get or set whether the slider is linear or circular.

Parameters:
 * `type` - an optional string, default "linear", specifying whether the slider is circular ("circular") or linear ("linear")

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * The length of a linear slider will expand to fill the dimension appropriate based on the value of [hs._asm.guitk.element.slider:vertical](#vertical); a circular slider will be anchored to the lower right corner of the element's frame.

- - -

<a name="value"></a>
~~~lua
slider:value([value]) -> sliderObject | number
~~~
Get or set the current value of the slider, adjusting the knob position if necessary.

Parameters:
 * `value` - an optional number specifying the value for the slider.

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * If the value is less than [hs._asm.guitk.element.slider:min](#min), then it will be set to the minimum instead.
 * If the value is greater than [hs._asm.guitk.element.slider:max](#max), then it will be set to the maximum instead.

- - -

<a name="vertical"></a>
~~~lua
slider:vertical([state]) -> sliderObject | boolean
~~~
Get or set whether a linear slider is vertical or horizontal.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not a linear slider is vertical (true) or horizontal (false).

Returns:
 * if a value is provided, returns the sliderObject ; otherwise returns the current value.

Notes:
 * This method has no effect on a circular slider -- see [hs._asm.guitk.element.slider:type](#type).

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


