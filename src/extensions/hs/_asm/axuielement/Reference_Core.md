hs._asm.axuielement
===================

This module allows you to access the accessibility objects of running applications, their windows, menus, and other user interface elements that support the OS X accessibility API.

This is very much a work in progress, so bugs and comments are welcome.

This module works through the use of axuielementObjects, which is the Hammerspoon representation for an accessibility object.  An accessibility object represents any object or component of an OS X application which can be manipulated through the OS X Accessibility API -- it can be an application, a window, a button, selected text, etc.  As such, it can only support those features and objects within an application that the application developers make available through the Accessibility API.

The basic methods available to determine what attributes and actions are available for a given object are described in this reference documentation.  In addition, the module will dynamically add methods for the attributes and actions appropriate to the object, but these will differ between object roles and applications -- again we are limited by what the target application developers provide us.

The dynamically generated methods will follow one of the following templates:
 * `object:*attribute*()`         - this will return the value for the specified attribute (see [hs._asm.axuielement:attributeValue](#attributeValue) for the generic function this is based on).
 * `object:set*attribute*(value)` - this will set the specified attribute to the given value (see [hs._asm.axuielement:setAttributeValue](#setAttributeValue) for the generic function this is based on).
 * `object:do*action*()`          - this request that the specified action is performed by the object (see [hs._asm.axuielement:performAction](#performAction) for the generic function this is based on).

Where *action* and *attribute* can be the formal Accessibility version of the attribute or action name (a string usually prefixed with "AX") or without the "AX" prefix.  When the prefix is left off, the first letter of the action or attribute can be uppercase or lowercase.

The module also dynamically supports treating the axuielementObject useradata as an array, to access it's children (i.e. `#object` will return a number, indicating the number of direct children the object has, and `object[1]` is equivalent to `object:children()[1]` or, more formally, `object:attributeValue("AXChildren")[1]`).

You can also treat the axuielementObject userdata as a table of key-value pairs to generate a list of the dynamically generated functions: `for k, v in pairs(object) do print(k, v) end` (this is essentially what [hs._asm.axuielement:dynamicMethods](#dynamicMethods) does).


Limited support for parameterized attributes is provided, but is not yet complete.  This is expected to see updates in the future.

### Usage
~~~lua
axuielement = require("hs._asm.axuielement")
~~~

### Contents


##### Module Constructors
* <a href="#applicationElement">axuielement.applicationElement(applicationObject) -> axuielementObject</a>
* <a href="#applicationElementForPID">axuielement.applicationElementForPID(pid) -> axuielementObject</a>
* <a href="#systemElementAtPosition">axuielement.systemElementAtPosition(x, y | { x, y }) -> axuielementObject</a>
* <a href="#systemWideElement">axuielement.systemWideElement() -> axuielementObject</a>
* <a href="#windowElement">axuielement.windowElement(windowObject) -> axuielementObject</a>

##### Module Methods
* <a href="#actionDescription">axuielement:actionDescription(action) -> string</a>
* <a href="#actionNames">axuielement:actionNames() -> table</a>
* <a href="#allAttributeValues">axuielement:allAttributeValues([includeErrors]) -> table</a>
* <a href="#asHSApplication">axuielement:asHSApplication() -> hs.application object | nil</a>
* <a href="#asHSWindow">axuielement:asHSWindow() -> hs.window object | nil</a>
* <a href="#attributeNames">axuielement:attributeNames() -> table</a>
* <a href="#attributeValue">axuielement:attributeValue(attribute) -> value</a>
* <a href="#attributeValueCount">axuielement:attributeValueCount(attribute) -> integer</a>
* <a href="#copy">axuielement:copy() -> axuielementObject</a>
* <a href="#dynamicMethods">axuielement:dynamicMethods([keyValueTable]) -> table</a>
* <a href="#elementAtPosition">axuielement:elementAtPosition(x, y | { x, y }) -> axuielementObject</a>
* <a href="#elementSearch">axuielement:elementSearch(matchCriteria, [isPattern], [includeParents]) -> table</a>
* <a href="#getAllChildElements">axuielement:getAllChildElements([parent], [callback]) -> table | axuielementObject</a>
* <a href="#isAttributeSettable">axuielement:isAttributeSettable(attribute) -> boolean</a>
* <a href="#matches">axuielement:matches(matchCriteria, [isPattern]) -> boolean</a>
* <a href="#parameterizedAttributeNames">axuielement:parameterizedAttributeNames() -> table</a>
* <a href="#parameterizedAttributeValue">axuielement:parameterizedAttributeValue(attribute, parameter) -> value</a>
* <a href="#performAction">axuielement:performAction(action) -> axuielement | false | nil</a>
* <a href="#pid">axuielement:pid() -> integer</a>
* <a href="#setAttributeValue">axuielement:setAttributeValue(attribute, value) -> axuielementObject | nil</a>

##### Module Constants
* <a href="#actions">axuielement.actions[]</a>
* <a href="#attributes">axuielement.attributes[]</a>
* <a href="#directions">axuielement.directions[]</a>
* <a href="#parameterizedAttributes">axuielement.parameterizedAttributes[]</a>
* <a href="#roles">axuielement.roles[]</a>
* <a href="#subroles">axuielement.subroles[]</a>

- - -

### Module Constructors

<a name="applicationElement"></a>
~~~lua
axuielement.applicationElement(applicationObject) -> axuielementObject
~~~
Returns the top-level accessibility object for the application specified by the `hs.application` object.

Parameters:
 * `applicationObject` - the `hs.application` object for the Application.

Returns:
 * an axuielementObject for the application specified

- - -

<a name="applicationElementForPID"></a>
~~~lua
axuielement.applicationElementForPID(pid) -> axuielementObject
~~~
Returns the top-level accessibility object for the application with the specified process ID.

Parameters:
 * `pid` - the process ID of the application.

Returns:
 * an axuielementObject for the application specified, or nil if it cannot be determined

- - -

<a name="systemElementAtPosition"></a>
~~~lua
axuielement.systemElementAtPosition(x, y | { x, y }) -> axuielementObject
~~~
Returns the accessibility object at the specified position in top-left relative screen coordinates.

Parameters:
 * `x`, `y`   - the x and y coordinates of the screen location to test, provided as separate parameters
 * `{ x, y }` - the x and y coordinates of the screen location to test, provided as a point-table, like the one returned by `hs.mouse.getAbsolutePosition`.

Returns:
 * an axuielementObject for the object at the specified coordinates, or nil if no object could be identified.

Notes:
 * See also [hs._asm.axuielement:elementAtPosition](#elementAtPosition) -- this function is a shortcut for `hs._asm.axuielement.systemWideElement():elementAtPosition(...)`.

 * This function does hit-testing based on window z-order (that is, layering). If one window is on top of another window, the returned accessibility object comes from whichever window is topmost at the specified location.

- - -

<a name="systemWideElement"></a>
~~~lua
axuielement.systemWideElement() -> axuielementObject
~~~
Returns an accessibility object that provides access to system attributes.

Parameters:
 * None

Returns:
 * the axuielementObject for the system attributes

- - -

<a name="windowElement"></a>
~~~lua
axuielement.windowElement(windowObject) -> axuielementObject
~~~
Returns the accessibility object for the window specified by the `hs.window` object.

Parameters:
 * `windowObject` - the `hs.window` object for the window.

Returns:
 * an axuielementObject for the window specified

### Module Methods

<a name="actionDescription"></a>
~~~lua
axuielement:actionDescription(action) -> string
~~~
Returns a localized description of the specified accessibility object's action.

Parameters:
 * `action` - the name of the action, as specified by [hs._asm.axuielement:actionNames](#actionNames).

Returns:
 * a string containing a description of the object's action

Notes:
 * The action descriptions are provided by the target application; as such their accuracy and usefulness rely on the target application's developers.

- - -

<a name="actionNames"></a>
~~~lua
axuielement:actionNames() -> table
~~~
Returns a list of all the actions the specified accessibility object can perform.

Parameters:
 * None

Returns:
 * an array of the names of all actions supported by the axuielementObject

Notes:
 * Common action names can be found in the [hs._asm.axuielement.actions](#actions) table; however, this method will list only those names which are supported by this object, and is not limited to just those in the referenced table.

- - -

<a name="allAttributeValues"></a>
~~~lua
axuielement:allAttributeValues([includeErrors]) -> table
~~~
Returns a table containing key-value pairs for all attributes of the accessibility object.

Parameters:
 * `includeErrors` - an optional boolean, default false, that specifies whether attribute names which generate an error when retrieved are included in the returned results.

Returns:
 * a table with key-value pairs corresponding to the attributes of the accessibility object.

- - -

<a name="asHSApplication"></a>
~~~lua
axuielement:asHSApplication() -> hs.application object | nil
~~~
If the element referes to an application, return an `hs.application` object for the element.

Parameters:
 * None

Returns:
 * if the element refers to an application, return an `hs.application` object for the element ; otherwise return nil

Notes:
 * An element is considered an application by this method if it has an AXRole of AXApplication and has a process identifier (pid).

- - -

<a name="asHSWindow"></a>
~~~lua
axuielement:asHSWindow() -> hs.window object | nil
~~~
If the element referes to a window, return an `hs.window` object for the element.

Parameters:
 * None

Returns:
 * if the element refers to a window, return an `hs.window` object for the element ; otherwise return nil

Notes:
 * An element is considered a window by this method if it has an AXRole of AXWindow.

- - -

<a name="attributeNames"></a>
~~~lua
axuielement:attributeNames() -> table
~~~
Returns a list of all the attributes supported by the specified accessibility object.

Parameters:
 * None

Returns:
 * an array of the names of all attributes supported by the axuielementObject

Notes:
 * Common attribute names can be found in the [hs._asm.axuielement.attributes](#attributes) tables; however, this method will list only those names which are supported by this object, and is not limited to just those in the referenced table.

- - -

<a name="attributeValue"></a>
~~~lua
axuielement:attributeValue(attribute) -> value
~~~
Returns the value of an accessibility object's attribute.

Parameters:
 * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).

Returns:
 * the current value of the attribute, or nil if the attribute has no value

- - -

<a name="attributeValueCount"></a>
~~~lua
axuielement:attributeValueCount(attribute) -> integer
~~~
Returns the count of the array of an accessibility object's attribute value.

Parameters:
 * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).

Returns:
 * the number of items in the value for the attribute, if it is an array, or nil if the value is not an array.

- - -

<a name="copy"></a>
~~~lua
axuielement:copy() -> axuielementObject
~~~
Return a duplicate userdata reference to the Accessibility object.

Parameters:
 * None

Returns:
 * a new userdata object representing a new reference to the Accessibility object.

Notes:
 * The new userdata will have no search state information attached to it, and is used internally by [hs._asm.axuielement:searchPath](#searchPath).

- - -

<a name="dynamicMethods"></a>
~~~lua
axuielement:dynamicMethods([keyValueTable]) -> table
~~~
Returns a list of the dynamic methods (short cuts) created by this module for the object

Parameters:
 * `keyValueTable` - an optional boolean, default false, indicating whether or not the result should be an array or a table of key-value pairs.

Returns:
 * If `keyValueTable` is true, this method returns a table of key-value pairs with each key being the name of a dynamically generated method, and the value being the corresponding function.  Otherwise, this method returns an array of the dynamically generated method names.

Notes:
 * the dynamically generated methods are described more fully in the reference documentation header, but basically provide shortcuts for getting and setting attribute values as well as perform actions supported by the Accessibility object the axuielementObject represents.

- - -

<a name="elementAtPosition"></a>
~~~lua
axuielement:elementAtPosition(x, y | { x, y }) -> axuielementObject
~~~
Returns the accessibility object at the specified position in top-left relative screen coordinates.

Parameters:
 * `x`, `y`   - the x and y coordinates of the screen location to test, provided as separate parameters
 * `{ x, y }` - the x and y coordinates of the screen location to test, provided as a point-table, like the one returned by `hs.mouse.getAbsolutePosition`.

Returns:
 * an axuielementObject for the object at the specified coordinates, or nil if no object could be identified.

Notes:
 * This method can only be called on an axuielementObject that represents an application or the system-wide element (see [hs._asm.axuielement.systemWideElement](#systemWideElement)).

 * This function does hit-testing based on window z-order (that is, layering). If one window is on top of another window, the returned accessibility object comes from whichever window is topmost at the specified location.
 * If this method is called on an axuielementObject representing an application, the search is restricted to the application.
 * If this method is called on an axuielementObject representing the system-wide element, the search is not restricted to any particular application.  See [hs._asm.axuielement.systemElementAtPosition](#systemElementAtPosition).

- - -

<a name="elementSearch"></a>
~~~lua
axuielement:elementSearch(matchCriteria, [isPattern], [includeParents]) -> table
~~~
Returns a table of axuielementObjects that match the specified criteria.  If this method is called for an axuielementObject, it will include all children of the element in its search.  If this method is called for a table of axuielementObjects, it will return the subset of the table that match the criteria.

Parameters:
 * `matchCriteria`  - the criteria to compare against the accessibility objects
 * `isPattern`      - an optional boolean, default false, specifying whether or not the strings in the search criteria should be considered as Lua patterns (true) or as absolute string matches (false).
 * `includeParents` - an optional boolean, default false, indicating that the parent of objects should be queried as well.  If you wish to specify this parameter, you *must* also specify the `isPattern` parameter.  This parameter is ignored if the method is called on a result set from a previous invocation of this method or [hs._asm.axuielement:getAllChildElements](#getAllChildElements).

Returns:
 * a table of axuielementObjects which match the specified criteria.  The table returned will include a metatable which allows calling this method on the result table for further narrowing the search.

Notes:
 * this method makes heavy use of the [hs._asm.axuielement:matches](#matches) method and pre-creates the necessary dynamic functions to optimize its search.

 * You can use this method to retrieve all of the current axuielementObjects for an application as follows:
~~~
ax = require"hs._asm.axuielement"
elements = ax.applicationElement(hs.application("Safari")):elementSearch({})
~~~
 * Note that if you started from the window of an application, only the children of that window would be returned; you could force it to gather all of the objects for the application by using `:elementSearch({}, false, true)`.
 * However, this method of querying for all elements can be slow -- it is highly recommended that you use [hs._asm.axuielement:getAllChildElements](#getAllChildElements) instead, and ideally with a callback function.
~~~
ax = require"hs._asm.axuielement"
ax.applicationElement(hs.application("Safari")):getAllChildElements(function(t)
    elements = t
    print("done with query")
end)
~~~
 * Whatever option you choose, you can use this method to narrow down the result set. This example will print the frame for each button that was present in Safari when the search occurred which has a description which starts with "min" (e.g. "minimize button") or "full" (e.g. "full screen button"):
~~~
for i, v in ipairs(elements:elementSearch({
                                    role="AXButton",
                                    roleDescription = { "^min", "^full"}
                                }, true)) do
    print(hs.inspect(v:frame()))
end
~~~

- - -

<a name="getAllChildElements"></a>
~~~lua
axuielement:getAllChildElements([parent], [callback]) -> table | axuielementObject
~~~
Query the accessibility object for all child objects (and their children...) and return them in a table.

Paramters:
 * `parent`   - an optional boolean, default false, indicating that the parent of objects should be queried as well.
 * `callback` - an optional function callback which will receive the results of the query.  If a function is provided, the query will be performed in a background thread, and this method will return immediately.

Returns:
 * If no function callback is provided, this method will return a table containing this element, and all of the children (and optionally parents) of this element.  If a function callback is provided, this method returns the axuielementObject.

Notes:
 * The table generated, either as the return value, or as the argument to the callback function, has the `hs._asm.axuielement.elementSearchTable` metatable assigned to it. See [hs._asm.axuielement:elementSearch](#elementSearch) for details on what this provides.

 * If `parent` is true, this method in effect provides all available accessibility objects for the application the object belongs to (or the focused application, if using the system-wide object).

 * If you do not provide a callback function, this method blocks Hammerspoon while it performs the query; such use is not recommended, especially if you set `parent` to true, as it can block for some time.

- - -

<a name="isAttributeSettable"></a>
~~~lua
axuielement:isAttributeSettable(attribute) -> boolean
~~~
Returns whether the specified accessibility object's attribute can be modified.

Parameters:
 * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).

Returns:
 * a boolean value indicating whether or not the value of the parameter can be modified.

- - -

<a name="matches"></a>
~~~lua
axuielement:matches(matchCriteria, [isPattern]) -> boolean
~~~
Returns true if the axuielementObject matches the specified criteria or false if it does not.

Paramters:
 * `matchCriteria` - the criteria to compare against the accessibility object
 * `isPattern`     - an optional boolean, default false, specifying whether or not the strings in the search criteria should be considered as Lua patterns (true) or as absolute string matches (false).

Returns:
 * true if the axuielementObject matches the criteria, false if it does not.

Notes:
 * if `isPattern` is specified and is true, all string comparisons are done with `string.match`.  See the Lua manual, section 6.4.1 (`help.lua._man._6_4_1` in the Hammerspoon console).
 * the `matchCriteria` must be one of the following:
   * a single string, specifying the AXRole value the axuielementObject's AXRole attribute must equal for the match to return true
   * an array of strings, specifying a list of AXRoles for which the match should return true
   * a table of key-value pairs specifying a more complex match criteria.  This table will be evaluated as follows:
     * each key-value pair is treated as a separate test and the object *must* match as true for all tests
     * each key is a string specifying an attribute to evaluate.  This attribute may be specified with its formal name (e.g. "AXRole") or the informal version (e.g. "role" or "Role").
     * each value may be a string, a number, a boolean, or an axuielementObject userdata object, or an array (table) of such.  If the value is an array, then the test will match as true if the object matches any of the supplied values for the attribute specified by the key.
       * Put another way: key-value pairs are "and'ed" together while the values for a specific key-value pair are "or'ed" together.

 * This method is used by [hs._asm.axuielement:elementSearch](#elementSearch) to determine if the given object should be included it's result set.  As an optimization for the `elementSearch` method, the keys in the `matchCriteria` table may be provided as a function which takes one argument (the axuielementObject to query).  The return value of this function will be compared against the value(s) of the key-value pair as described above.  This is done to prevent dynamically re-creating the query for each comparison when the search set is large.

- - -

<a name="parameterizedAttributeNames"></a>
~~~lua
axuielement:parameterizedAttributeNames() -> table
~~~
Returns a list of all the parameterized attributes supported by the specified accessibility object.

Parameters:
 * None

Returns:
 * an array of the names of all parameterized attributes supported by the axuielementObject

- - -

<a name="parameterizedAttributeValue"></a>
~~~lua
axuielement:parameterizedAttributeValue(attribute, parameter) -> value
~~~
Returns the value of an accessibility object's parameterized attribute.

Parameters:
 * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:parameterizedAttributeNames](#parameterizedAttributeNames).
 * `parameter` - the parameter

Returns:
 * the current value of the parameterized attribute, or nil if it has no value

Notes:
 * Parameterized attribute support is still considered experimental and not fully supported yet.  Use with caution.

- - -

<a name="performAction"></a>
~~~lua
axuielement:performAction(action) -> axuielement | false | nil
~~~
Requests that the specified accessibility object perform the specified action.

Parameters:
 * `action` - the name of the action, as specified by [hs._asm.axuielement:actionNames](#actionNames).

Returns:
 * if the requested action was accepted by the target, returns the axuielementObject; if the requested action was rejected, returns false, otherwise returns nil on error.

Notes:
 * The return value only suggests success or failure, but is not a guarantee.  The receiving application may have internal logic which prevents the action from occurring at this time for some reason, even though this method returns success (the axuielementObject).  Contrawise, the requested action may trigger a requirement for a response from the user and thus appear to time out, causing this method to return false or nil.

- - -

<a name="pid"></a>
~~~lua
axuielement:pid() -> integer
~~~
Returns the process ID associated with the specified accessibility object.

Parameters:
 * None

Returns:
 * the process ID for the application to which the accessibility object ultimately belongs.

- - -

<a name="setAttributeValue"></a>
~~~lua
axuielement:setAttributeValue(attribute, value) -> axuielementObject | nil
~~~
Sets the accessibility object's attribute to the specified value.

Parameters:
 * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).
 * `value`     - the value to assign to the attribute

Returns:
 * the axuielementObject on success; nil if the attribute could not be set.

Notes:
 * This is still somewhat experimental and needs more testing; use with caution.

### Module Constants

<a name="actions"></a>
~~~lua
axuielement.actions[]
~~~
A table of common accessibility object action names, provided for reference.

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.

- - -

<a name="attributes"></a>
~~~lua
axuielement.attributes[]
~~~
A table of common accessibility object attribute names, provided for reference. The names are grouped into the following subcategories (keys):

 * `application`
 * `dock`
 * `general`
 * `matte`
 * `menu`
 * `misc`
 * `system`
 * `table`
 * `text`
 * `window`

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.
 * the category name indicates the type of accessibility object likely to contain the member elements.

- - -

<a name="directions"></a>
~~~lua
axuielement.directions[]
~~~
A table of common directions which may be specified as the value of an accessibility object property, provided for reference.

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.

- - -

<a name="parameterizedAttributes"></a>
~~~lua
axuielement.parameterizedAttributes[]
~~~
A table of common accessibility object parameterized attribute names, provided for reference.

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.

- - -

<a name="roles"></a>
~~~lua
axuielement.roles[]
~~~
A table of common accessibility object roles, provided for reference.

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.

- - -

<a name="subroles"></a>
~~~lua
axuielement.subroles[]
~~~
A table of common accessibility object subroles, provided for reference.

Notes:
 * this table is provided for reference only and is not intended to be comprehensive.

- - -

### License

>     The MIT License (MIT)
>
> Copyright (c) 2018 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>

