hs._asm.guitk.element
=====================

THis submodule provides common methods and metamethods linking a variety of visual elements that can be used with `hs._asm.guitk` to build your own visual displays and input  interfaces within Hammerspoon.

This module by itself provides no elements, but serves as the glue between it's submodules and the guitk window and manager objects.  Elements are defined as submodules to this and may inherit methods defined in `hs._asm.guitk.element._control` and `hs._asm.guitk.element._view`.  The documentation for each specific element will indicate if it inherits methods from one of these helper submodules.

Methods invoked on element userdata objects which are not recognized by the element itself are passed up the responder chain (`hs._asm.guitk.manager` and `hs._asm.guitk`) as well, allowing you to work from the userdata which is most relevant without having to track the userdata for its supporting infrastructure separately. This will become more clear in the examples provided at a location to be determined (currently in the [../Examples](../Examples) directory of this repository folder).

### Installation

This module provides gui elements only and requires its parent [hs._asm.guitk](..) for proper use. See the instructions for installing the parent module for current installation instructions.

### Usage
~~~lua
element = require("hs._asm.guitk").element
~~~

### Submodules

* [hs._asm.guitk.element._control](README._control.md)
* [hs._asm.guitk.element._view](README._view.md)
* [hs._asm.guitk.element.avplayer](README.avplayer.md)
* [hs._asm.guitk.element.button](README.button.md)
* [hs._asm.guitk.element.colorwell](README.colorwell.md)
* [hs._asm.guitk.element.datepicker](README.datepicker.md)
* [hs._asm.guitk.element.image](README.image.md)
* [hs._asm.guitk.element.progress](README.progress.md)
* [hs._asm.guitk.element.slider](README.slider.md)
* [hs._asm.guitk.element.textfield](README.textfield.md)

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


