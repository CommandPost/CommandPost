hs._asm.guitk.element.avplayer
==============================

Provides an AudioVisual player element for `hs._asm.guitk`.

If you wish to include other elements within the window containing the avplayer object, you will need to use an `hs._asm.guitk.manager` object.  However, since this element is fully self contained and provides its own controls for video playback, it may be easier to attach this element directly to a `hs._asm.guitk` window object when you don't require other elements in the visual display.

Playback of remote or streaming content has been tested against http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8, which is a sample URL provided in the Apple documentation at https://developer.apple.com/library/prerelease/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW4

* This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

### Usage
~~~lua
progress = require("hs._asm.guitk").element.avplayer
~~~

### Contents

##### Module Constructors
* <a href="#new">avplayer.new([frame]) -> avplayerObject</a>

##### Module Methods
* <a href="#allowExternalPlayback">avplayer:allowExternalPlayback([state]) -> avplayerObject | boolean</a>
* <a href="#callback">avplayer:callback(fn) -> avplayerObject | fn | nil</a>
* <a href="#ccEnabled">avplayer:ccEnabled([state]) -> avplayerObject | boolean</a>
* <a href="#controlsStyle">avplayer:controlsStyle([style]) -> avplayerObject | string</a>
* <a href="#currentTime">avplayer:currentTime() -> number | nil</a>
* <a href="#duration">avplayer:duration() -> number | nil</a>
* <a href="#externalPlayback">avplayer:externalPlayback() -> Boolean</a>
* <a href="#flashChapterAndTitle">avplayer:flashChapterAndTitle(number, [string]) -> avplayerObject</a>
* <a href="#frameSteppingButtons">avplayer:frameSteppingButtons([state]) -> avplayerObject | boolean</a>
* <a href="#fullScreenButton">avplayer:fullScreenButton([state]) -> avplayerObject | boolean</a>
* <a href="#load">avplayer:load(path) -> avplayerObject</a>
* <a href="#mute">avplayer:mute([state]) -> avplayerObject | boolean</a>
* <a href="#pause">avplayer:pause() -> avplayerObject</a>
* <a href="#pauseWhenHidden">avplayer:pauseWhenHidden([state]) -> avplayerObject | boolean</a>
* <a href="#play">avplayer:play([fromBeginning]) -> avplayerObject</a>
* <a href="#playbackInformation">avplayer:playbackInformation() -> table | nil</a>
* <a href="#rate">avplayer:rate([rate]) -> avplayerObject | number</a>
* <a href="#seek">avplayer:seek(time, [callback]) -> avplayerObject | nil</a>
* <a href="#sharingServiceButton">avplayer:sharingServiceButton([state]) -> avplayerObject | boolean</a>
* <a href="#status">avplayer:status() -> status[, error] | nil</a>
* <a href="#trackCompleted">avplayer:trackCompleted([state]) -> avplayerObject | boolean</a>
* <a href="#trackProgress">avplayer:trackProgress([number | nil]) -> avplayerObject | number | nil</a>
* <a href="#trackRate">avplayer:trackRate([state]) -> avplayerObject | boolean</a>
* <a href="#trackStatus">avplayer:trackStatus([state]) -> avplayerObject | boolean</a>
* <a href="#volume">avplayer:volume([volume]) -> avplayerObject | number</a>

- - -

### Module Constructors

<a name="new"></a>
~~~lua
avplayer.new([frame]) -> avplayerObject
~~~
Creates a new AVPlayer element for `hs._asm.guitk` which can display audiovisual media.

Parameters:
 * `frame` - an optional frame table specifying the position and size of the frame for the avplayer object.

Returns:
 * the avplayerObject

Notes:
 * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.

### Module Methods

<a name="allowExternalPlayback"></a>
~~~lua
avplayer:allowExternalPlayback([state]) -> avplayerObject | boolean
~~~
Get or set whether or not external playback via AirPlay is allowed for this item.

Parameters:
 * `state` - an optional boolean, default false, specifying whether external playback via AirPlay is allowed for this item.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.

 * External playback via AirPlay is only available in macOS 10.11 and newer.

- - -

<a name="callback"></a>
~~~lua
avplayer:callback(fn) -> avplayerObject | fn | nil
~~~
Get or Set the callback function for the avplayerObject.

Parameters:
 * `fn` - a function, or explicit `nil`, specifying the callback function which is used by this avplayerObject.  If `nil` is specified, the currently active callback function is removed.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * The callback function should expect 2 or more arguments.  The first two arguments will always be:
   * `avplayObject` - the avplayerObject userdata
   * `message`      - a string specifying the reason for the callback.
   * Additional arguments depend upon the message.  See the following methods for details concerning the arguments for each message:
     * `finished`   - [hs._asm.guitk.element.avplayer:trackCompleted](#trackCompleted)
     * `pause`      - [hs._asm.guitk.element.avplayer:trackRate](#trackRate)
     * `play`       - [hs._asm.guitk.element.avplayer:trackRate](#trackRate)
     * `progress`   - [hs._asm.guitk.element.avplayer:trackProgress](#trackProgress)
     * `seek`       - [hs._asm.guitk.element.avplayer:seek](#seek)
     * `status`     - [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus)

- - -

<a name="ccEnabled"></a>
~~~lua
avplayer:ccEnabled([state]) -> avplayerObject | boolean
~~~
Get or set whether or not the player can use close captioning, if it is included in the audiovisual content.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the player should display closed captioning information, if it is available.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

- - -

<a name="controlsStyle"></a>
~~~lua
avplayer:controlsStyle([style]) -> avplayerObject | string
~~~
Get or set the style of controls displayed in the avplayerObject for controlling media playback.

Parameters:
 * `style` - an optional string, default "default", specifying the stye of the controls displayed for controlling media playback.  The string may be one of the following:
   * `none`     - no controls are provided -- playback must be managed programmatically through Hammerspoon Lua code.
   * `inline`   - media controls are displayed in an autohiding status bar at the bottom of the media display.
   * `floating` - media controls are displayed in an autohiding panel which floats over the media display.
   * `minimal`  - media controls are displayed as a round circle in the center of the media display.
   * `none`     - no media controls are displayed in the media display.
   * `default`  - use the OS X default control style; under OS X 10.11, this is the "inline".

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

- - -

<a name="currentTime"></a>
~~~lua
avplayer:currentTime() -> number | nil
~~~
Returns the current position in seconds within the audiovisual media content.

Parameters:
 * None

Returns:
 * the current position, in seconds, within the audiovisual media content, or `nil` if no media content is currently loaded.

- - -

<a name="duration"></a>
~~~lua
avplayer:duration() -> number | nil
~~~
Returns the duration, in seconds, of the audiovisual media content currently loaded.

Parameters:
 * None

Returns:
 * the duration, in seconds, of the audiovisual media content currently loaded, if it can be determined, or `nan` (not-a-number) if it cannot.  If no item has been loaded, this method will return nil.

Notes:
 * the duration of an item which is still loading cannot be determined; you may want to use [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus) and wait until it receives a "readyToPlay" state before querying this method.

 * a live stream may not provide duration information and also return `nan` for this method.

 * Lua defines `nan` as a number which is not equal to itself.  To test if the value of this method is `nan` requires code like the following:
 ~~~lua
 duration = avplayer:duration()
 if type(duration) == "number" and duration ~= duration then
     -- the duration is equal to `nan`
 end
~~~

- - -

<a name="externalPlayback"></a>
~~~lua
avplayer:externalPlayback() -> Boolean
~~~
Returns whether or not external playback via AirPlay is currently active for the avplayer object.

Parameters:
 * None

Returns:
 * true, if AirPlay is currently being used to play the audiovisual content, or false if it is not.


Notes:
 * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.

 * External playback via AirPlay is only available in macOS 10.11 and newer.

- - -

<a name="flashChapterAndTitle"></a>
~~~lua
avplayer:flashChapterAndTitle(number, [string]) -> avplayerObject
~~~
Flashes the number and optional string over the media playback display momentarily.

Parameters:
 * `number` - an integer specifying the chapter number to display.
 * `string` - an optional string specifying the chapter name to display.

Returns:
 * the avplayerObject

Notes:
 * If only a number is provided, the text "Chapter #" is displayed.  If a string is also provided, "#. string" is displayed.

- - -

<a name="frameSteppingButtons"></a>
~~~lua
avplayer:frameSteppingButtons([state]) -> avplayerObject | boolean
~~~
Get or set whether frame stepping or scrubbing controls are included in the media controls.

Parameters:
 * `state` - an optional boolean, default false, specifying whether frame stepping (true) or scrubbing (false) controls are included in the media controls.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

- - -

<a name="fullScreenButton"></a>
~~~lua
avplayer:fullScreenButton([state]) -> avplayerObject | boolean
~~~
Get or set whether or not the full screen toggle button should be included in the media controls.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the full screen toggle button should be included in the media controls.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.

- - -

<a name="load"></a>
~~~lua
avplayer:load(path) -> avplayerObject
~~~
Load the specified resource for playback.

Parameters:
 * `path` - a string specifying the file path or URL to the audiovisual resource.

Returns:
 * the avplayerObject

Notes:
 * Content will not start autoplaying when loaded - you must use the controls provided in the audiovisual player or one of [hs._asm.guitk.element.avplayer:play](#play) or [hs._asm.guitk.element.avplayer:rate](#rate) to begin playback.

 * If the path or URL are malformed, unreachable, or otherwise unavailable, [hs._asm.guitk.element.avplayer:status](#status) will return "failed".
 * Because a remote URL may not respond immediately, you can also setup a callback with [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus) to be notified when the item has loaded or if it has failed.

- - -

<a name="mute"></a>
~~~lua
avplayer:mute([state]) -> avplayerObject | boolean
~~~
Get or set whether or not audio output is muted for the audovisual media item.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not audio output has been muted for the avplayer object.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

- - -

<a name="pause"></a>
~~~lua
avplayer:pause() -> avplayerObject
~~~
Pause the audiovisual media currently loaded in the avplayer object.

Parameters:
 * None

Returns:
 * the avplayerObject

Notes:
 * this is equivalent to setting the rate to 0.0 (see [hs._asm.guitk.element.avplayer:rate](#rate)`)

- - -

<a name="pauseWhenHidden"></a>
~~~lua
avplayer:pauseWhenHidden([state]) -> avplayerObject | boolean
~~~
Get or set whether or not playback of media should be paused when the avplayer object is hidden.

Parameters:
 * `state` - an optional boolean, default true, specifying whether or not media playback should be paused when the avplayer object is hidden.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Note:
 * this method currently does not work; fixing this is in the TODO list.

- - -

<a name="play"></a>
~~~lua
avplayer:play([fromBeginning]) -> avplayerObject
~~~
Play the audiovisual media currently loaded in the avplayer object.

Parameters:
 * `fromBeginning` - an optional boolean, default false, specifying whether or not the media playback should start from the beginning or from the current location.

Returns:
 * the avplayerObject

Notes:
 * this is equivalent to setting the rate to 1.0 (see [hs._asm.guitk.element.avplayer:rate](#rate)`)

- - -

<a name="playbackInformation"></a>
~~~lua
avplayer:playbackInformation() -> table | nil
~~~
Returns a table containing information about the media playback characteristics of the audiovisual media currently loaded in the avplayerObject.

Parameters:
 * None

Returns:
 * a table containing the following media characteristics, or `nil` if no media content is currently loaded:
   * "playbackLikelyToKeepUp" - Indicates whether the item will likely play through without stalling.  Note that this is only a prediction.
   * "playbackBufferEmpty"    - Indicates whether playback has consumed all buffered media and that playback may stall or end.
   * "playbackBufferFull"     - Indicates whether the internal media buffer is full and that further I/O is suspended.
   * "canPlayReverse"         - A Boolean value indicating whether the item can be played with a rate of -1.0.
   * "canPlayFastForward"     - A Boolean value indicating whether the item can be played at rates greater than 1.0.
   * "canPlayFastReverse"     - A Boolean value indicating whether the item can be played at rates less than –1.0.
   * "canPlaySlowForward"     - A Boolean value indicating whether the item can be played at a rate between 0.0 and 1.0.
   * "canPlaySlowReverse"     - A Boolean value indicating whether the item can be played at a rate between -1.0 and 0.0.

- - -

<a name="rate"></a>
~~~lua
avplayer:rate([rate]) -> avplayerObject | number
~~~
Get or set the rate of playback for the audiovisual content of the avplayer object.

Parameters:
 * `rate` - an optional number specifying the rate you wish for the audiovisual content to be played.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * This method affects the playback rate of both video and audio -- if you wish to mute audio during a "fast forward" or "rewind", see [hs._asm.guitk.element.avplayer:mute](#mute).
 * A value of 0.0 is equivalent to [hs._asm.guitk.element.avplayer:pause](#pause).
 * A value of 1.0 is equivalent to [hs._asm.guitk.element.avplayer:play](#play).

 * Other rates may not be available for all media and will be ignored if specified and the media does not support playback at the specified rate:
   * Rates between 0.0 and 1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlaySlowForward` field
   * Rates greater than 1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayFastForward` field
   * The item can be played in reverse (a rate of -1.0) if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayReverse` field
   * Rates between 0.0 and -1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlaySlowReverse` field
   * Rates less than -1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayFastReverse` field

- - -

<a name="seek"></a>
~~~lua
avplayer:seek(time, [callback]) -> avplayerObject | nil
~~~
Jumps to the specified location in the audiovisual content currently loaded into the player.

Parameters:
 * `time`     - the location, in seconds, within the audiovisual content to seek to.
 * `callback` - an optional boolean, default false, specifying whether or not a callback should be invoked when the seek operation has completed.

Returns:
 * the avplayerObject, or nil if no media content is currently loaded

Notes:
 * If you specify `callback` as true, the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 or 4 arguments:
   * the avplayerObject
   * "seek"
   * the current time, in seconds, specifying the current playback position in the media content
   * `true` if the seek operation was allowed to complete, or `false` if it was interrupted (for example by another seek request).

- - -

<a name="sharingServiceButton"></a>
~~~lua
avplayer:sharingServiceButton([state]) -> avplayerObject | boolean
~~~
Get or set whether or not the sharing services button is included in the media controls.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not the sharing services button is included in the media controls.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.

- - -

<a name="status"></a>
~~~lua
avplayer:status() -> status[, error] | nil
~~~
Returns the current status of the media content loaded for playback.

Parameters:
 * None

Returns:
 * One of the following status strings, or `nil` if no media content is currently loaded:
   * "unknown"     - The content's status is unknown; often this is returned when remote content is still loading or being evaluated for playback.
   * "readyToPlay" - The content has been loaded or sufficiently buffered so that playback may begin
   * "failed"      - There was an error loading the content; a second return value will contain a string which may contain more information about the error.

- - -

<a name="trackCompleted"></a>
~~~lua
avplayer:trackCompleted([state]) -> avplayerObject | boolean
~~~
Enable or disable a callback whenever playback of the current media content is completed (reaches the end).

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not completing the playback of media should invoke a callback.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 2 arguments:
   * the avplayerObject
   * "finished"

- - -

<a name="trackProgress"></a>
~~~lua
avplayer:trackProgress([number | nil]) -> avplayerObject | number | nil
~~~
Enable or disable a periodic callback at the interval specified.

Parameters:
 * `number` - an optional number specifying how often, in seconds, the callback function should be invoked to report progress.  If an explicit nil is specified, then the progress callback is disabled. Defaults to nil.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.  A return value of `nil` indicates that no progress callback is in effect.

Notes:
 * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 arguments:
   * the avplayerObject
   * "progress"
   * the time in seconds specifying the current location in the media playback.

 * From Apple Documentation: The block is invoked periodically at the interval specified, interpreted according to the timeline of the current item. The block is also invoked whenever time jumps and whenever playback starts or stops. If the interval corresponds to a very short interval in real time, the player may invoke the block less frequently than requested. Even so, the player will invoke the block sufficiently often for the client to update indications of the current time appropriately in its end-user interface.

- - -

<a name="trackRate"></a>
~~~lua
avplayer:trackRate([state]) -> avplayerObject | boolean
~~~
Enable or disable a callback whenever the rate of playback changes.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not playback rate changes should invoke a callback.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 arguments:
   * the avplayerObject
   * "pause", if the rate changes to 0.0, or "play" if the rate changes to any other value
   * the rate that the playback was changed to.

 * Not all media content can have its playback rate changed; attempts to do so will invoke the callback twice -- once signifying that the change was made, and a second time indicating that the rate of play was reset back to the limits of the media content.  See [hs._asm:rate](#rate) for more information.

- - -

<a name="trackStatus"></a>
~~~lua
avplayer:trackStatus([state]) -> avplayerObject | boolean
~~~
Enable or disable a callback whenever the status of loading a media item changes.

Parameters:
 * `state` - an optional boolean, default false, specifying whether or not changes to the status of audiovisual media's loading status should generate a callback..

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

Notes:
 * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 or 4 arguments:
   * the avplayerObject
   * "status"
   * a string matching one of the states described in [hs._asm.guitk.element.avplayer:status](#status)
   * if the state reported is failed, an error message describing the error that occurred.

- - -

<a name="volume"></a>
~~~lua
avplayer:volume([volume]) -> avplayerObject | number
~~~
Get or set the avplayer object's volume on a linear scale from 0.0 (silent) to 1.0 (full volume, relative to the current OS volume).

Parameters:
 * `volume` - an optional number, default as specified by the media or 1.0 if no designation is specified by the media, specifying the player's volume relative to the system volume level.

Returns:
 * if an argument is provided, the avplayerObject; otherwise the current value.

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


