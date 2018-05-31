hs._asm.guitk.element.image
===========================

Provides an image holder element `hs._asm.guitk`. The image can be static, specified by you, or it can be an editable element, allowing the user to change the image through drag-and-drop or cut-and-paste.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
image = require("hs._asm.guitk").element.image
~~~

### Contents

##### Module Constructors
* <a href="#new">image.new([frame]) -> imageObject</a>

##### Module Methods
* <a href="#callback">image:callback([fn | nil]) -> imageObject | fn | nil</a>
* <a href="#image">image:image([image]) -> imageObject | hs.image | nil</a>
* <a href="#imageAlignment">image:imageAlignment([alignment]) -> imageObject | string</a>
* <a href="#imageFrameStyle">image:imageFrameStyle([style]) -> imageObject | string</a>
* <a href="#imageScaling">image:imageScaling([scale]) -> imageObject | string</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
image.new([frame]) -> imageObject
~~~
Creates a new image holder element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the element.

Returns:
 * the imageObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * If you do not assign an image to the element with [hs._asm.guitk.element.image:image](#image) after creating a new image element, the element will not have a default height or width; when assigning the element to an `hs._asm.guitk.manager`, be sure to specify them in the frame details or the element may not be visible.

### Module Methods

<a name="callback"></a>
~~~lua
image:callback([fn | nil]) -> imageObject | fn | nil
~~~
Get or set the callback function which will be invoked whenever the user changes the image of the element by dragging or pasting an image into it.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the image inside the element is changed by the user.

Returns:
 * if a value is provided, returns the imageObject ; otherwise returns the current value.

Notes:
 * The image callback will receive one argument and should return none. The argument will be the imageObject userdata.
   * Use [hs._asm.guitk.element.image:image](#image) on the argument to get the new image.

- - -

<a name="image"></a>
~~~lua
image:image([image]) -> imageObject | hs.image | nil
~~~
Get or set the image currently being displayed in the image element.

Parameters:
 * `image` - an optional `hs.image` object, or explicit nil to remove, representing the image currently being displayed by the image element.

Returns:
 * if a value is provided, returns the imageObject ; otherwise returns the current value.

Notes:
 * If the element is editable or supports cut-and-paste, any change made by the user to the image will be available to Hammerspoon through this method.

- - -

<a name="imageAlignment"></a>
~~~lua
image:imageAlignment([alignment]) -> imageObject | string
~~~
Get or set the alignment of the image within the image element.

Parameters:
 * `alignment` - an optional string, default "center", specifying the images alignment within the element frame. Valid strings are as follows:
   * "topLeft"     - the image's top left corner will match the element frame's top left corner
   * "top"         - the image's top match the element frame's top and will be centered horizontally
   * "topRight"    - the image's top right corner will match the element frame's top right corner
   * "left"        - the image's left side will match the element frame's left side and will be centered vertically
   * "center"      - the image will be centered vertically and horizontally within the element frame
   * "right"       - the image's right side will match the element frame's right side and will be centered vertically
   * "bottomLeft"  - the image's bottom left corner will match the element frame's bottom left corner
   * "bottom"      - the image's bottom match the element frame's bottom and will be centered horizontally
   * "bottomRight" - the image's bottom right corner will match the element frame's bottom right corner

Returns:
 * if a value is provided, returns the imageObject ; otherwise returns the current value.

- - -

<a name="imageFrameStyle"></a>
~~~lua
image:imageFrameStyle([style]) -> imageObject | string
~~~
Get or set the visual frame drawn around the image element area.

Parameters:
 * `style` - an optional string, default "none", specifying the frame to draw around the image element area. Valid strings are as follows:
   * "none"   - no frame is drawing around the image element frame
   * "photo"  - a thin black outline with a white background and a dropped shadow.
   * "bezel"  - a gray, concave bezel with no background that makes the image look sunken
   * "groove" - a thin groove with a gray background that looks etched around the image
   * "button" - a convex bezel with a gray background that makes the image stand out in relief, like a butto

Returns:
 * if a value is provided, returns the imageObject ; otherwise returns the current value.

Notes:
 * Apple considers the photo, groove, and button style frames "stylistically obsolete" and if a frame is required, recommend that you use the bezel style or draw your own to more closely match the OS look and feel.

- - -

<a name="imageScaling"></a>
~~~lua
image:imageScaling([scale]) -> imageObject | string
~~~
Get or set the scaling applied to the image if it doesn't fit the image element area exactly

Parameters:
 * `scale` - an optional string, default "proportionallyDown", specifying how to scale the image when it doesn't fit the element area exactly. Valid strings are as follows:
   * "proportionallyDown"     - shrink the image, preserving the aspect ratio, to fit the element frame if the image is larger than the element frame
   * "axesIndependently"      - shrink or expand the image to fully fill the element frame. This does not preserve the aspect ratio
   * "none"                   - perform no scaling or resizing of the image
   * "proportionallyUpOrDown" - shrink or expand the image to fully fill the element frame, preserving the aspect ration

Returns:
 * if a value is provided, returns the imageObject ; otherwise returns the current value.

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


