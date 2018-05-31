hs._asm.guitk.element.datepicker
================================

Provides a date picker element for use with `hs._asm.guitk`.

* This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
datepicker = require("hs._asm.guitk").element.datepicker
~~~

### Contents

##### Module Constructors
* <a href="#new">datepicker.new([frame]) -> datepickerObject</a>

##### Module Methods
* <a href="#backgroundColor">datepicker:backgroundColor([color]) -> datepickerObject | color table</a>
* <a href="#bezeled">datepicker:bezeled([flag]) -> datepickerObject | boolean</a>
* <a href="#bordered">datepicker:bordered([enabled]) -> datepickerObject | boolean</a>
* <a href="#calendar">datepicker:calendar([calendar]) -> datepickerObject | string | nil</a>
* <a href="#callback">datepicker:callback([fn | nil]) -> datepickerObject | fn | nil</a>
* <a href="#date">datepicker:date([date]) -> datepickerObject | number</a>
* <a href="#dateRangeMode">datepicker:dateRangeMode([flag]) -> datepickerObject | boolean</a>
* <a href="#drawsBackground">datepicker:drawsBackground([flag]) -> datepickerObject | boolean</a>
* <a href="#locale">datepicker:locale([locale]) -> datepickerObject | string | nil</a>
* <a href="#maxDate">datepicker:maxDate([date]) -> datepickerObject | number</a>
* <a href="#minDate">datepicker:minDate([date]) -> datepickerObject | number</a>
* <a href="#pickerElements">datepicker.pickerElements([elements]) -> datepickerObject | table</a>
* <a href="#pickerStyle">datepicker:pickerStyle([style]) -> datepickerObject | string</a>
* <a href="#textColor">datepicker:textColor([color]) -> datepickerObject | color table</a>
* <a href="#timeInterval">datepicker:timeInterval([interval]) -> datepickerObject | integer</a>
* <a href="#timezone">datepicker:timezone([timezone]) -> datepickerObject | string | integer | nil</a>

##### Module Constants
* <a href="#calendarIdentifiers">datepicker.calendarIdentifiers</a>
* <a href="#timezoneAbbreviations">datepicker.timezoneAbbreviations</a>
* <a href="#timezoneNames">datepicker.timezoneNames</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
datepicker.new([frame]) -> datepickerObject
~~~
Creates a new date picker element for `hs._asm.guitk`.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for element.

Returns:
 * the datepickerObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

 * The initial date and time represented by the element will be the date and time when this function is invoked.  See [hs._asm.guitk.element.datepicker:date](#date).

### Module Methods

<a name="backgroundColor"></a>
~~~lua
datepicker:backgroundColor([color]) -> datepickerObject | color table
~~~
Get or set the color for the background of datepicker element.

Parameters:
* `color` - an optional table containing color keys as described in `hs.drawing.color`

Returns:
 * If an argument is provided, the datepickerObject; otherwise the current value.

Notes:
 * The background color will only be drawn when [hs._asm.guitk.element.datepicker:drawsBackground](#drawsBackground) is true.
 * If [hs._asm.guitk.element.datepicker:pickerStyle](#pickerStyle) is "textField" or "textFieldAndStepper", this will set the background of the text field. If it is "clockAndColor", only the calendar's background color will be set.

- - -

<a name="bezeled"></a>
~~~lua
datepicker:bezeled([flag]) -> datepickerObject | boolean
~~~
Get or set whether or not the datepicker element has a bezeled border around it.

Parameters:
 * `flag` - an optional boolean, default true, indicating whether or not the element's frame is bezeled.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * Setting this to true will set [hs._asm.guitk.element.datepicker:bordered](#bordered) to false.

- - -

<a name="bordered"></a>
~~~lua
datepicker:bordered([enabled]) -> datepickerObject | boolean
~~~
Get or set whether the datepicker element has a rectangular border around it.

Parameters:
 * `enabled` - an optional boolean, default false, specifying whether or not a border should be drawn around the element.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * Setting this to true will set [hs._asm.guitk.element.datepicker:bezeled](#bezeled) to false.

- - -

<a name="calendar"></a>
~~~lua
datepicker:calendar([calendar]) -> datepickerObject | string | nil
~~~
Get or set the current calendar used for displaying the date in the datepicker element.

Parameters:
 * `calendar` - an optional string specifying the calendar used when displaying the date in the element. Specify nil, the default value, to use the current system calendar.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * See [hs._asm.guitk.element.datepicker.calendarIdentifiers](#calendarIdentifiers) for valid strings that can be used with this method.

- - -

<a name="callback"></a>
~~~lua
datepicker:callback([fn | nil]) -> datepickerObject | fn | nil
~~~
Get or set the callback function which will be invoked when the user interacts with the datepicker element.

Parameters:
 * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user interacts with the element.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * The callback function should expect arguments as described below and return none:
   * When the datepicker is becomes active the callback will receive the following arguments:
     * the datepicker userdata object
     * the message string "didBeginEditing" indicating that the datepicker element has become active
   * When the user leaves the datepicker element, the callback will receive the following arguments:
     * the datepicker userdata object
     * the message string "didEndEditing" indicating that the datepicker element is no longer active
     * a number representing the selected date as the number of seconds since the epoch -- see [hs._asm.guitk.element.datepicker:date](#date)
   * When the user selects or changes the date or time in the datepicker element, and `hs._asm.guitk.element._control:continuous` is true for the element, the callback will receive the following arguments:
     * the datepicker userdata object
     * the message string "dateDidChange" indicating that the user has modified the date or time in the datepicker element.
     * a number representing the selected date as the number of seconds since the epoch -- see [hs._asm.guitk.element.datepicker:date](#date)

- - -

<a name="date"></a>
~~~lua
datepicker:date([date]) -> datepickerObject | number
~~~
Get or set the date, or initial date when dateRangeMode is true, and time displayed by the datepicker element.

Parameters:
 * `date` - an optional number representing a date and time as the number of seconds from 00:00:00 GMT on 1 January 1970. The default value will be the number representing the date and time when the element was constructed with [hs._asm.guitk.element.datepicker.new](#new).

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * Lua's `os.date` function can only handle integer values; this method returns fractions of a second in the decimal portion of the number, so you will need to convert the number to an integer first, e.g. `os.date("%c", math.floor(hs._asm.guitk.element.datepicker:date()))`

 * When [hs._asm.guitk.element.datepicker:dateRangeMode](#dateRangeMode) is true, the end date of the range can be calculated as `hs._asm.guitk.element.datepicker:date() + hs._asm.guitk.element.datepicker:timeInterval()`.

- - -

<a name="dateRangeMode"></a>
~~~lua
datepicker:dateRangeMode([flag]) -> datepickerObject | boolean
~~~
Get or set whether a date range can be selected by the datepicker object

Parameters:
 * `flag` - an optional boolean, default false, indicating whether or not the datepicker allows a single date (false) or a date range (true) to be selected.

Returns:
 * If an argument is provided, the datepickerObject; otherwise the current value.

Notes:
 * A date range can only be selected by the user when [hs._asm.guitk.element.datepicker:pickerStyle](#pickerStyle) is "clockAndCalendar".

 * When the user has selected a date range, the first date in the range will be available in [hs._asm.guitk.element.datepicker:date](#date) and the interval between the start and end date will be the number of seconds returned by [hs._asm.guitk.element.datepicker:timeInterval](#timeInterval)

- - -

<a name="drawsBackground"></a>
~~~lua
datepicker:drawsBackground([flag]) -> datepickerObject | boolean
~~~
Get or set whether or not the datepicker element draws its background.

Parameters:
 * `flag` - an optional boolean, default false, indicating whether or not the element's background is drawn.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * Setting this to true will draw the background of the element with the color specified with [hs._asm.guitk.element.datepicker:backgroundColor](#backgroundColor).

- - -

<a name="locale"></a>
~~~lua
datepicker:locale([locale]) -> datepickerObject | string | nil
~~~
Get or set the current locale used for displaying the datepicker element.

Parameters:
 * `locale` - an optional string specifying the locale that determines how the datepicker should be displayed. Specify nil, the default value, to use the current system locale.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * See `hs.host.locale.availableLocales` for a list of locales available.

- - -

<a name="maxDate"></a>
~~~lua
datepicker:maxDate([date]) -> datepickerObject | number
~~~
Get or set the maximum date and time the user is allowed to select with the datepicker element.

Parameters:
 * `date` - an optional number representing the maximum date and time that the user is allowed to select with the datepicker element. Set to nil, the default value, to specify that there is no maximum valid date and time.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * The behavior is undefined If a value is set with this method and it is less than the value of [hs._asm.guitk.element.datepicker:minDate](#minDate).

- - -

<a name="minDate"></a>
~~~lua
datepicker:minDate([date]) -> datepickerObject | number
~~~
Get or set the minimum date and time the user is allowed to select with the datepicker element.

Parameters:
 * `date` - an optional number representing the minimum date and time that the user is allowed to select with the datepicker element. Set to nil, the default value, to specify that there is no minimum valid date and time.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * The behavior is undefined If a value is set with this method and it is greater than the value of [hs._asm.guitk.element.datepicker:maxDate](#maxDate).

- - -

<a name="pickerElements"></a>
~~~lua
datepicker.pickerElements([elements]) -> datepickerObject | table
~~~
Get or set what date and time components the datepicker element presents to the user for modification

Parameters:
 * `elements` - an optional table containing the following key-value pairs:
   * `timeElement` - a string, default "HMS", specifying what time components to display. Valid strings are:
     * "HMS" - allows setting the hour, minute, and seconds of the time. This is the default.
     * "HM"  - allows setting the hour and minute of the time
     * "off" - do not present the time for modification; can also be nil (i.e. if the `timeElement` key is not provided)
   * `dateElement` - a string, default "YMD", specifying what date components to display. Valid strings are:
     * "YMD" - allows setting the year, month, and day of the date. This is the default.
     * "YM"  - allows setting the year and month; not valid when [hs._asm.guitk.element.datepicker:pickerStyle](#pickerStyle) is "clockAndCalendar" and will be reset to "YMD".
     * "off" - do not present the date for modification; can also be nil (i.e. if the `dateElement` key is not provided)

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

- - -

<a name="pickerStyle"></a>
~~~lua
datepicker:pickerStyle([style]) -> datepickerObject | string
~~~
Get or set the style of datepicker element displayed.

Parameters:
 * `style` - an optional string, default "textFieldAndStepper", specifying the images alignment within the element frame. Valid strings are as follows:
   * "textFieldAndStepper" - displays the date in an editable textfield with stepper arrows
   * "clockAndCalendar"    - displays a calendar and/or clock, depending upon the value of [hs._asm.guitk.element.datepicker:pickerElements](#pickerElements).
   * "textField"           - displays the date in an editable textfield

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

- - -

<a name="textColor"></a>
~~~lua
datepicker:textColor([color]) -> datepickerObject | color table
~~~
Get or set the color for the text of the datepicker element.

Parameters:
* `color` - an optional table containing color keys as described in `hs.drawing.color`

Returns:
 * If an argument is provided, the datepickerObject; otherwise the current value.

Notes:
 * This method only affects the text color when [hs._asm.guitk.element.datepicker:pickerStyle](#pickerStyle) is "textField" or "textFieldAndStepper".

- - -

<a name="timeInterval"></a>
~~~lua
datepicker:timeInterval([interval]) -> datepickerObject | integer
~~~
Get or set the interval between the start date and the end date when a range of dates is specified by the datepicker element.

Parameters:
 * `interval` - an optional integer specifying the interval between a the range of dates represented by the datepicker element.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * This value is only relevant when [hs._asm.guitk.element.datepicker:dateRangeMode](#dateRangeMode) is true and [hs._asm.guitk.element.datepicker:pickerStyle](#pickerStyle) is "clockAndCalendar".

 * If the user selects a range of dates in the calendar portion of the datepicker element, this number will be a multiple of 86400, the number of seconds in a day.
 * If you set a value with this method, it should be a multiple of 86400 - fractions of a day will not be visible or adjustable within the datepicker element.

- - -

<a name="timezone"></a>
~~~lua
datepicker:timezone([timezone]) -> datepickerObject | string | integer | nil
~~~
Get or set the current timezone used for displaying the time in the datepicker element.

Parameters:
 * `timezone` - an optional string or integer specifying the timezone used when displaying the time in the element. Specify nil, the default value, to use the current system timezone. If specified as an integer, the integer represents the number of seconds offset from GMT.

Returns:
 * if a value is provided, returns the datepickerObject ; otherwise returns the current value.

Notes:
 * See [hs._asm.guitk.element.datepicker.timezoneNames](#timezoneNames) and [hs._asm.guitk.element.datepicker.timezoneAbbreviations](#timezoneAbbreviations) for valid strings that can be used with this method.

### Module Constants

<a name="calendarIdentifiers"></a>
~~~lua
datepicker.calendarIdentifiers
~~~
A table which contains an array of strings listing the calendar types supported by the system.

These values can be used with [hs._asm.guitk.element.datepicker:calendar](#calendar) to adjust the date and calendar displayed by the datepicker element.

This constant has a `__tostring` metamethod defined so that you can type `require("hs._asm.guitk").element.datepicker.calendarIdentifiers` into the Hammerspoon console to see its contents.

- - -

<a name="timezoneAbbreviations"></a>
~~~lua
datepicker.timezoneAbbreviations
~~~
A table which contains a mapping of timezone abbreviations known to the system to the corresponding timezone name.

These values can be used with [hs._asm.guitk.element.datepicker:timezone](#timezone) to adjust the time displayed by the datepicker element.

This table contains key-value pairs in which each key is a timezone abbreviation and its value is the timezone name it represents. This table is generated when this module is loaded so that it will reflect the timezones recognized by the currently running version of macOS.

This constant has a `__tostring` metamethod defined so that you can type `require("hs._asm.guitk").element.datepicker.timezoneAbbreviations` into the Hammerspoon console to see its contents.

- - -

<a name="timezoneNames"></a>
~~~lua
datepicker.timezoneNames
~~~
A table which contains an array of strings listing the names of all the time zones known to the system.

These values can be used with [hs._asm.guitk.element.datepicker:timezone](#timezone) to adjust the time displayed by the datepicker element.

This table is generated when this module is loaded so that it will reflect the timezones recognized by the currently running version of macOS.

This constant has a `__tostring` metamethod defined so that you can type `require("hs._asm.guitk").element.datepicker.timezoneNames` into the Hammerspoon console to see its contents.

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


