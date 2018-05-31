hs._asm.guitk.element._control
==============================

Common methods inherited by elements which act as controls. Generally these are elements which are manipulated directly by the user to supply information or trigger a desired action.

Currently, the elements which inherit these methods are:
 * hs._asm.guitk.element.button
 * hs._asm.guitk.element.colorwell
 * hs._asm.guitk.element.datepicker
 * hs._asm.guitk.element.image
 * hs._asm.guitk.element.slider
 * hs._asm.guitk.element.textfield

macOS Developer Note: Understanding this is not required for use of the methods provided by this submodule, but for those interested, some of the elements provided under `hs._asm.guitk.element` are subclasses of the macOS NSControl class; macOS methods which belong to NSControl and are not overridden or superseded by more specific or appropriate element specific methods are defined here so that they can be used by all elements which share this common ancestor.

### Usage

This module should not be loaded directly; it is automatically added to elements which inherit these methods when `hs._asm.guitk` is loaded.

### Contents

##### Module Methods
* <a href="#continuous">element:continuous([state]) -> elementObject | current value</a>
* <a href="#controlSize">element:controlSize([size]) -> elementObject | current value</a>
* <a href="#controlTint">element:controlTint([tint]) -> elementObject | current value</a>
* <a href="#enabled">element:enabled([state]) -> elementObject | current value</a>
* <a href="#font">element:font([font]) -> elementObject | current value</a>
* <a href="#highlighted">element:highlighted([state]) -> elementObject | current value</a>
* <a href="#lineBreakMode">element:lineBreakMode([mode]) -> elementObject | string</a>
* <a href="#singleLineMode">element:singleLineMode([state]) -> elementObject | boolean</a>
* <a href="#textAlignment">element:textAlignment([alignment]) -> elementObject | current value</a>

- - -

### Module Methods

<a name="continuous"></a>
~~~lua
element:continuous([state]) -> elementObject | current value
~~~
Get or set whether or not the element triggers continuous callbacks when the user interacts with it.

Paramaters:
 * `state` - an optional boolean indicating whether or not continuous callbacks are generated for the element when the user interacts with it.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * The exact effect of this method depends upon the type of element; for example with the color well setting this to true will cause a callback as the user drags the mouse around in the color wheel; for a textfield this determines whether a callback occurs after each character is entered or deleted or just when the user enters or exits the textfield.

- - -

<a name="controlSize"></a>
~~~lua
element:controlSize([size]) -> elementObject | current value
~~~
Get or set the level of details in terms of the expected size of the element

Parameters:
 * `size` - an optional string specifying the size, in a general way, necessary to properly display the element.  Valid strings are as follows:
   * "regular" - present the element in its normal default size
   * "small"   - present the element in a more compact form; for example when a windows toolbar offers the "Use small size" option.
   * "mini"    - present the element in an even smaller form

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * The exact effect this has on each element is type specific and may change the look of the element in other ways as well, such as reducing or removing borders for buttons -- the intent is provide a differing level of detail appropriate to the chosen element size; it is still incumbent upon you to select an appropriate sized font or frame size to take advantage of the level of detail provided.

- - -

<a name="controlTint"></a>
~~~lua
element:controlTint([tint]) -> elementObject | current value
~~~
Get or set the tint for the element

Parameters:
 * `tint` - an optional string specifying the tint of the element's visual components.  Valid strings are as follows:
   * "default"
   * "blue"
   * "graphite"
   * "clear"

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * This method of providing differentiation between elements was more prominent in earlier versions of macOS and may have little or no effect on most visual elements in the current os.

- - -

<a name="enabled"></a>
~~~lua
element:enabled([state]) -> elementObject | current value
~~~
Get or set whether or not the element is currently enabled.

Parameters:
 * `state` - an optional boolean indicating whether or not the element is enabled.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

- - -

<a name="font"></a>
~~~lua
element:font([font]) -> elementObject | current value
~~~
Get or set the font used for displaying text for the element.

Paramaters:
 * `font` - an optional table specifying a font as defined in `hs.styledtext`.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * a font table is defined as having two key-value pairs: `name` specifying the name of the font as a string and `size` specifying the font size as a number.

- - -

<a name="highlighted"></a>
~~~lua
element:highlighted([state]) -> elementObject | current value
~~~
Get or set whether or not the element has a highlighted appearance.

Parameters:
 * `state` - an optional boolean indicating whether or not the element has a highlighted appearance.

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

Notes:
 * Not all elements have a highlighted appearance and this method will have no effect in such cases.

- - -

<a name="lineBreakMode"></a>
~~~lua
element:lineBreakMode([mode]) -> elementObject | string
~~~
Get or set the linebreak mode used for displaying text for the element.

Parameters:
 * `mode` - an optional string specifying the line break mode for the element. Must be one of:
   * "wordWrap"       - Wrapping occurs at word boundaries, unless the word itself doesn’t fit on a single line.
   * "charWrap"       - Wrapping occurs before the first character that doesn’t fit.
   * "clip"           - Lines are simply not drawn past the edge of the text container.
   * "truncateHead"   - The line is displayed so that the end fits in the container and the missing text at the beginning of the line is indicated by an ellipsis glyph.
   * "truncateTail"   - The line is displayed so that the beginning fits in the container and the missing text at the end of the line is indicated by an ellipsis glyph.
   * "truncateMiddle" - The line is displayed so that the beginning and end fit in the container and the missing text in the middle is indicated by an ellipsis glyph.

Returns:
 * if a value is provided, returns the elementObject ; otherwise returns the current value.

- - -

<a name="singleLineMode"></a>
~~~lua
element:singleLineMode([state]) -> elementObject | boolean
~~~
Get or set whether the element restricts layout and rendering of text to a single line.

Parameters:
 * `state` - an optional boolean specifying whether the element restricts text to a single line.

Returns:
 * if a value is provided, returns the element ; otherwise returns the current value.

Notes:
 * When this is set to true, text layout and rendering is restricted to a single line. The element will interpret [hs._asm.guitk.element._control:lineBreakMode](#lineBreakMode) modes of "charWrap" and "wordWrap" as if they were "clip" and an editable textfield will ignore key binding commands that insert paragraph and line separators.

- - -

<a name="textAlignment"></a>
~~~lua
element:textAlignment([alignment]) -> elementObject | current value
~~~
Get or set the alignment of text which is displayed by the element, often as a label or description.

Parameters:
 * `alignment` - an optional string specifying the alignment of the text being displayed by the element. Valid strings are as follows:
   * "left"      - Align text along the left edge
   * "center"    - Align text equally along both sides of the center line
   * "right"     - Align text along the right edge
   * "justified" - Fully justify the text so that the last line in a paragraph is natural aligned
   * "natural"   - Use the default alignment associated with the current locale. The default alignment for left-to-right scripts is "left", and the default alignment for right-to-left scripts is "right".

Returns:
 * if an argument is provided, returns the elementObject userdata; otherwise returns the current value

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


