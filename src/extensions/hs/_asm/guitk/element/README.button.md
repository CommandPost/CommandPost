hs._asm.guitk.element.button
============================

Provides button and checkbox elements for use with `hs._asm.guitk`.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
button = require("hs._asm.guitk").element.button
~~~

### Contents

##### Module Constructors
* <a href="#buttonType">button.buttonType(type, [frame]) -> buttonObject</a>
* <a href="#buttonWithImage">button.buttonWithImage(image) -> buttonObject</a>
* <a href="#buttonWithTitle">button.buttonWithTitle(title) -> buttonObject</a>
* <a href="#buttonWithTitleAndImage">button.buttonWithTitleAndImage(title, image) -> buttonObject</a>
* <a href="#checkbox">button.checkbox(title) -> buttonObject</a>
* <a href="#radioButton">button.radioButton(title) -> buttonObject</a>
* <a href="#radioButtonSet">button.radioButtonSet(...) -> managerObject</a>

##### Module Methods
* <a href="#allowsMixedState">button:allowsMixedState([state]) -> buttonObject | boolean</a>
* <a href="#alternateImage">button:alternateImage([image]) -> buttonObject | hs.image object | nil</a>
* <a href="#alternateTitle">button:alternateTitle([title]) -> buttonObject | string | hs.styledtext object</a>
* <a href="#bezelStyle">button:bezelStyle([style]) -> buttonObject | string</a>
* <a href="#borderOnHover">button:borderOnHover([state]) -> buttonObject | boolean</a>
* <a href="#bordered">button:bordered([state]) -> buttonObject | boolean</a>
* <a href="#callback">button:callback([fn | nil]) -> buttonObject | fn | nil</a>
* <a href="#highlighted">button:highlighted([state]) -> buttonObject | boolean</a>
* <a href="#image">button:image([image]) -> buttonObject | hs.image object | nil</a>
* <a href="#imagePosition">button:imagePosition([position]) -> buttonObject | string</a>
* <a href="#imageScaling">button:imageScaling([scale]) -> buttonObject | string</a>
* <a href="#maxAcceleratorLevel">button:maxAcceleratorLevel([level]) -> buttonObject | integer</a>
* <a href="#periodicDelay">button:periodicDelay([table]) -> buttonObject | table</a>
* <a href="#sound">button:sound([sound]) -> buttonObject | hs.sound object | nil</a>
* <a href="#state">button:state([state]) -> buttonObject | string</a>
* <a href="#title">button:title([title]) -> buttonObject | string | hs.styledtext object</a>
* <a href="#transparent">button:transparent([state]) -> buttonObject | boolean</a>
* <a href="#value">button:value([float]) -> integer | double</a>

- - -

### Module Constructors

<a name="buttonType"></a>
~~~lua
button.buttonType(type, [frame]) -> buttonObject
~~~
Creates a new button element of the specified type for `hs._asm.guitk`.

Parameters:
 * `button` - a string specifying the type of button to create. The string must be one of the following:
   * "momentaryLight"        - When the button is clicked (on state), it appears illuminated. If the button has borders, it may also appear recessed. When the button is released, it returns to its normal (off) state. This type of button is best for simply triggering actions because it doesn’t show its state; it always displays its normal image or title.
   * "pushOnPushOff"         - When the button is clicked (on state), it appears illuminated. If the button has borders, it may also appear recessed. A second click returns it to its normal (off) state.
   * "toggle"                - After the first click, the button displays its alternate image or title (on state); a second click returns the button to its normal (off) state.
   * "switch"                - This style is a variant of "toggle" that has no border and is typically used to represent a checkbox.
   * "radio"                 - This style is similar to "switch", but it is used to constrain a selection to a single element from several elements.
   * "momentaryChange"       - When the button is clicked, the alternate (on state) image and alternate title are displayed. Otherwise, the normal (off state) image and title are displayed.
   * "onOff"                 - The first click highlights the button; a second click returns it to the normal (unhighlighted) state.
   * "momentaryPushIn"       - When the user clicks the button (on state), the button appears illuminated. Most buttons in macOS, such as Cancel button in many dialogs, are momentary light buttons. If you click one, it highlights briefly, triggers an action, and returns to its original state.
   * "accelerator"           - On pressure-sensitive systems, such as systems with the Force Touch trackpad, an accelerator button sends repeating actions as pressure changes occur. It stops sending actions when the user releases pressure entirely. Only available in macOS 10.12 and newer.
   * "multiLevelAccelerator" - A multilevel accelerator button is a variation of a normal accelerator button that allows for a configurable number of stepped pressure levels. As each one is reached, the user receives light tactile feedback and an action is sent. Only available in macOS 10.12 and newer.
 * `frame` - an optional frame table specifying the position and size of the frame for the button.

Returns:
 * a new buttonObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * See also:
   * [hs._asm.guitk.element.button.buttonWithTitle](#buttonWithTitle)
   * [hs._asm.guitk.element.button.buttonWithTitleAndImage](#buttonWithTitleAndImage)
   * [hs._asm.guitk.element.button.buttonWithImage](#buttonWithImage)
   * [hs._asm.guitk.element.button.checkbox](#checkbox)
   * [hs._asm.guitk.element.button.radioButton](#radioButton)

- - -

<a name="buttonWithImage"></a>
~~~lua
button.buttonWithImage(image) -> buttonObject
~~~
Creates a new button element of the specified of type "momentaryPushIn" with the specified title for `hs._asm.guitk`.

Parameters:
 * `image` - the `hs.image` object specifying the image to display in the button.

Returns:
 * a new buttonObject

Notes:
 * This creates a standard macOS push button with the image centered within the button.
 * The default frame created will be the minimum size necessary to display the button with the image. If you need to adjust the button's size further, do so with the element frame details options available once the button element is attached to a guitk manager (see `hs._asm.guitk.manager`)

 * This constructor uses an NSButton initializer introduced with macOS 10.12; for macOS versions prior to this, this module attempts to mimic the appearance and behavior of the button using the equivalent of [hs._asm.guitk.element.button.buttonType](#buttonType) and the other methods within this module. If you believe that something has been missed in the fallback initializer, please submit an issue to the Hammerspoon github site.

 * See also:
   * [hs._asm.guitk.element.button.buttonType](#buttonType)
   * [hs._asm.guitk.element.button.buttonWithTitle](#buttonWithTitle)
   * [hs._asm.guitk.element.button.buttonWithTitleAndImage](#buttonWithTitleAndImage)

- - -

<a name="buttonWithTitle"></a>
~~~lua
button.buttonWithTitle(title) -> buttonObject
~~~
Creates a new button element of the specified of type "momentaryPushIn" with the specified title for `hs._asm.guitk`.

Parameters:
 * `title` - the title which will be displayed in the button

Returns:
 * a new buttonObject

Notes:
 * This creates a standard macOS push button with the title centered within the button.
 * The default frame created will be the minimum size necessary to display the button with its title. If you need to adjust the button's size further, do so with the element frame details options available once the button element is attached to a guitk manager (see `hs._asm.guitk.manager`)

 * This constructor uses an NSButton initializer introduced with macOS 10.12; for macOS versions prior to this, this module attempts to mimic the appearance and behavior of the button using the equivalent of [hs._asm.guitk.element.button.buttonType](#buttonType) and the other methods within this module. If you believe that something has been missed in the fallback initializer, please submit an issue to the Hammerspoon github site.

 * See also:
   * [hs._asm.guitk.element.button.buttonType](#buttonType)
   * [hs._asm.guitk.element.button.buttonWithTitleAndImage](#buttonWithTitleAndImage)
   * [hs._asm.guitk.element.button.buttonWithImage](#buttonWithImage)

- - -

<a name="buttonWithTitleAndImage"></a>
~~~lua
button.buttonWithTitleAndImage(title, image) -> buttonObject
~~~
Creates a new button element of the specified of type "momentaryPushIn" with the specified title and image for `hs._asm.guitk`.

Parameters:
 * `title` - the title which will be displayed in the button
 * `image` - the `hs.image` object specifying the image to display preceding the button title.

Returns:
 * a new buttonObject

Notes:
 * This creates a standard macOS push button with an image at the left and the title centered within the button.
 * The default frame created will be the minimum size necessary to display the button with its image and title. If you need to adjust the button's size further, do so with the element frame details options available once the button element is attached to a guitk manager (see `hs._asm.guitk.manager`)

 * This constructor uses an NSButton initializer introduced with macOS 10.12; for macOS versions prior to this, this module attempts to mimic the appearance and behavior of the button using the equivalent of [hs._asm.guitk.element.button.buttonType](#buttonType) and the other methods within this module. If you believe that something has been missed in the fallback initializer, please submit an issue to the Hammerspoon github site.

 * See also:
   * [hs._asm.guitk.element.button.buttonType](#buttonType)
   * [hs._asm.guitk.element.button.buttonWithTitle](#buttonWithTitle)
   * [hs._asm.guitk.element.button.buttonWithImage](#buttonWithImage)

- - -

<a name="checkbox"></a>
~~~lua
button.checkbox(title) -> buttonObject
~~~
Creates a new checkbox button element of the specified of type "switch" with the specified title for `hs._asm.guitk`.

Parameters:
 * `title` - the title which will be displayed next to the checkbox

Returns:
 * a new buttonObject

Notes:
 * This creates a standard macOS checkbox with the title next to it.
 * The default frame created will be the minimum size necessary to display the checkbox with its title. If you need to adjust the button's size further, do so with the element frame details options available once the button element is attached to a guitk manager (see `hs._asm.guitk.manager`)

 * This constructor uses an NSButton initializer introduced with macOS 10.12; for macOS versions prior to this, this module attempts to mimic the appearance and behavior of the button using the equivalent of [hs._asm.guitk.element.button.buttonType](#buttonType) and the other methods within this module. If you believe that something has been missed in the fallback initializer, please submit an issue to the Hammerspoon github site.

 * See also [hs._asm.guitk.element.button.buttonType](#buttonType)

- - -

<a name="radioButton"></a>
~~~lua
button.radioButton(title) -> buttonObject
~~~
Creates a new radio button element of the specified of type "radio" with the specified title for `hs._asm.guitk`.

Parameters:
 * `title` - the title which will be displayed next to the radio button

Returns:
 * a new buttonObject

Notes:
 * This creates a standard macOS radio button with the title next to it.
   * Only one radio button in the same manager can be active (selected) at one time; multiple radio buttons in the same manager are treated as a group or set.
   * To display multiple independent radio button sets in the same window or view (manager), each group must be in a separate `hs._asm.guitk.manager` object and these separate objects may then be assigned as elements to a "parent" manager which is assigned to the `hs._asm.guitk` window; alternatively use [hs._asm.guitk.element.button.radioButtonSet](#radioBUttonSet)

 * The default frame created will be the minimum size necessary to display the checkbox with its title. If you need to adjust the button's size further, do so with the element frame details options available once the button element is attached to a guitk manager (see `hs._asm.guitk.manager`)

 * This constructor uses an NSButton initializer introduced with macOS 10.12; for macOS versions prior to this, this module attempts to mimic the appearance and behavior of the button using the equivalent of [hs._asm.guitk.element.button.buttonType](#buttonType) and the other methods within this module. If you believe that something has been missed in the fallback initializer, please submit an issue to the Hammerspoon github site.

 * See also:
   * [hs._asm.guitk.element.button.radioButtonSet](#radioBUttonSet)
   * [hs._asm.guitk.element.button.buttonType](#buttonType)

- - -

<a name="radioButtonSet"></a>
~~~lua
button.radioButtonSet(...) -> managerObject
~~~
Creates an `hs._asm.guitk.manager` object which can be used as an element containing a set of radio buttons with labels defined by the specified title strings.

Parameters:
 `...` - a single table of strings, or list of strings separated by commas, specifying the labels to assign to the radion buttons in the set.

Returns:
 * a new managerObject which can be used as an element to another `hs._asm.guitk.manager` or assigned to an `hs._asm.guitk` window directly.

Notes:
 * Radio buttons in the same view (manager) are treated as related and only one can be selected at a time. By grouping radio button sets in separate managers, these independant managers can be assigned to a parent manager and each set will be seen as independent -- each set can have a selected item independent of the other radio sets which may also be displayed in the parent.

 * For example:
~~~ lua
    g = require("hs._asm.guitk")
    m = g.new{ x = 100, y = 100, h = 100, w = 130 }:contentManager(g.manager.new()):contentManager():show()
    m[1] = g.element.button.radioButtonSet(1, 2, 3, 4)
    m[2] = g.element.button.radioButtonSet{"abc", "d", "efghijklmn"}
    m(2):moveRightOf(m(1), 10, "centered")
~~~

See [hs._asm.guitk.element.button.radioButton](#radioButton) for more details.

### Module Methods

<a name="allowsMixedState"></a>
~~~lua
button:allowsMixedState([state]) -> buttonObject | boolean
~~~
Get or set whether the button allows for a mixed state in addition to "on" and "off"

Parameters:
 * `state` - an optional boolean specifying whether the button allows for a mixed state

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * Mixed state is typically useful only with buttons of type "switch" or "radio" and is primarily used to indicate that something is only applied partially, e.g. when part of a selection of text is bold but not all of it. When a checkbox or radio button is in the "mixed" state, it is displayed with a dash instead of an X or a filled in radio button.
 * See also [hs._asm.guitk.element.button:state](#state)

- - -

<a name="alternateImage"></a>
~~~lua
button:alternateImage([image]) -> buttonObject | hs.image object | nil
~~~
Get or set the alternate image displayed by button types which support this

Parameters:
 * `image` - an optional hs.image object, or explicit nil to remove, specifying the alternate image for the button.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * For buttons which change their appearance based upon their state, this is the image which will be displayed when the button is in its "on" state.

 * Observation shows that the alternateImage value is used by the following button types:
   * "toggle"          - the button will alternate between the image and the alternateImage
   * "momentaryChange" - if the button is not bordered, the alternate image will be displayed while the user is clicking on the button and will revert back to the image once the user has released the mouse button.///    * "switch"               - when the checkbox is checked, it will display its alternateImage as the checked box, if one has been assigned
   * "radio"           - when the radio button is selected, it will display its alternateImage as the filled in radio button, if one has been assigned
 * Other button types have not been observed to use this attribute; if you believe you have discovered something we have missed here, please submit an issue to the Hamemrspoon github web site.

- - -

<a name="alternateTitle"></a>
~~~lua
button:alternateTitle([title] | [type]) -> buttonObject | string | hs.styledtext object
~~~
Get or set the alternate title displayed by button types which support this

Parameters:
 * to set the alternate title:
   * `title` - an optional string or `hs.styledtext` object specifying the alternate title to set for the button.
 * to get the current alternate title:
   * `type`  - an optional boolean, default false, specifying if the value retrieved should be as an `hs.styledtext` object (true) or as a string (false).

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * For buttons which change their appearance based upon their state, this is the title which will be displayed when the button is in its "on" state.

 * Observation shows that the alternateTitle value is used by the following button types:
   * "toggle"          - the button will alternate between the title and the alternateTitle
   * "momentaryChange" - if the button is not bordered, the alternate title will be displayed while the user is clicking on the button and will revert back to the title once the user has released the mouse button.
   * "switch"          - when the checkbox is checked, it will display its alternateTitle, if one has been assigned
   * "radio"           - when the radio button is selected, it will display its alternateTitle, if one has been assigned
 * Other button types have not been observed to use this attribute; if you believe you have discovered something we have missed here, please submit an issue to the Hamemrspoon github web site.

- - -

<a name="bezelStyle"></a>
~~~lua
button:bezelStyle([style]) -> buttonObject | string
~~~
Get or set the bezel style for the button

Parameters:
 * `style` - an optional string specifying the bezel style for the button. Must be one of the following strings:
   * "rounded"           - A rounded rectangle button, designed for text.
   * "regularSquare"     - A rectangular button with a two-point border, designed for icons.
   * "disclosure"        - A bezel style for use with a disclosure triangle. Works best with a button of type "onOff".
   * "shadowlessSquare"  - Similar to "regularSquare", but has no shadow, so you can abut the buttons without overlapping shadows. This style would be used in a tool palette, for example.
   * "circular"          - A round button with room for a small icon or a single character.
   * "texturedSquare"    - A bezel style appropriate for use with textured (metal) windows.
   * "helpButton"        - A round button with a question mark providing the standard help button look.
   * "smallSquare"       - A simple square bezel style. Buttons using this style can be scaled to any size.
   * "texturedRounded"   - A textured (metal) bezel style similar in appearance to the Finder’s action (gear) button.
   * "roundRect"         - A bezel style that matches the search buttons in Finder and Mail.
   * "recessed"          - A bezel style that matches the recessed buttons in Mail, Finder and Safari.
   * "roundedDisclosure" - Similar to "disclosure", but appears as an up or down caret within a small rectangular button. Works best with a button of type "onOff".
   * "inline"            - The inline bezel style contains a solid round-rect border background. It can be used to create an "unread" indicator in an outline view, or another inline button in a tableview, such as a stop progress button in a download panel. Use text for an unread indicator, and a template image for other buttons.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

- - -

<a name="borderOnHover"></a>
~~~lua
button:borderOnHover([state]) -> buttonObject | boolean
~~~
Get or set whether the button's border is toggled when the mouse hovers over the button

Parameters:
 * `state` - an optional boolean specifying whether the button's border is toggled when the mouse hovers over the button

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * Has no effect on buttons of type "switch" or "radio"
 * Changing this value will not affect whether or not the border is currently being displayed until the cursor actually hovers over the button or the button is clicked by the user. To keep the visual display in sync, make sure to set this value before displaying the guitk (e.g. `hs._asm.guitk:show()`) or set the border manually to the initial state you wish with [hs._asm.guitk.element.button:bordered](#bordered).

- - -

<a name="bordered"></a>
~~~lua
button:bordered([state]) -> buttonObject | boolean
~~~
Get or set whether a border is displayed around the button.

Parameters:
 * `state` - an optional boolean specifying whether the button should display a border around the button area or not.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * setting this to true for the "switch" or "radio" button types will prevent the alternate image, if defined, from being displayed.

- - -

<a name="callback"></a>
~~~lua
button:callback([fn | nil]) -> buttonObject | fn | nil
~~~
Get or set the callback function which will be invoked whenever the user clicks on the button element.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the clicks on the button.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * The button callback will receive two arguments and should return none. The arguments will be the buttonObject userdata and the new button state -- see [hs._asm.guitk.element.button:state](#state)

- - -

<a name="highlighted"></a>
~~~lua
button:highlighted([state]) -> buttonObject | boolean
~~~
Get or set whether the button is currently highlighted.

Parameters:
 * `state` - an optional boolean specifying whether or not the button is currently highlighted.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * Highlighting makes the button appear recessed, displays its alternate title or image, or causes the button to appear illuminated.

- - -

<a name="image"></a>
~~~lua
button:image([image]) -> buttonObject | hs.image object | nil
~~~
Get or set the image displayed for the button

Parameters:
 * `image` - an optional hs.image object, or explicit nil to remove, specifying the image for the button.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * For buttons which change their appearance based upon their state, this is the image which will be displayed when the button is in its "off" state.

- - -

<a name="imagePosition"></a>
~~~lua
button:imagePosition([position]) -> buttonObject | string
~~~
Get or set the position of the image relative to its title for the button

Parameters:
 * `position` - an optional string specifying the position of the image relative to its title for the button. Must be one of the following strings:
   * "none"     - The button doesn’t display an image.
   * "only"     - The button displays an image, but not a title.
   * "left"     - The image is to the left of the title.
   * "right"    - The image is to the right of the title.
   * "below"    - The image is below the title.
   * "above"    - The image is above the title.
   * "overlaps" - The image overlaps the title.

   * "leading"  - The image leads the title as defined for the current language script direction. Available in macOS 10.12+.
   * "trailing" - The image trails the title as defined for the current language script direction. Available in macOS 10.12+.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

- - -

<a name="imageScaling"></a>
~~~lua
button:imageScaling([scale]) -> buttonObject | string
~~~
Get or set the scaling mode applied to the image for the button

Parameters:
 * `scale` - an optional string specifying the scaling mode applied to the image for the button. Must be one of the following strings:
   * "proportionallyDown"     - If it is too large for the destination, scale the image down while preserving the aspect ratio.
   * "axesIndependently"      - Scale each dimension to exactly fit destination.
   * "none"                   - Do not scale the image.
   * "proportionallyUpOrDown" - Scale the image to its maximum possible dimensions while both staying within the destination area and preserving its aspect ratio.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

- - -

<a name="maxAcceleratorLevel"></a>
~~~lua
button:maxAcceleratorLevel([level]) -> buttonObject | integer
~~~
Get or set the number of discrete pressure levels recognized by a button of type "multiLevelAccelerator"

Parameters:
 * `level` - an optional integer specifying the number of discrete pressure levels recognized by a button of type "multiLevelAccelerator". Must be an integer between 1 and 5 inclusive.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * This method and the "multiLevelAccelerator" button type are only supported in macOS 10.12 and newer.

- - -

<a name="periodicDelay"></a>
~~~lua
button:periodicDelay([table]) -> buttonObject | table
~~~
Get or set the delay and interval periods for the callbacks of a continuous button.

Parameters:
 * `table` - an optional table specifying the delay and interval periods for the callbacks of a continuous button. The default is { 0.4, 0.075 }.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * To make a button continuous, see `hs._asm.guitk.element._control:continuous`. By default, buttons are *not* continuous.

 * The table passed in as an argument or returned by this method should contain two numbers:
   * the delay in seconds before the callback will be first invoked for the continuous button
   * the interval in seconds between subsequent callbacks after the first one has been invoked.
 * Once the user releases the mouse button, a final callback will be invoked for the button and will reflect the new [hs._asm.guitk.element.button:state](#state) for the button.

- - -

<a name="sound"></a>
~~~lua
button:sound([sound]) -> buttonObject | hs.sound object | nil
~~~
Get or set the sound played when the user clicks on the button

Parameters:
 * `sound` - an optional hs.sound object, or explicit nil to remove, specifying the sound played when the user clicks on the button

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

- - -

<a name="state"></a>
~~~lua
button:state([state]) -> buttonObject | string
~~~
Get or set the current state of the button.

Parameters:
 * `state` - an optional string used to set the current state of the button. Must be one of "on", "off", or "mixed".

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * Setting the state to "mixed" is only valid when [hs._asm.guitk.element.button:allowsMixedState](#allowsMixedState) is set to true.
 * Mixed state is typically useful only with buttons of type "switch" or "radio" and is primarily used to indicate that something is only applied partially, e.g. when part of a selection of text is bold but not all of it. When a checkbox or radio button is in the "mixed" state, it is displayed with a dash instead of an X or a filled in radio button.

- - -

<a name="title"></a>
~~~lua
button:title([title] | [type]) -> buttonObject | string | hs.styledtext object
~~~
Get or set the title displayed for the button

Parameters:
 * to set the title:
   * `title` - an optional string or `hs.styledtext` object specifying the title to set for the button.
 * to get the current title:
   * `type`  - an optional boolean, default false, specifying if the value retrieved should be as an `hs.styledtext` object (true) or as a string (false).

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

Notes:
 * For buttons which change their appearance based upon their state, this is the title which will be displayed when the button is in its "off" state.

 * The button constructors which allow specifying a title require a string; if you wish to change to a styled text object, you'll need to invoke this method on the new object after it is constructed.

- - -

<a name="transparent"></a>
~~~lua
button:transparent([state]) -> buttonObject | boolean
~~~
Get or set whether the button's background is transparent.

Parameters:
 * `state` - an optional boolean specifying whether the button's background is transparent.

Returns:
 * if a value is provided, returns the buttonObject ; otherwise returns the current value.

- - -

<a name="value"></a>
~~~lua
button:value([float]) -> integer | double
~~~
Get the current value represented by the button's state

Parameters:
 * `float` - an optional boolean specifying whether or not the value should be returned as a number (true) or as an integer (false). Defaults to false.

Returns:
 * The current value of the button as represented by its state.

Notes:
 * In general, this method will return 0 when the button's state is "off" and 1 when the button's state is "on" -- see [hs._asm.guitk.element.button:state](#state).
 * If [hs._asm.guitk.element.button:allowsMixedState](#allowsMixedState) has been set to true for this button, this method will return -1 when the button's state is "mixed".

 * If the button is of the "accelerator" type and the user is using a Force Touch capable trackpad, you can pass `true` to this method to get a relative measure of the amount of pressure being applied; this method will return a number between 1.0 and 2.0 representing the amount of pressure being applied when `float` is set to true.  If `float` is false or left out, then an "accelerator" type button will just return 1 as long as any pressure is being applied to the button.

 * If the button is of the "multiLevelAccelerator" type and the user is using a Force Touch capable trackpad, this method will return a number between 0 (not being pressed) up to the value set for [hs._asm.guitk.element.button:maxAcceleratorLevel](#maxAcceleratorLevel), depending upon how much pressure is being applied to the button.

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


