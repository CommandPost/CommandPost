hs._asm.guitk.element.textfield
===============================

Provides text label and input field elements for use with `hs._asm.guitk`.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
textfield = require("hs._asm.guitk").element.textfield
~~~

### Contents

##### Module Constructors
* <a href="#new">textfield.new([frame]) -> textfieldObject</a>
* <a href="#newLabel">textfield.newLabel(text) -> textfieldObject</a>
* <a href="#newTextField">textfield.newTextField([text]) -> textfieldObject</a>
* <a href="#newWrappingLabel">textfield.newWrappingLabel(text) -> textfieldObject</a>

##### Module Methods
* <a href="#allowsCharacterPicker">textfield:allowsCharacterPicker([state]) -> textfieldObject | boolean</a>
* <a href="#automaticTextCompletion">textfield:automaticTextCompletion([state]) -> textfieldObject | boolean</a>
* <a href="#backgroundColor">textfield:backgroundColor([color]) -> textfieldObject | color table</a>
* <a href="#bezelStyle">textfield:bezelStyle([style]) -> textfieldObject | string</a>
* <a href="#bezeled">textfield:bezeled([state]) -> textfieldObject | boolean</a>
* <a href="#bordered">textfield:bordered([state]) -> textfieldObject | boolean</a>
* <a href="#callback">textfield:callback([fn | nil]) -> textfieldObject | fn | nil</a>
* <a href="#drawsBackground">textfield:drawsBackground([state]) -> textfieldObject | boolean</a>
* <a href="#editable">textfield:editable([state]) -> textfieldObject | boolean</a>
* <a href="#editingCallback">textfield:editingCallback([fn | nil]) -> textfieldObject | fn | nil</a>
* <a href="#expandIntoTooltip">textfield:expandIntoTooltip([state]) -> textfieldObject | boolean</a>
* <a href="#importsGraphics">textfield:importsGraphics([state]) -> textfieldObject | boolean</a>
* <a href="#maximumNumberOfLines">textfield:maximumNumberOfLines([lines]) -> textfieldObject | integer</a>
* <a href="#placeholderString">textfield:placeholderString([placeholder]) -> textfieldObject | string</a>
* <a href="#preferredMaxWidth">textfield:preferredMaxWidth([width]) -> textfieldObject | number</a>
* <a href="#selectAll">textfield:selectAll() -> textfieldObject</a>
* <a href="#selectable">textfield:selectable([state]) -> textfieldObject | boolean</a>
* <a href="#styleEditable">textfield:styleEditable([state]) -> textfieldObject | boolean</a>
* <a href="#textColor">textfield:textColor([color]) -> textfieldObject | color table</a>
* <a href="#tighteningForTruncation">textfield:tighteningForTruncation([state]) -> textfieldObject | boolean</a>
* <a href="#value">textfield:value([value] | [type]) -> textfieldObject | string | styledtextObject</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
textfield.new([frame]) -> textfieldObject
~~~
Creates a new textfield element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the element.

Returns:
 * the textfieldObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * The textfield element does not have a default width unless you assign a value to it with [hs._asm.guitk.element.textfield:value](#value); if you are assigning an empty textfield element to an `hs._asm.guitk.manager`, be sure to specify a width in the frame details or the element may not be visible.

- - -

<a name="newLabel"></a>
~~~lua
textfield.newLabel(text) -> textfieldObject
~~~
Creates a new textfield element usable as a label for `hs._asm.guitk`.

Parameters:
 * `text` - a string or `hs.styledtext` object specifying the text to assign to the label.

Returns:
 * the textfieldObject

Notes:
 * This constructor creates a non-editable, non-selectable text field, often used as a label for another element.
   * If you specify `text` as a string, the label is non-wrapping and appears in the default system font.
   * If you specify `text` as an `hs.styledtext` object, the line break mode and font are determined by the style attributes of the object.

- - -

<a name="newTextField"></a>
~~~lua
textfield.newTextField([text]) -> textfieldObject
~~~
Creates a new editable textfield element for `hs._asm.guitk`.

Parameters:
 * `text` - an optional string specifying the text to assign to the text field.

Returns:
 * the textfieldObject

Notes:
 * This constructor creates a non-wrapping, editable text field, suitable for accepting user input.

- - -

<a name="newWrappingLabel"></a>
~~~lua
textfield.newWrappingLabel(text) -> textfieldObject
~~~
Creates a new textfield element usable as a label for `hs._asm.guitk`.

Parameters:
 * `text` - a string specifying the text to assign to the label.

Returns:
 * the textfieldObject

Notes:
 * This constructor creates a wrapping, selectable, non-editable text field, that is suitable for use as a label or informative text. The text defaults to the system font.

### Module Methods

<a name="allowsCharacterPicker"></a>
~~~lua
textfield:allowsCharacterPicker([state]) -> textfieldObject | boolean
~~~
Get or set whether the textfield allows the use of the touchbar character picker when the textfield is editable and is being edited.

Parameters:
 * `state` - an optional boolean, default false, specifying whether the textfield allows the use of the touchbar character picker when the textfield is editable and is being edited.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * This method is only available in macOS 10.12.1 and newer

- - -

<a name="automaticTextCompletion"></a>
~~~lua
textfield:automaticTextCompletion([state]) -> textfieldObject | boolean
~~~
Get or set whether automatic text completion is enabled when the textfield is being edited.

Parameters:
 * `state` - an optional boolean, default true, specifying whether automatic text completion is enabled when the textfield is being edited.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * This method is only available in macOS 10.12.2 and newer

- - -

<a name="backgroundColor"></a>
~~~lua
textfield:backgroundColor([color]) -> textfieldObject | color table
~~~
Get or set the color for the background of the textfield element.

Parameters:
* `color` - an optional table containing color keys as described in `hs.drawing.color`

Returns:
 * If an argument is provided, the textfieldObject; otherwise the current value.

Notes:
 * The background color will only be drawn when [hs._asm.guitk.element.textfield:drawsBackground](#drawsBackground) is true.

- - -

<a name="bezelStyle"></a>
~~~lua
textfield:bezelStyle([style]) -> textfieldObject | string
~~~
Get or set whether the corners of a bezeled textfield are rounded or square

Parameters:
 * `style` - an optional string, default "square", specifying whether the corners of a bezeled textfield are rounded or square. Must be one of "square" or "round".

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * only has an effect if [hs._asm.guitk.element.textfield:bezeled](#bezeled) is true.

- - -

<a name="bezeled"></a>
~~~lua
textfield:bezeled([state]) -> textfieldObject | boolean
~~~
Get or set whether the textfield draws a bezeled border around its contents.

Parameters:
 * `state` - an optional boolean specifying whether the textfield draws a bezeled border around its contents. Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * If you set this to true, [hs._asm.guitk.element.textfield:bordered](#bordered) is set to false.

- - -

<a name="bordered"></a>
~~~lua
textfield:bordered([state]) -> textfieldObject | boolean
~~~
Get or set whether the textfield draws a black border around its contents.

Parameters:
 * `state` - an optional boolean, default false, specifying whether the textfield draws a black border around its contents.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * If you set this to true, [hs._asm.guitk.element.textfield:bezeled](#bezeled) is set to false.

- - -

<a name="callback"></a>
~~~lua
textfield:callback([fn | nil]) -> textfieldObject | fn | nil
~~~
Get or set the callback function which will be invoked whenever the user interacts with the textfield element.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user interacts with the textfield

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * The callback function should expect arguments as described below and return none:
   * When the user starts typing in the text field, the callback will receive the following arguments:
     * the textfield userdata object
     * the message string "didBeginEditing" indicating that the user has started editing the textfield element
   * When the focus leaves the text field element, the callback will receive the following arguments (note that it is possible to receive this callback without a corresponding "didBeginEditing" callback if the user makes no changes to the textfield):
     * the textfield userdata object
     * the message string "didEndEditing" indicating that the textfield element is no longer active
     * the current string value of the textfield -- see [hs._asm.guitk.element.textfield:value](#value)
     * a string specifying why editing terminated:
       * "other"    - another element has taken focus or the user has clicked outside of the text field
       * "return"   - the user has hit the enter or return key. Note that this does not take focus away from the textfield by default so if the user types again, another "didBeginEditing" callback for the textfield will be generated.
       * "tab"      - the user used the tab key to move to the next textfield element
       * "shiftTab" - the user user the tab key with the shift modifier to move to the previous textfield element
       * the specification allows for other possible reasons for ending the editing of a textfield, but so far it is not known how to enable these and they may apply to other text based elements which have not yet been implemented.  These are "cancel", "left", "right", "up", and "down". If you do see one of these reasons in your use of the textfield element, please submit an issue with sample code so it can be determined how to properly document this.
   * If the `hs._asm.guitk.element._control:continuous` is set to true for the textfield element, a callback with the following arguments will occur each time the user presses a key:
     * the textfield userdata object
     * the string "textDidChange" indicating that the user has typed or deleted something in the textfield
     * the current string value of the textfield -- see [hs._asm.guitk.element.textfield:value](#value)

- - -

<a name="drawsBackground"></a>
~~~lua
textfield:drawsBackground([state]) -> textfieldObject | boolean
~~~
Get or set whether the background of the textfield is shown

Parameters:
 * `state` - an optional boolean specifying whether the background of the textfield is shown (true) or transparent (false). Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

- - -

<a name="editable"></a>
~~~lua
textfield:editable([state]) -> textfieldObject | boolean
~~~
Get or set whether the textfield is editable.

Parameters:
 * `state` - an optional boolean specifying whether the textfield contents are editable. Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * Setting this to true automatically sets [hs._asm.guitk.element.textfield:selectable](#selectable) to true.

- - -

<a name="editingCallback"></a>
~~~lua
textfield:editingCallback([fn | nil]) -> textfieldObject | fn | nil
~~~
Get or set the callback function which will is invoked to make editing decisions about the textfield

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked to make editing decisions about the textfield

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * The callback function should expect multiple arguments and return a boolean as described below (a return value of none or nil will use the default as specified for each callback below):
   * When the user attempts to edit the textfield, the callback will be invoked with the following arguments and the boolean return value should indicate whether editing is to be allowed:
     * the textfield userdata object
     * the string "shouldBeginEditing" indicating that the callback is asking permission to allow editing of the textfield at this time
     * the default return value as determined by the current state of the the textfield and its location in the window/view hierarchy (usually this will be true)
   * When the user attempts to finish editing the textfield, the callback will be invoked with the following arguments and the boolean return value should indicate whether focus is allowed to leave the textfield:
     * the textfield userdata object
     * the string "shouldEndEditing" indicating that the callback is asking permission to complete editing of the textfield at this time
     * the default return value as determined by the current state of the the textfield and its location in the window/view hierarchy (usually this will be true)
   * When the return (or enter) key or escape key are pressed, the callback will be invoked with the following arguments and the return value should indicate whether or not the keypress was handled by the callback or should be passed further up the window/view hierarchy:
     * the textfield userdata object
     * the string "keyPress"
     * the string "return" or "escape"
     * the default return value of false indicating that the callback is not interested in this keypress.
   * Note that the return value is currently ignored when the key pressed is "escape".
   * Note that the specification allows for the additional keys "left", "right", "up", and "down" to trigger this callback, but at present it is not known how to enable this for a textfield element. It is surmised that they may be applicable to text based elements that are not currently supported by `hs._asm.guitk`. If you do manage to receive a callback for one of these keys, please submit an issue with sample code so we can determine how to properly document them.

- - -

<a name="expandIntoTooltip"></a>
~~~lua
textfield:expandIntoTooltip([state]) -> textfieldObject | boolean
~~~
Get or set whether the textfield contents will be expanded into a tooltip if the contents are longer than the textfield is wide and the mouse pointer hovers over the textfield.

Parameters:
 * `state` - an optional boolean, default false, specifying whether the textfield contents will be expanded into a tooltip if the contents are longer than the textfield is wide.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * If a tooltip is set with `hs._asm.guitk.element._control:tooltip` then this method has no effect.

- - -

<a name="importsGraphics"></a>
~~~lua
textfield:importsGraphics([state]) -> textfieldObject | boolean
~~~
Get or set whether an editable textfield whose style is editable allows image files to be dragged into it

Parameters:
 * `state` - an optional boolean, default false, specifying whether the textfield allows image files to be dragged into it

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * [hs._asm.guitk.element.textfield:styleEditable](#styleEditable) must also be true for this method to have any effect.

- - -

<a name="maximumNumberOfLines"></a>
~~~lua
textfield:maximumNumberOfLines([lines]) -> textfieldObject | integer
~~~
Get or set the maximum number of lines that can be displayed in the textfield.

Parameters:
 * `lines` - an optional integer, default 0, specifying the maximum number of lines that can be displayed in the textfield. A value of 0 indicates that there is no limit.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * This method is only available in macOS 10.11 and newer
 * If the text reaches the number of lines allowed, or the height of the container cannot accommodate the number of lines needed, the text will be clipped or truncated.
   * Affects the default fitting size when the textfield is assigned to an `hs._asm.guitk.manager` object if the textfield element's height and width are not specified when assigned.

- - -

<a name="placeholderString"></a>
~~~lua
textfield:placeholderString([placeholder]) -> textfieldObject | string
~~~
Get or set the placeholder string for the textfield.

Parameters:
* `placeholder` - an optional string or `hs.styledtext` object, or an explicit nil to remove, specifying the placeholder string for a textfield. The place holder string is displayed in a light color when the contents of the textfield is empty (i.e. is set to nil or the empty string "")

Returns:
 * If an argument is provided, the textfieldObject; otherwise the current value.

- - -

<a name="preferredMaxWidth"></a>
~~~lua
textfield:preferredMaxWidth([width]) -> textfieldObject | number
~~~
Get or set the preferred layout width for the textfield

Parameters:
 * `width` - an optional number, default 0.0, specifying the preferred width of the textfield

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

- - -

<a name="selectAll"></a>
~~~lua
textfield:selectAll() -> textfieldObject
~~~
Selects the text of a selectable or editable textfield and makes it the active element in the window.

Parameters:
 * None

Returns:
 * the textfieldObject

Notes:
 * This method has no effect if the textfield is not editable or selectable.  Use `hs._asm.guitk:activeElement` if you wish to remove the focus from any textfield that is currently selected.

- - -

<a name="selectable"></a>
~~~lua
textfield:selectable([state]) -> textfieldObject | boolean
~~~
Get or set whether the contents of the textfield is selectable.

Parameters:
 * `state` - an optional boolean specifying whether the textfield contents are selectable. Defaults to `true` for textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField) or [hs._asm.guitk.element.textfield.newWrappingLabel](#newWrappingLabel), otherwise false.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * Setting this to false automatically sets [hs._asm.guitk.element.textfield:editable](#editable) to false.

- - -

<a name="styleEditable"></a>
~~~lua
textfield:styleEditable([state]) -> textfieldObject | boolean
~~~
Get or set whether the style (font, color, etc.) of the text in an editable textfield can be changed by the user

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the style of the text can be edited in the textfield

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * If the style of a textfield element can be edited, the user will be able to access the font and color panels by right-clicking in the text field and selecting the Font submenu from the menu that is shown.

- - -

<a name="textColor"></a>
~~~lua
textfield:textColor([color]) -> textfieldObject | color table
~~~
Get or set the color for the the text in a textfield element.

Parameters:
* `color` - an optional table containing color keys as described in `hs.drawing.color`

Returns:
 * If an argument is provided, the textfieldObject; otherwise the current value.

Notes:
 * Has no effect on portions of an `hs.styledtext` value that specifies the text color for the object

- - -

<a name="tighteningForTruncation"></a>
~~~lua
textfield:tighteningForTruncation([state]) -> textfieldObject | boolean
~~~
Get or set whether the system may tighten inter-character spacing in the text field before truncating text.

Parameters:
 * `state` - an optional boolean, default false, specifying whether the system may tighten inter-character spacing in the text field before truncating text. Has no effect when the textfield is assigned an `hs.styledtext` object.

Returns:
 * if a value is provided, returns the textfieldObject ; otherwise returns the current value.

Notes:
 * This method is only available in macOS 10.11 and newer

- - -

<a name="value"></a>
~~~lua
textfield:value([value] | [type]) -> textfieldObject | string | styledtextObject
~~~
Get or set the contents of the textfield.

Parameters:
 * to set the textfield content:
   * `value` - an optional string or `hs.styledtext` object specifying the contents to display in the textfield
 * to get the current content of the textfield:
   * `type`  - an optional boolean specifying if the value retrieved should be as an `hs.styledtext` object (true) or a string (false). If no argument is provided, the value returned will be whatever type was last assigned to the textfield with this method or its constructor.

Returns:
 * If a string or `hs.styledtext` object is assigned with this method, returns the textfieldObject; otherwise returns the value in the type requested or most recently assigned.

Notes:
 * If no argument is provided and [hs._asm.guitk.element.textfield:styleEditable](#styleEditable) is true, if the style has been modified by the user an `hs.styledtext` object will be returned even if the most recent assignment was with a string value.

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


