#import "common.h"

static int refTable = LUA_NOREF ;

#pragma mark - Support Functions

int pushAXUIElement(lua_State *L, AXUIElementRef theElement) {
    AXUIElementRef* thePtr = lua_newuserdata(L, sizeof(AXUIElementRef)) ;
    *thePtr = CFRetain(theElement) ;
    luaL_getmetatable(L, USERDATA_TAG) ;
    lua_setmetatable(L, -2) ;
    return 1 ;
}

const char *AXErrorAsString(AXError theError) {
    const char *ans ;
    switch(theError) {
        case kAXErrorSuccess:                           ans = "No error occurred" ; break ;
        case kAXErrorFailure:                           ans = "A system error occurred" ; break ;
        case kAXErrorIllegalArgument:                   ans = "Illegal argument." ; break ;
        case kAXErrorInvalidUIElement:                  ans = "AXUIElementRef is invalid." ; break ;
        case kAXErrorInvalidUIElementObserver:          ans = "Not a valid observer." ; break ;
        case kAXErrorCannotComplete:                    ans = "Messaging failed." ; break ;
        case kAXErrorAttributeUnsupported:              ans = "Attribute is not supported by target." ; break ;
        case kAXErrorActionUnsupported:                 ans = "Action is not supported by target." ; break ;
        case kAXErrorNotificationUnsupported:           ans = "Notification is not supported by target." ; break ;
        case kAXErrorNotImplemented:                    ans = "Function or method not implemented." ; break ;
        case kAXErrorNotificationAlreadyRegistered:     ans = "Notification has already been registered." ; break ;
        case kAXErrorNotificationNotRegistered:         ans = "Notification is not registered yet." ; break ;
        case kAXErrorAPIDisabled:                       ans = "The accessibility API is disabled" ; break ;
        case kAXErrorNoValue:                           ans = "Requested value does not exist." ; break ;
        case kAXErrorParameterizedAttributeUnsupported: ans = "Parameterized attribute is not supported." ; break ;
        case kAXErrorNotEnoughPrecision:                ans = "Not enough precision." ; break ;
        default:                                        ans = "Unrecognized error occured." ; break ;
    }
    return ans ;
}

static BOOL isApplicationOrSystem(AXUIElementRef theRef) {
    BOOL result = NO ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)@"AXRole", &value) ;
    if ((errorState == kAXErrorSuccess) &&
        (CFGetTypeID(value) == CFStringGetTypeID()) &&
        ([(__bridge NSString *)value isEqualToString:(__bridge NSString *)kAXApplicationRole] ||
         [(__bridge NSString *)value isEqualToString:(__bridge NSString *)kAXSystemWideRole])) {

        result = YES ;
    }
    if (value) CFRelease(value) ;
    return result ;
}

static int errorWrapper(lua_State *L, NSString *where, NSString *what, AXError err) {
    if (what) {
        [LuaSkin logVerbose:[NSString stringWithFormat:@"%s:%@ AXError %d for %@: %s", USERDATA_TAG, where, err, what, AXErrorAsString(err)]] ;
    } else {
        [LuaSkin logVerbose:[NSString stringWithFormat:@"%s:%@ AXError %d: %s", USERDATA_TAG, where, err, AXErrorAsString(err)]] ;
    }
    lua_pushnil(L) ;
    return 1 ;
}


static void getAllAXUIElements_searchHamster(CFTypeRef theRef, BOOL includeParents, CFMutableArrayRef results) {
    CFTypeID theRefType = CFGetTypeID(theRef) ;
    if (theRefType == CFArrayGetTypeID()) {
        CFIndex theRefCount = CFArrayGetCount(theRef) ;
        for (CFIndex i = 0 ; i < theRefCount ; i++) {
            CFTypeRef value = CFArrayGetValueAtIndex(theRef, i) ;
            CFTypeID valueType = CFGetTypeID(value) ;
            if ((valueType == CFArrayGetTypeID()) || (valueType == AXUIElementGetTypeID())) {
                getAllAXUIElements_searchHamster(value, includeParents, results) ;
            }
        }
    } else if (theRefType == AXUIElementGetTypeID()) {
        if (CFArrayContainsValue(results, CFRangeMake(0, CFArrayGetCount(results)), theRef)) return ;
        CFArrayAppendValue(results, theRef) ;
        CFArrayRef attributeNames ;
        AXError errorState = AXUIElementCopyAttributeNames(theRef, &attributeNames) ;
        if (errorState == kAXErrorSuccess) {
            for (id name in (__bridge NSArray *)attributeNames) {
                if ((![name isEqualToString:(__bridge NSString *)kAXTopLevelUIElementAttribute] &&
                    ![name isEqualToString:(__bridge NSString *)kAXParentAttribute]) || includeParents) {
                    CFTypeRef value ;
                    errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)name, &value) ;
                    if (errorState == kAXErrorSuccess) {
                        CFTypeID theType = CFGetTypeID(value) ;
                        if ((theType == CFArrayGetTypeID()) || (theType == AXUIElementGetTypeID())) {
                            getAllAXUIElements_searchHamster(value, includeParents, results) ;
                        }
                    } else {
                        if (errorState != kAXErrorNoValue) {
                            [LuaSkin logVerbose:[NSString stringWithFormat:@"%s:getAllChildElements AXError %d for %@: %s", USERDATA_TAG, errorState, name, AXErrorAsString(errorState)]] ;
                        }
                    }
                    if (value) CFRelease(value) ;
                }
            }
        } else {
            [LuaSkin logVerbose:[NSString stringWithFormat:@"%s:getAllChildElements AXError %d getting attribute names: %s", USERDATA_TAG, errorState, AXErrorAsString(errorState)]] ;
        }
        if (attributeNames) CFRelease(attributeNames) ;
    } /* else {
       * ignore it, not a type we care about
    }  */
    return ;
}

#pragma mark - Module Functions

/// hs._asm.axuielement.windowElement(windowObject) -> axuielementObject
/// Constructor
/// Returns the accessibility object for the window specified by the `hs.window` object.
///
/// Parameters:
///  * `windowObject` - the `hs.window` object for the window.
///
/// Returns:
///  * an axuielementObject for the window specified
static int getWindowElement(lua_State *L)      { return pushAXUIElement(L, get_axuielementref(L, 1, "hs.window")) ; }

/// hs._asm.axuielement.applicationElement(applicationObject) -> axuielementObject
/// Constructor
/// Returns the top-level accessibility object for the application specified by the `hs.application` object.
///
/// Parameters:
///  * `applicationObject` - the `hs.application` object for the Application.
///
/// Returns:
///  * an axuielementObject for the application specified
static int getApplicationElement(lua_State *L) { return pushAXUIElement(L, get_axuielementref(L, 1, "hs.application")) ; }

/// hs._asm.axuielement.systemWideElement() -> axuielementObject
/// Constructor
/// Returns an accessibility object that provides access to system attributes.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the axuielementObject for the system attributes
static int getSystemWideElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    AXUIElementRef value = AXUIElementCreateSystemWide() ;
    pushAXUIElement(L, value) ;
    CFRelease(value) ;
    return 1 ;
}

/// hs._asm.axuielement.applicationElementForPID(pid) -> axuielementObject
/// Constructor
/// Returns the top-level accessibility object for the application with the specified process ID.
///
/// Parameters:
///  * `pid` - the process ID of the application.
///
/// Returns:
///  * an axuielementObject for the application specified, or nil if it cannot be determined
static int getApplicationElementForPID(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TNUMBER, LS_TBREAK] ;
    pid_t thePid = (pid_t)luaL_checkinteger(L, 1) ;
    AXUIElementRef value = AXUIElementCreateApplication(thePid) ;
    if (value && isApplicationOrSystem(value)) {
        pushAXUIElement(L, value) ;

    } else {
        lua_pushnil(L) ;
    }
    if (value) {
	    CFRelease(value) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.axuielement:copy() -> axuielementObject
/// Method
/// Return a duplicate userdata reference to the Accessibility object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a new userdata object representing a new reference to the Accessibility object.
///
/// Notes:
///  * The new userdata will have no search state information attached to it, and is used internally by [hs._asm.axuielement:searchPath](#searchPath).
static int duplicateReference(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    pushAXUIElement(L, theRef) ;
    return 1 ;
}

/// hs._asm.axuielement:attributeNames() -> table
/// Method
/// Returns a list of all the attributes supported by the specified accessibility object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an array of the names of all attributes supported by the axuielementObject
///
/// Notes:
///  * Common attribute names can be found in the [hs._asm.axuielement.attributes](#attributes) tables; however, this method will list only those names which are supported by this object, and is not limited to just those in the referenced table.
static int getAttributeNames(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFArrayRef attributeNames ;
    AXError errorState = AXUIElementCopyAttributeNames(theRef, &attributeNames) ;
    if (errorState == kAXErrorSuccess) {
        lua_newtable(L) ;
        for (id value in (__bridge NSArray *)attributeNames) {
            [skin pushNSObject:value] ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
    } else {
        errorWrapper(L, @"attributeNames", nil, errorState) ;
    }
    if (attributeNames) CFRelease(attributeNames) ;
    return 1 ;
}

/// hs._asm.axuielement:actionNames() -> table
/// Method
/// Returns a list of all the actions the specified accessibility object can perform.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an array of the names of all actions supported by the axuielementObject
///
/// Notes:
///  * Common action names can be found in the [hs._asm.axuielement.actions](#actions) table; however, this method will list only those names which are supported by this object, and is not limited to just those in the referenced table.
static int getActionNames(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFArrayRef attributeNames ;
    AXError errorState = AXUIElementCopyActionNames(theRef, &attributeNames) ;
    if (errorState == kAXErrorSuccess) {
        lua_newtable(L) ;
        for (id value in (__bridge NSArray *)attributeNames) {
            [skin pushNSObject:value] ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
    } else {
        errorWrapper(L, @"actionNames", nil, errorState) ;
    }
    if (attributeNames) CFRelease(attributeNames) ;
    return 1 ;
}

/// hs._asm.axuielement:actionDescription(action) -> string
/// Method
/// Returns a localized description of the specified accessibility object's action.
///
/// Parameters:
///  * `action` - the name of the action, as specified by [hs._asm.axuielement:actionNames](#actionNames).
///
/// Returns:
///  * a string containing a description of the object's action
///
/// Notes:
///  * The action descriptions are provided by the target application; as such their accuracy and usefulness rely on the target application's developers.
static int getActionDescription(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *action = [skin toNSObjectAtIndex:2] ;
    CFStringRef description ;
    AXError errorState = AXUIElementCopyActionDescription(theRef, (__bridge CFStringRef)action, &description) ;
    if (errorState == kAXErrorSuccess) {
        [skin pushNSObject:(__bridge NSString *)description] ;
    } else if (errorState == kAXErrorNoValue) {
        lua_pushnil(L) ;
    } else {
        errorWrapper(L, @"actionDescription", action, errorState) ;
    }
    if (description) CFRelease(description) ;
    return 1 ;
}

/// hs._asm.axuielement:attributeValue(attribute) -> value
/// Method
/// Returns the value of an accessibility object's attribute.
///
/// Parameters:
///  * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).
///
/// Returns:
///  * the current value of the attribute, or nil if the attribute has no value
static int getAttributeValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *attribute = [skin toNSObjectAtIndex:2] ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)attribute, &value) ;
    if (errorState == kAXErrorSuccess) {
        pushCFTypeToLua(L, value, refTable) ;
    } else if (errorState == kAXErrorNoValue) {
        lua_pushnil(L) ;
    } else {
        errorWrapper(L, @"attributeValue", attribute, errorState) ;
    }
    if (value) CFRelease(value) ;
    return 1 ;
}

/// hs._asm.axuielement:allAttributeValues([includeErrors]) -> table
/// Method
/// Returns a table containing key-value pairs for all attributes of the accessibility object.
///
/// Parameters:
///  * `includeErrors` - an optional boolean, default false, that specifies whether attribute names which generate an error when retrieved are included in the returned results.
///
/// Returns:
///  * a table with key-value pairs corresponding to the attributes of the accessibility object.
static int getAllAttributeValues(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    BOOL includeErrors = lua_gettop(L) == 2 ? (BOOL)lua_toboolean(L, 2) : NO ;
    CFArrayRef attributeNames ;
    AXError errorState = AXUIElementCopyAttributeNames(theRef, &attributeNames) ;
    if (errorState == kAXErrorSuccess) {
        CFArrayRef values = nil ;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        errorState = AXUIElementCopyMultipleAttributeValues(theRef, attributeNames, 0, &values) ;
#pragma clang diagnostic pop
        if (errorState == kAXErrorSuccess) {
            lua_newtable(L) ;
            for(CFIndex idx = 0 ; idx < CFArrayGetCount(attributeNames) ; idx++) {
                CFTypeRef item = CFArrayGetValueAtIndex(values, idx) ;
                if ((CFGetTypeID(item) == AXValueGetTypeID()) && (AXValueGetType((AXValueRef)item) == kAXValueAXErrorType)) {
                    if (!includeErrors) continue ;
                }
                pushCFTypeToLua(L, item, refTable) ;
                lua_setfield(L, -2, [(__bridge NSString *)CFArrayGetValueAtIndex(attributeNames, idx) UTF8String]) ;
            }
        } else {
            errorWrapper(L, @"allAttributeValues", @"retrieving attribute values", errorState) ;
        }
        if (values) CFRelease(values) ;
    } else {
        errorWrapper(L, @"allAttributeValues", @"retrieving attribute names", errorState) ;
    }
    if (attributeNames) CFRelease(attributeNames) ;
    return 1 ;
}

/// hs._asm.axuielement:attributeValueCount(attribute) -> integer
/// Method
/// Returns the count of the array of an accessibility object's attribute value.
///
/// Parameters:
///  * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).
///
/// Returns:
///  * the number of items in the value for the attribute, if it is an array, or nil if the value is not an array.
static int getAttributeValueCount(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *attribute = [skin toNSObjectAtIndex:2] ;
    CFIndex count ;
    AXError errorState = AXUIElementGetAttributeValueCount(theRef, (__bridge CFStringRef)attribute, &count) ;
    if (errorState == kAXErrorSuccess) {
        lua_pushinteger(L, count) ;
    } else {
        errorWrapper(L, @"attributeValueCount", attribute, errorState) ;
    }
    return 1 ;
}

/// hs._asm.axuielement:parameterizedAttributeNames() -> table
/// Method
/// Returns a list of all the parameterized attributes supported by the specified accessibility object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an array of the names of all parameterized attributes supported by the axuielementObject
static int getParameterizedAttributeNames(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFArrayRef attributeNames ;
    AXError errorState = AXUIElementCopyParameterizedAttributeNames(theRef, &attributeNames) ;
    if (errorState == kAXErrorSuccess) {
        lua_newtable(L) ;
        for (id value in (__bridge NSArray *)attributeNames) {
            [skin pushNSObject:value] ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
    } else {
        errorWrapper(L, @"parameterizedAttributeNames", nil, errorState) ;
    }
    if (attributeNames) CFRelease(attributeNames) ;
    return 1 ;
}

/// hs._asm.axuielement:isAttributeSettable(attribute) -> boolean
/// Method
/// Returns whether the specified accessibility object's attribute can be modified.
///
/// Parameters:
///  * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).
///
/// Returns:
///  * a boolean value indicating whether or not the value of the parameter can be modified.
static int isAttributeSettable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *attribute = [skin toNSObjectAtIndex:2] ;
    Boolean settable ;
    AXError errorState = AXUIElementIsAttributeSettable(theRef, (__bridge CFStringRef)attribute, &settable) ;
    if (errorState == kAXErrorSuccess) {
        lua_pushboolean(L, settable) ;
    } else {
        errorWrapper(L, @"isAttributeSettable", attribute, errorState) ;
    }
    return 1 ;
}

/// hs._asm.axuielement:pid() -> integer
/// Method
/// Returns the process ID associated with the specified accessibility object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the process ID for the application to which the accessibility object ultimately belongs.
static int getPid(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    pid_t thePid ;
    AXError errorState = AXUIElementGetPid(theRef, &thePid) ;
    if (errorState == kAXErrorSuccess) {
        lua_pushinteger(L, (lua_Integer)thePid) ;
    } else {
        errorWrapper(L, @"pid", nil, errorState) ;
    }
    return 1 ;
}

/// hs._asm.axuielement:performAction(action) -> axuielement | false | nil
/// Method
/// Requests that the specified accessibility object perform the specified action.
///
/// Parameters:
///  * `action` - the name of the action, as specified by [hs._asm.axuielement:actionNames](#actionNames).
///
/// Returns:
///  * if the requested action was accepted by the target, returns the axuielementObject; if the requested action was rejected, returns false, otherwise returns nil on error.
///
/// Notes:
///  * The return value only suggests success or failure, but is not a guarantee.  The receiving application may have internal logic which prevents the action from occurring at this time for some reason, even though this method returns success (the axuielementObject).  Contrawise, the requested action may trigger a requirement for a response from the user and thus appear to time out, causing this method to return false or nil.
static int performAction(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *action = [skin toNSObjectAtIndex:2] ;
    AXError errorState = AXUIElementPerformAction(theRef, (__bridge CFStringRef)action) ;
    if (errorState == kAXErrorSuccess) {
        lua_pushvalue(L, 1) ;
    } else if (errorState == kAXErrorCannotComplete) {
        lua_pushboolean(L, NO) ;
    } else {
        errorWrapper(L, @"performAction", action, errorState) ;
    }
    return 1 ;
}

/// hs._asm.axuielement:elementAtPosition(x, y | { x, y }) -> axuielementObject
/// Method
/// Returns the accessibility object at the specified position in top-left relative screen coordinates.
///
/// Parameters:
///  * `x`, `y`   - the x and y coordinates of the screen location to test, provided as separate parameters
///  * `{ x, y }` - the x and y coordinates of the screen location to test, provided as a point-table, like the one returned by `hs.mouse.getAbsolutePosition`.
///
/// Returns:
///  * an axuielementObject for the object at the specified coordinates, or nil if no object could be identified.
///
/// Notes:
///  * This method can only be called on an axuielementObject that represents an application or the system-wide element (see [hs._asm.axuielement.systemWideElement](#systemWideElement)).
///
///  * This function does hit-testing based on window z-order (that is, layering). If one window is on top of another window, the returned accessibility object comes from whichever window is topmost at the specified location.
///  * If this method is called on an axuielementObject representing an application, the search is restricted to the application.
///  * If this method is called on an axuielementObject representing the system-wide element, the search is not restricted to any particular application.  See [hs._asm.axuielement.systemElementAtPosition](#systemElementAtPosition).
static int getElementAtPosition(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TTABLE, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    if (isApplicationOrSystem(theRef)) {
        float x, y ;
        if (lua_type(L, 2) == LUA_TTABLE && lua_gettop(L) == 2) {
            NSPoint thePoint = [skin tableToPointAtIndex:2] ;
            x = (float)thePoint.x ;
            y = (float)thePoint.y ;
        } else if (lua_gettop(L) == 3) {
            x = (float)lua_tonumber(L, 2) ;
            y = (float)lua_tonumber(L, 3) ;
        } else {
            return luaL_error(L, "point table or x and y as numbers expected") ;
        }
        AXUIElementRef value ;
        AXError errorState = AXUIElementCopyElementAtPosition(theRef, x, y, &value) ;
        if (errorState == kAXErrorSuccess) {
            pushAXUIElement(L, value) ;
        } else {
            errorWrapper(L, @"elementAtPosition", nil, errorState) ;
        }
        if (value) CFRelease(value) ;
    } else {
        return luaL_error(L, "must be application or systemWide element") ;
    }
    return 1 ;
}

/// hs._asm.axuielement:parameterizedAttributeValue(attribute, parameter) -> value
/// Method
/// Returns the value of an accessibility object's parameterized attribute.
///
/// Parameters:
///  * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:parameterizedAttributeNames](#parameterizedAttributeNames).
///  * `parameter` - the parameter
///
/// Returns:
///  * the current value of the parameterized attribute, or nil if it has no value
///
/// Notes:
///  * Parameterized attribute support is still considered experimental and not fully supported yet.  Use with caution.
static int getParameterizedAttributeValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TANY, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *attribute = [skin toNSObjectAtIndex:2] ;
    CFTypeRef parameter = lua_toCFType(L, 3) ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyParameterizedAttributeValue(theRef, (__bridge CFStringRef)attribute, parameter, &value) ;
    if (errorState == kAXErrorSuccess) {
        pushCFTypeToLua(L, value, refTable) ;
    } else if (errorState == kAXErrorNoValue) {
        lua_pushnil(L) ;
    } else {
        errorWrapper(L, @"parameterizedAttributeValue", attribute, errorState) ;
    }
    if (value) CFRelease(value) ;
    if (parameter) CFRelease(parameter) ;
    return 1 ;
}

/// hs._asm.axuielement:setAttributeValue(attribute, value) -> axuielementObject | nil
/// Method
/// Sets the accessibility object's attribute to the specified value.
///
/// Parameters:
///  * `attribute` - the name of the attribute, as specified by [hs._asm.axuielement:attributeNames](#attributeNames).
///  * `value`     - the value to assign to the attribute
///
/// Returns:
///  * the axuielementObject on success; nil if the attribute could not be set.
///
/// Notes:
///  * This is still somewhat experimental and needs more testing; use with caution.
static int setAttributeValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TANY, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    NSString *attribute = [skin toNSObjectAtIndex:2] ;
    CFTypeRef value = lua_toCFType(L, 3) ;
    AXError errorState = AXUIElementSetAttributeValue (theRef, (__bridge CFStringRef)attribute, value) ;
    if (errorState == kAXErrorSuccess) {
        lua_pushvalue(L, 1) ;
    } else {
        errorWrapper(L, @"setAttributeValue", attribute, errorState) ;
    }
    if (value) CFRelease(value) ;
    return 1 ;
}

/// hs._asm.axuielement:getAllChildElements([parent], [callback]) -> table | axuielementObject
/// Method
/// Query the accessibility object for all child objects (and their children...) and return them in a table.
///
/// Paramters:
///  * `parent`   - an optional boolean, default false, indicating that the parent of objects should be queried as well.
///  * `callback` - an optional function callback which will receive the results of the query.  If a function is provided, the query will be performed in a background thread, and this method will return immediately.
///
/// Returns:
///  * If no function callback is provided, this method will return a table containing this element, and all of the children (and optionally parents) of this element.  If a function callback is provided, this method returns the axuielementObject.
///
/// Notes:
///  * The table generated, either as the return value, or as the argument to the callback function, has the `hs._asm.axuielement.elementSearchTable` metatable assigned to it. See [hs._asm.axuielement:elementSearch](#elementSearch) for details on what this provides.
///
///  * If `parent` is true, this method in effect provides all available accessibility objects for the application the object belongs to (or the focused application, if using the system-wide object).
///
///  * If you do not provide a callback function, this method blocks Hammerspoon while it performs the query; such use is not recommended, especially if you set `parent` to true, as it can block for some time.
static int getAllAXUIElements(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    switch (lua_gettop(L)) {
        case 1:  [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ; break ;
        case 2:  [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TFUNCTION, LS_TBREAK] ; break ;
        default: [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN, LS_TFUNCTION, LS_TBREAK] ; break ;
    }
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    BOOL includeParents = NO ;
    BOOL usesCallback   = NO ;
    if (lua_type(L, 2) == LUA_TBOOLEAN) includeParents = (BOOL)lua_toboolean(L, 2) ;
    if (lua_type(L, lua_gettop(L)) == LUA_TFUNCTION) usesCallback = YES ;

    CFMutableArrayRef results = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks) ;
    if (usesCallback) {
        lua_pushvalue(L, lua_gettop(L)) ;
        int callbackRef = [skin luaRef:refTable] ;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            getAllAXUIElements_searchHamster(theRef, includeParents, results) ;
            dispatch_async(dispatch_get_main_queue(), ^{
                [skin pushLuaRef:refTable ref:callbackRef] ;
                CFIndex arraySize = CFArrayGetCount(results) ;
                lua_newtable(L) ;
                for (CFIndex i = 0 ; i < arraySize ; i++) {
                    pushAXUIElement(L, CFArrayGetValueAtIndex(results, i)) ;
                    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
                }
                luaL_getmetatable(L, USERDATA_TAG ".elementSearchTable") ;
                lua_setmetatable(L, -2) ;
                CFRelease(results) ;
                if (![skin protectedCallAndTraceback:1 nresults:0]) {
                    [skin logError:[NSString stringWithFormat:@"%s:callback error:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
                    lua_pop(L, 1) ;
                }
                [skin luaUnref:refTable ref:callbackRef] ;
            });
        });
        lua_pushvalue(L, 1) ;
    } else {
        getAllAXUIElements_searchHamster(theRef, includeParents, results) ;
        CFIndex arraySize = CFArrayGetCount(results) ;
        lua_newtable(L) ;
        for (CFIndex i = 0 ; i < arraySize ; i++) {
            pushAXUIElement(L, CFArrayGetValueAtIndex(results, i)) ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
        luaL_getmetatable(L, USERDATA_TAG ".elementSearchTable") ;
        lua_setmetatable(L, -2) ;
        CFRelease(results) ;
    }
    return 1 ;
}

/// hs._asm.axuielement:asHSApplication() -> hs.application object | nil
/// Method
/// If the element referes to an application, return an `hs.application` object for the element.
///
/// Parameters:
///  * None
///
/// Returns:
///  * if the element refers to an application, return an `hs.application` object for the element ; otherwise return nil
///
/// Notes:
///  * An element is considered an application by this method if it has an AXRole of AXApplication and has a process identifier (pid).
static int axuielementToApplication(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)@"AXRole", &value) ;
    if ((errorState == kAXErrorSuccess) &&
        (CFGetTypeID(value) == CFStringGetTypeID()) &&
        ([(__bridge NSString *)value isEqualToString:(__bridge NSString *)kAXApplicationRole])) {
        pid_t thePid ;
        AXError errorState2 = AXUIElementGetPid(theRef, &thePid) ;
        if (errorState2 == kAXErrorSuccess) {
            if (!new_application(L, thePid)) lua_pushnil(L) ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        lua_pushnil(L) ;
    }
    if (value) CFRelease(value) ;
    return 1 ;
}

/// hs._asm.axuielement:asHSWindow() -> hs.window object | nil
/// Method
/// If the element referes to a window, return an `hs.window` object for the element.
///
/// Parameters:
///  * None
///
/// Returns:
///  * if the element refers to a window, return an `hs.window` object for the element ; otherwise return nil
///
/// Notes:
///  * An element is considered a window by this method if it has an AXRole of AXWindow.
static int axuielementToWindow(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)@"AXRole", &value) ;
    if ((errorState == kAXErrorSuccess) &&
        (CFGetTypeID(value) == CFStringGetTypeID()) &&
        ([(__bridge NSString *)value isEqualToString:(__bridge NSString *)kAXWindowRole])) {
        new_window(L, CFRetain(theRef)) ;
    } else {
        lua_pushnil(L) ;
    }
    if (value) CFRelease(value) ;

    return 1 ;
}

static int axuielement_setTimeout(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER, LS_TBREAK] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    AXError errorState = AXUIElementSetMessagingTimeout(theRef, (float)lua_tonumber(L, 2)) ;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
    switch (errorState) {
        case kAXErrorSuccess:
            lua_pushvalue(L, 1) ;
            break ;
        case kAXErrorIllegalArgument:
            return luaL_argerror(L, 2, "timeout must be zero or positive") ;
        case kAXErrorInvalidUIElement:
            return luaL_argerror(L, 1, "axuielement object is not valid") ;
        default:
            return luaL_error(L, "unexpected error:%s", AXErrorAsString(errorState)) ;
    }
#pragma clang diagnostic pop
    return 1 ;
}

#pragma mark - Module Constants

/// hs._asm.axuielement.roles[]
/// Constant
/// A table of common accessibility object roles, provided for reference.
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
static int pushRolesTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXApplicationRole] ;        lua_setfield(L, -2, "application") ;
    [skin pushNSObject:(__bridge NSString *)kAXSystemWideRole] ;         lua_setfield(L, -2, "systemWide") ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowRole] ;             lua_setfield(L, -2, "window") ;
    [skin pushNSObject:(__bridge NSString *)kAXSheetRole] ;              lua_setfield(L, -2, "sheet") ;
    [skin pushNSObject:(__bridge NSString *)kAXDrawerRole] ;             lua_setfield(L, -2, "drawer") ;
    [skin pushNSObject:(__bridge NSString *)kAXGrowAreaRole] ;           lua_setfield(L, -2, "growArea") ;
    [skin pushNSObject:(__bridge NSString *)kAXImageRole] ;              lua_setfield(L, -2, "image") ;
    [skin pushNSObject:(__bridge NSString *)kAXUnknownRole] ;            lua_setfield(L, -2, "unknown") ;
    [skin pushNSObject:(__bridge NSString *)kAXButtonRole] ;             lua_setfield(L, -2, "button") ;
    [skin pushNSObject:(__bridge NSString *)kAXRadioButtonRole] ;        lua_setfield(L, -2, "radioButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXCheckBoxRole] ;           lua_setfield(L, -2, "checkBox") ;
    [skin pushNSObject:(__bridge NSString *)kAXPopUpButtonRole] ;        lua_setfield(L, -2, "popUpButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuButtonRole] ;         lua_setfield(L, -2, "menuButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXTabGroupRole] ;           lua_setfield(L, -2, "tabGroup") ;
    [skin pushNSObject:(__bridge NSString *)kAXTableRole] ;              lua_setfield(L, -2, "table") ;
    [skin pushNSObject:(__bridge NSString *)kAXColumnRole] ;             lua_setfield(L, -2, "column") ;
    [skin pushNSObject:(__bridge NSString *)kAXRowRole] ;                lua_setfield(L, -2, "row") ;
    [skin pushNSObject:(__bridge NSString *)kAXOutlineRole] ;            lua_setfield(L, -2, "outline") ;
    [skin pushNSObject:(__bridge NSString *)kAXBrowserRole] ;            lua_setfield(L, -2, "browser") ;
    [skin pushNSObject:(__bridge NSString *)kAXScrollAreaRole] ;         lua_setfield(L, -2, "scrollArea") ;
    [skin pushNSObject:(__bridge NSString *)kAXScrollBarRole] ;          lua_setfield(L, -2, "scrollBar") ;
    [skin pushNSObject:(__bridge NSString *)kAXRadioGroupRole] ;         lua_setfield(L, -2, "radioGroup") ;
    [skin pushNSObject:(__bridge NSString *)kAXListRole] ;               lua_setfield(L, -2, "list") ;
    [skin pushNSObject:(__bridge NSString *)kAXGroupRole] ;              lua_setfield(L, -2, "group") ;
    [skin pushNSObject:(__bridge NSString *)kAXValueIndicatorRole] ;     lua_setfield(L, -2, "valueIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXComboBoxRole] ;           lua_setfield(L, -2, "comboBox") ;
    [skin pushNSObject:(__bridge NSString *)kAXSliderRole] ;             lua_setfield(L, -2, "slider") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementorRole] ;        lua_setfield(L, -2, "incrementor") ;
    [skin pushNSObject:(__bridge NSString *)kAXBusyIndicatorRole] ;      lua_setfield(L, -2, "busyIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXProgressIndicatorRole] ;  lua_setfield(L, -2, "progressIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXRelevanceIndicatorRole] ; lua_setfield(L, -2, "relevanceIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXToolbarRole] ;            lua_setfield(L, -2, "toolbar") ;
    [skin pushNSObject:(__bridge NSString *)kAXDisclosureTriangleRole] ; lua_setfield(L, -2, "disclosureTriangle") ;
    [skin pushNSObject:(__bridge NSString *)kAXTextFieldRole] ;          lua_setfield(L, -2, "textField") ;
    [skin pushNSObject:(__bridge NSString *)kAXTextAreaRole] ;           lua_setfield(L, -2, "textArea") ;
    [skin pushNSObject:(__bridge NSString *)kAXStaticTextRole] ;         lua_setfield(L, -2, "staticText") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuBarRole] ;            lua_setfield(L, -2, "menuBar") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuBarItemRole] ;        lua_setfield(L, -2, "menuBarItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuRole] ;               lua_setfield(L, -2, "menu") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemRole] ;           lua_setfield(L, -2, "menuItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXSplitGroupRole] ;         lua_setfield(L, -2, "splitGroup") ;
    [skin pushNSObject:(__bridge NSString *)kAXSplitterRole] ;           lua_setfield(L, -2, "splitter") ;
    [skin pushNSObject:(__bridge NSString *)kAXColorWellRole] ;          lua_setfield(L, -2, "colorWell") ;
    [skin pushNSObject:(__bridge NSString *)kAXTimeFieldRole] ;          lua_setfield(L, -2, "timeField") ;
    [skin pushNSObject:(__bridge NSString *)kAXDateFieldRole] ;          lua_setfield(L, -2, "dateField") ;
    [skin pushNSObject:(__bridge NSString *)kAXHelpTagRole] ;            lua_setfield(L, -2, "helpTag") ;
    [skin pushNSObject:(__bridge NSString *)kAXMatteRole] ;              lua_setfield(L, -2, "matteRole") ;
    [skin pushNSObject:(__bridge NSString *)kAXDockItemRole] ;           lua_setfield(L, -2, "dockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXCellRole] ;               lua_setfield(L, -2, "cell") ;
    [skin pushNSObject:(__bridge NSString *)kAXGridRole] ;               lua_setfield(L, -2, "grid") ;
    [skin pushNSObject:(__bridge NSString *)kAXHandleRole] ;             lua_setfield(L, -2, "handle") ;
    [skin pushNSObject:(__bridge NSString *)kAXLayoutAreaRole] ;         lua_setfield(L, -2, "layoutArea") ;
    [skin pushNSObject:(__bridge NSString *)kAXLayoutItemRole] ;         lua_setfield(L, -2, "layoutItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXLevelIndicatorRole] ;     lua_setfield(L, -2, "levelIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXPopoverRole] ;            lua_setfield(L, -2, "popover") ;
    [skin pushNSObject:(__bridge NSString *)kAXRulerMarkerRole] ;        lua_setfield(L, -2, "rulerMarker") ;
    [skin pushNSObject:(__bridge NSString *)kAXRulerRole] ;              lua_setfield(L, -2, "ruler") ;
    return 1 ;
}

/// hs._asm.axuielement.subroles[]
/// Constant
/// A table of common accessibility object subroles, provided for reference.
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
static int pushSubrolesTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXCloseButtonSubrole] ;             lua_setfield(L, -2, "closeButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinimizeButtonSubrole] ;          lua_setfield(L, -2, "minimizeButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXZoomButtonSubrole] ;              lua_setfield(L, -2, "zoomButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXToolbarButtonSubrole] ;           lua_setfield(L, -2, "toolbarButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXSecureTextFieldSubrole] ;         lua_setfield(L, -2, "secureTextField") ;
    [skin pushNSObject:(__bridge NSString *)kAXTableRowSubrole] ;                lua_setfield(L, -2, "tableRow") ;
    [skin pushNSObject:(__bridge NSString *)kAXOutlineRowSubrole] ;              lua_setfield(L, -2, "outlineRow") ;
    [skin pushNSObject:(__bridge NSString *)kAXUnknownSubrole] ;                 lua_setfield(L, -2, "unknown") ;
    [skin pushNSObject:(__bridge NSString *)kAXStandardWindowSubrole] ;          lua_setfield(L, -2, "standardWindow") ;
    [skin pushNSObject:(__bridge NSString *)kAXDialogSubrole] ;                  lua_setfield(L, -2, "dialog") ;
    [skin pushNSObject:(__bridge NSString *)kAXSystemDialogSubrole] ;            lua_setfield(L, -2, "systemDialog") ;
    [skin pushNSObject:(__bridge NSString *)kAXFloatingWindowSubrole] ;          lua_setfield(L, -2, "floatingWindow") ;
    [skin pushNSObject:(__bridge NSString *)kAXSystemFloatingWindowSubrole] ;    lua_setfield(L, -2, "systemFloatingWindow") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementArrowSubrole] ;          lua_setfield(L, -2, "incrementArrow") ;
    [skin pushNSObject:(__bridge NSString *)kAXDecrementArrowSubrole] ;          lua_setfield(L, -2, "decrementArrow") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementPageSubrole] ;           lua_setfield(L, -2, "incrementPage") ;
    [skin pushNSObject:(__bridge NSString *)kAXDecrementPageSubrole] ;           lua_setfield(L, -2, "decrementPage") ;
    [skin pushNSObject:(__bridge NSString *)kAXSortButtonSubrole] ;              lua_setfield(L, -2, "sortButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXSearchFieldSubrole] ;             lua_setfield(L, -2, "searchField") ;
    [skin pushNSObject:(__bridge NSString *)kAXApplicationDockItemSubrole] ;     lua_setfield(L, -2, "applicationDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXDocumentDockItemSubrole] ;        lua_setfield(L, -2, "documentDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXFolderDockItemSubrole] ;          lua_setfield(L, -2, "folderDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinimizedWindowDockItemSubrole] ; lua_setfield(L, -2, "minimizedWindowDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXURLDockItemSubrole] ;             lua_setfield(L, -2, "URLDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXDockExtraDockItemSubrole] ;       lua_setfield(L, -2, "dockExtraDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXTrashDockItemSubrole] ;           lua_setfield(L, -2, "trashDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXProcessSwitcherListSubrole] ;     lua_setfield(L, -2, "processSwitcherList") ;
    [skin pushNSObject:(__bridge NSString *)kAXContentListSubrole] ;             lua_setfield(L, -2, "contentList") ;
    [skin pushNSObject:(__bridge NSString *)kAXDescriptionListSubrole] ;         lua_setfield(L, -2, "descriptionList") ;
    [skin pushNSObject:(__bridge NSString *)kAXFullScreenButtonSubrole] ;        lua_setfield(L, -2, "fullScreenButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXRatingIndicatorSubrole] ;         lua_setfield(L, -2, "ratingIndicator") ;
    [skin pushNSObject:(__bridge NSString *)kAXSeparatorDockItemSubrole] ;       lua_setfield(L, -2, "separatorDockItem") ;
    [skin pushNSObject:(__bridge NSString *)kAXSwitchSubrole] ;                  lua_setfield(L, -2, "switch") ;
    [skin pushNSObject:(__bridge NSString *)kAXTimelineSubrole] ;                lua_setfield(L, -2, "timeline") ;
    [skin pushNSObject:(__bridge NSString *)kAXToggleSubrole] ;                  lua_setfield(L, -2, "toggle") ;
    return 1 ;
}

/// hs._asm.axuielement.attributes[]
/// Constant
/// A table of common accessibility object attribute names, provided for reference. The names are grouped into the following subcategories (keys):
///
///  * `application`
///  * `dock`
///  * `general`
///  * `matte`
///  * `menu`
///  * `misc`
///  * `system`
///  * `table`
///  * `text`
///  * `window`
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
///  * the category name indicates the type of accessibility object likely to contain the member elements.
static int pushAttributesTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
//General attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXRoleAttribute] ;              lua_setfield(L, -2, "role") ;
    [skin pushNSObject:(__bridge NSString *)kAXSubroleAttribute] ;           lua_setfield(L, -2, "subrole") ;
    [skin pushNSObject:(__bridge NSString *)kAXRoleDescriptionAttribute] ;   lua_setfield(L, -2, "roleDescription") ;
    [skin pushNSObject:(__bridge NSString *)kAXHelpAttribute] ;              lua_setfield(L, -2, "help") ;
    [skin pushNSObject:(__bridge NSString *)kAXTitleAttribute] ;             lua_setfield(L, -2, "title") ;
    [skin pushNSObject:(__bridge NSString *)kAXValueAttribute] ;             lua_setfield(L, -2, "value") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinValueAttribute] ;          lua_setfield(L, -2, "minValue") ;
    [skin pushNSObject:(__bridge NSString *)kAXMaxValueAttribute] ;          lua_setfield(L, -2, "maxValue") ;
    [skin pushNSObject:(__bridge NSString *)kAXValueIncrementAttribute] ;    lua_setfield(L, -2, "valueIncrement") ;
    [skin pushNSObject:(__bridge NSString *)kAXAllowedValuesAttribute] ;     lua_setfield(L, -2, "allowedValues") ;
    [skin pushNSObject:(__bridge NSString *)kAXEnabledAttribute] ;           lua_setfield(L, -2, "enabled") ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedAttribute] ;           lua_setfield(L, -2, "focused") ;
    [skin pushNSObject:(__bridge NSString *)kAXParentAttribute] ;            lua_setfield(L, -2, "parent") ;
    [skin pushNSObject:(__bridge NSString *)kAXChildrenAttribute] ;          lua_setfield(L, -2, "children") ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedChildrenAttribute] ;  lua_setfield(L, -2, "selectedChildren") ;
    [skin pushNSObject:(__bridge NSString *)kAXVisibleChildrenAttribute] ;   lua_setfield(L, -2, "visibleChildren") ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowAttribute] ;            lua_setfield(L, -2, "window") ;
    [skin pushNSObject:(__bridge NSString *)kAXTopLevelUIElementAttribute] ; lua_setfield(L, -2, "topLevelUIElement") ;
    [skin pushNSObject:(__bridge NSString *)kAXPositionAttribute] ;          lua_setfield(L, -2, "position") ;
    [skin pushNSObject:(__bridge NSString *)kAXSizeAttribute] ;              lua_setfield(L, -2, "size") ;
    [skin pushNSObject:(__bridge NSString *)kAXOrientationAttribute] ;       lua_setfield(L, -2, "orientation") ;
    [skin pushNSObject:(__bridge NSString *)kAXDescriptionAttribute] ;       lua_setfield(L, -2, "description") ;
    lua_setfield(L, -2, "general") ;
// Text-specific attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedTextAttribute] ;          lua_setfield(L, -2, "selectedText") ;
    [skin pushNSObject:(__bridge NSString *)kAXVisibleCharacterRangeAttribute] ; lua_setfield(L, -2, "visibleCharacterRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedTextRangeAttribute] ;     lua_setfield(L, -2, "selectedTextRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXNumberOfCharactersAttribute] ;    lua_setfield(L, -2, "numberOfCharacters") ;
    [skin pushNSObject:(__bridge NSString *)kAXSharedTextUIElementsAttribute] ;  lua_setfield(L, -2, "sharedTextUIElements") ;
    [skin pushNSObject:(__bridge NSString *)kAXSharedCharacterRangeAttribute] ;  lua_setfield(L, -2, "sharedCharacterRange") ;
    lua_setfield(L, -2, "text") ;
// Window-specific attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXMainAttribute] ;           lua_setfield(L, -2, "main") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinimizedAttribute] ;      lua_setfield(L, -2, "minimized") ;
    [skin pushNSObject:(__bridge NSString *)kAXCloseButtonAttribute] ;    lua_setfield(L, -2, "closeButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXZoomButtonAttribute] ;     lua_setfield(L, -2, "zoomButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinimizeButtonAttribute] ; lua_setfield(L, -2, "minimizeButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXToolbarButtonAttribute] ;  lua_setfield(L, -2, "toolbarButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXGrowAreaAttribute] ;       lua_setfield(L, -2, "growArea") ;
    [skin pushNSObject:(__bridge NSString *)kAXProxyAttribute] ;          lua_setfield(L, -2, "proxy") ;
    [skin pushNSObject:(__bridge NSString *)kAXModalAttribute] ;          lua_setfield(L, -2, "modal") ;
    [skin pushNSObject:(__bridge NSString *)kAXDefaultButtonAttribute] ;  lua_setfield(L, -2, "defaultButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXCancelButtonAttribute] ;   lua_setfield(L, -2, "cancelButton") ;
    lua_setfield(L, -2, "window") ;
// Menu-specific attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemCmdCharAttribute] ;          lua_setfield(L, -2, "menuItemCmdChar") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemCmdVirtualKeyAttribute] ;    lua_setfield(L, -2, "menuItemCmdVirtualKey") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemCmdGlyphAttribute] ;         lua_setfield(L, -2, "menuItemCmdGlyph") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemCmdModifiersAttribute] ;     lua_setfield(L, -2, "menuItemCmdModifiers") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemMarkCharAttribute] ;         lua_setfield(L, -2, "menuItemMarkChar") ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemPrimaryUIElementAttribute] ; lua_setfield(L, -2, "menuItemPrimaryUIElement") ;
    lua_setfield(L, -2, "menu") ;
// Application-specific attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuBarAttribute] ;          lua_setfield(L, -2, "menuBar") ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowsAttribute] ;          lua_setfield(L, -2, "windows") ;
    [skin pushNSObject:(__bridge NSString *)kAXFrontmostAttribute] ;        lua_setfield(L, -2, "frontmost") ;
    [skin pushNSObject:(__bridge NSString *)kAXHiddenAttribute] ;           lua_setfield(L, -2, "hidden") ;
    [skin pushNSObject:(__bridge NSString *)kAXMainWindowAttribute] ;       lua_setfield(L, -2, "mainWindow") ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedWindowAttribute] ;    lua_setfield(L, -2, "focusedWindow") ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedUIElementAttribute] ; lua_setfield(L, -2, "focusedUIElement") ;
    lua_setfield(L, -2, "application") ;
// Miscellaneous attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXHeaderAttribute] ;                     lua_setfield(L, -2, "header") ;
    [skin pushNSObject:(__bridge NSString *)kAXEditedAttribute] ;                     lua_setfield(L, -2, "edited") ;
    [skin pushNSObject:(__bridge NSString *)kAXValueWrapsAttribute] ;                 lua_setfield(L, -2, "valueWraps") ;
    [skin pushNSObject:(__bridge NSString *)kAXTabsAttribute] ;                       lua_setfield(L, -2, "tabs") ;
    [skin pushNSObject:(__bridge NSString *)kAXTitleUIElementAttribute] ;             lua_setfield(L, -2, "titleUIElement") ;
    [skin pushNSObject:(__bridge NSString *)kAXHorizontalScrollBarAttribute] ;        lua_setfield(L, -2, "horizontalScrollBar") ;
    [skin pushNSObject:(__bridge NSString *)kAXVerticalScrollBarAttribute] ;          lua_setfield(L, -2, "verticalScrollBar") ;
    [skin pushNSObject:(__bridge NSString *)kAXOverflowButtonAttribute] ;             lua_setfield(L, -2, "overflowButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXFilenameAttribute] ;                   lua_setfield(L, -2, "filename") ;
    [skin pushNSObject:(__bridge NSString *)kAXExpandedAttribute] ;                   lua_setfield(L, -2, "expanded") ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedAttribute] ;                   lua_setfield(L, -2, "selected") ;
    [skin pushNSObject:(__bridge NSString *)kAXSplittersAttribute] ;                  lua_setfield(L, -2, "splitters") ;
    [skin pushNSObject:(__bridge NSString *)kAXNextContentsAttribute] ;               lua_setfield(L, -2, "nextContents") ;
    [skin pushNSObject:(__bridge NSString *)kAXDocumentAttribute] ;                   lua_setfield(L, -2, "document") ;
    [skin pushNSObject:(__bridge NSString *)kAXDecrementButtonAttribute] ;            lua_setfield(L, -2, "decrementButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementButtonAttribute] ;            lua_setfield(L, -2, "incrementButton") ;
    [skin pushNSObject:(__bridge NSString *)kAXPreviousContentsAttribute] ;           lua_setfield(L, -2, "previousContents") ;
    [skin pushNSObject:(__bridge NSString *)kAXContentsAttribute] ;                   lua_setfield(L, -2, "contents") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementorAttribute] ;                lua_setfield(L, -2, "incrementor") ;
    [skin pushNSObject:(__bridge NSString *)kAXHourFieldAttribute] ;                  lua_setfield(L, -2, "hourField") ;
    [skin pushNSObject:(__bridge NSString *)kAXMinuteFieldAttribute] ;                lua_setfield(L, -2, "minuteField") ;
    [skin pushNSObject:(__bridge NSString *)kAXSecondFieldAttribute] ;                lua_setfield(L, -2, "secondField") ;
    [skin pushNSObject:(__bridge NSString *)kAXAMPMFieldAttribute] ;                  lua_setfield(L, -2, "AMPMField") ;
    [skin pushNSObject:(__bridge NSString *)kAXDayFieldAttribute] ;                   lua_setfield(L, -2, "dayField") ;
    [skin pushNSObject:(__bridge NSString *)kAXMonthFieldAttribute] ;                 lua_setfield(L, -2, "monthField") ;
    [skin pushNSObject:(__bridge NSString *)kAXYearFieldAttribute] ;                  lua_setfield(L, -2, "yearField") ;
    [skin pushNSObject:(__bridge NSString *)kAXColumnTitleAttribute] ;                lua_setfield(L, -2, "columnTitles") ;
    [skin pushNSObject:(__bridge NSString *)kAXURLAttribute] ;                        lua_setfield(L, -2, "URL") ;
    [skin pushNSObject:(__bridge NSString *)kAXLabelUIElementsAttribute] ;            lua_setfield(L, -2, "labelUIElements") ;
    [skin pushNSObject:(__bridge NSString *)kAXLabelValueAttribute] ;                 lua_setfield(L, -2, "labelValue") ;
    [skin pushNSObject:(__bridge NSString *)kAXShownMenuUIElementAttribute] ;         lua_setfield(L, -2, "shownMenuUIElement") ;
    [skin pushNSObject:(__bridge NSString *)kAXServesAsTitleForUIElementsAttribute] ; lua_setfield(L, -2, "servesAsTitleForUIElements") ;
    [skin pushNSObject:(__bridge NSString *)kAXLinkedUIElementsAttribute] ;           lua_setfield(L, -2, "linkedUIElements") ;
    lua_setfield(L, -2, "misc") ;
// Table and outline view attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXRowsAttribute] ;                   lua_setfield(L, -2, "rows") ;
    [skin pushNSObject:(__bridge NSString *)kAXVisibleRowsAttribute] ;            lua_setfield(L, -2, "visibleRows") ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedRowsAttribute] ;           lua_setfield(L, -2, "selectedRows") ;
    [skin pushNSObject:(__bridge NSString *)kAXColumnsAttribute] ;                lua_setfield(L, -2, "columns") ;
    [skin pushNSObject:(__bridge NSString *)kAXVisibleColumnsAttribute] ;         lua_setfield(L, -2, "visibleColumns") ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedColumnsAttribute] ;        lua_setfield(L, -2, "selectedColumns") ;
    [skin pushNSObject:(__bridge NSString *)kAXSortDirectionAttribute] ;          lua_setfield(L, -2, "sortDirection") ;
    [skin pushNSObject:(__bridge NSString *)kAXColumnHeaderUIElementsAttribute] ; lua_setfield(L, -2, "columnHeaderUIElements") ;
    [skin pushNSObject:(__bridge NSString *)kAXIndexAttribute] ;                  lua_setfield(L, -2, "index") ;
    [skin pushNSObject:(__bridge NSString *)kAXDisclosingAttribute] ;             lua_setfield(L, -2, "disclosing") ;
    [skin pushNSObject:(__bridge NSString *)kAXDisclosedRowsAttribute] ;          lua_setfield(L, -2, "disclosedRows") ;
    [skin pushNSObject:(__bridge NSString *)kAXDisclosedByRowAttribute] ;         lua_setfield(L, -2, "disclosedByRow") ;
    lua_setfield(L, -2, "table") ;
// Matte attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXMatteHoleAttribute] ;             lua_setfield(L, -2, "matteHole") ;
    [skin pushNSObject:(__bridge NSString *)kAXMatteContentUIElementAttribute] ; lua_setfield(L, -2, "matteContentUIElement") ;
    lua_setfield(L, -2, "matte") ;
// Dock attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXIsApplicationRunningAttribute] ; lua_setfield(L, -2, "isApplicationRunning") ;
    lua_setfield(L, -2, "dock") ;
// System-wide attributes
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedApplicationAttribute] ; lua_setfield(L, -2, "focusedApplication") ;
    lua_setfield(L, -2, "system") ;
    return 1 ;
}

/// hs._asm.axuielement.parameterizedAttributes[]
/// Constant
/// A table of common accessibility object parameterized attribute names, provided for reference.
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
static int pushParamaterizedAttributesTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXLineForIndexParameterizedAttribute] ;             lua_setfield(L, -2, "lineForIndex") ;
    [skin pushNSObject:(__bridge NSString *)kAXRangeForLineParameterizedAttribute] ;             lua_setfield(L, -2, "rangeForLine") ;
    [skin pushNSObject:(__bridge NSString *)kAXStringForRangeParameterizedAttribute] ;           lua_setfield(L, -2, "stringForRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXRangeForPositionParameterizedAttribute] ;         lua_setfield(L, -2, "rangeForPosition") ;
    [skin pushNSObject:(__bridge NSString *)kAXRangeForIndexParameterizedAttribute] ;            lua_setfield(L, -2, "rangeForIndex") ;
    [skin pushNSObject:(__bridge NSString *)kAXBoundsForRangeParameterizedAttribute] ;           lua_setfield(L, -2, "boundsForRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXRTFForRangeParameterizedAttribute] ;              lua_setfield(L, -2, "RTFForRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXAttributedStringForRangeParameterizedAttribute] ; lua_setfield(L, -2, "attributedStringForRange") ;
    [skin pushNSObject:(__bridge NSString *)kAXStyleRangeForIndexParameterizedAttribute] ;       lua_setfield(L, -2, "styleRangeForIndex") ;
    [skin pushNSObject:(__bridge NSString *)kAXInsertionPointLineNumberAttribute] ;              lua_setfield(L, -2, "insertionPointLineNumber") ;
    return 1 ;
}

/// hs._asm.axuielement.actions[]
/// Constant
/// A table of common accessibility object action names, provided for reference.
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
static int pushActionsTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    [skin pushNSObject:(__bridge NSString *)kAXPressAction] ;           lua_setfield(L, -2, "press") ;
    [skin pushNSObject:(__bridge NSString *)kAXIncrementAction] ;       lua_setfield(L, -2, "increment") ;
    [skin pushNSObject:(__bridge NSString *)kAXDecrementAction] ;       lua_setfield(L, -2, "decrement") ;
    [skin pushNSObject:(__bridge NSString *)kAXConfirmAction] ;         lua_setfield(L, -2, "confirm") ;
    [skin pushNSObject:(__bridge NSString *)kAXCancelAction] ;          lua_setfield(L, -2, "cancel") ;
    [skin pushNSObject:(__bridge NSString *)kAXRaiseAction] ;           lua_setfield(L, -2, "raise") ;
    [skin pushNSObject:(__bridge NSString *)kAXShowMenuAction] ;        lua_setfield(L, -2, "showMenu") ;
    [skin pushNSObject:(__bridge NSString *)kAXShowAlternateUIAction] ; lua_setfield(L, -2, "showAlternateUI") ;
    [skin pushNSObject:(__bridge NSString *)kAXShowDefaultUIAction] ;   lua_setfield(L, -2, "showDefaultUI") ;
    [skin pushNSObject:(__bridge NSString *)kAXPickAction] ;            lua_setfield(L, -2, "pick") ;
    return 1 ;
}

/// hs._asm.axuielement.directions[]
/// Constant
/// A table of common directions which may be specified as the value of an accessibility object property, provided for reference.
///
/// Notes:
///  * this table is provided for reference only and is not intended to be comprehensive.
static int pushDirectionsTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
// Orientations
    [skin pushNSObject:(__bridge NSString *)kAXHorizontalOrientationValue] ; lua_setfield(L, -2, "horizontalOrientation") ;
    [skin pushNSObject:(__bridge NSString *)kAXVerticalOrientationValue] ;   lua_setfield(L, -2, "verticalOrientation") ;
    [skin pushNSObject:(__bridge NSString *)kAXUnknownOrientationValue] ;    lua_setfield(L, -2, "unknownOrientation") ;
// Sort directions
    [skin pushNSObject:(__bridge NSString *)kAXAscendingSortDirectionValue] ;  lua_setfield(L, -2, "ascendingSortDirection") ;
    [skin pushNSObject:(__bridge NSString *)kAXDescendingSortDirectionValue] ; lua_setfield(L, -2, "descendingSortDirection") ;
    [skin pushNSObject:(__bridge NSString *)kAXUnknownSortDirectionValue] ;    lua_setfield(L, -2, "dnknownSortDirection") ;
    return 1 ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFTypeRef value ;
    AXError errorState = AXUIElementCopyAttributeValue(theRef, (__bridge CFStringRef)@"AXRole", &value) ;
    NSString *title = @"*AXRole undefined*" ;
    if (errorState == kAXErrorSuccess) {
        title = (__bridge NSString *)value ;
    }
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    if (value) CFRelease(value) ;
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    AXUIElementRef theRef = get_axuielementref(L, 1, USERDATA_TAG) ;
    CFRelease(theRef) ;
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

static int userdata_eq(lua_State* L) {
    AXUIElementRef theRef1 = get_axuielementref(L, 1, USERDATA_TAG) ;
    AXUIElementRef theRef2 = get_axuielementref(L, 2, USERDATA_TAG) ;
    lua_pushboolean(L, CFEqual(theRef1, theRef2)) ;
    return 1 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"attributeNames",              getAttributeNames},
    {"allAttributeValues",          getAllAttributeValues},
    {"parameterizedAttributeNames", getParameterizedAttributeNames},
    {"actionNames",                 getActionNames},
    {"actionDescription",           getActionDescription},
    {"attributeValue",              getAttributeValue},
    {"parameterizedAttributeValue", getParameterizedAttributeValue},
    {"attributeValueCount",         getAttributeValueCount},
    {"isAttributeSettable",         isAttributeSettable},
    {"pid",                         getPid},
    {"performAction",               performAction},
    {"elementAtPosition",           getElementAtPosition},
    {"setAttributeValue",           setAttributeValue},
    {"getAllChildElements",         getAllAXUIElements},
    {"asHSWindow",                  axuielementToWindow},
    {"asHSApplication",             axuielementToApplication},
    {"copy",                        duplicateReference},
    {"setTimeout",                  axuielement_setTimeout},

    {"__tostring",                  userdata_tostring},
    {"__eq",                        userdata_eq},
    {"__gc",                        userdata_gc},
    {NULL,                          NULL}
} ;

// static int textMarkerTesting(lua_State *L) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     int returns = 2 ;
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wformat-pedantic"
//     [skin pushNSObject:[NSString stringWithFormat:@"wkGetAXTextMarkerTypeID == %p", wkGetAXTextMarkerTypeID]] ;
//     [skin pushNSObject:[NSString stringWithFormat:@"wkGetAXTextMarkerRangeTypeID == %p", wkGetAXTextMarkerRangeTypeID]] ;
// #pragma clang diagnostic pop
//     if (&wkGetAXTextMarkerTypeID && &wkGetAXTextMarkerRangeTypeID) {
//         lua_pushinteger(L, (lua_Integer)wkGetAXTextMarkerTypeID()) ;
//         lua_pushinteger(L, (lua_Integer)wkGetAXTextMarkerRangeTypeID()) ;
//         returns = 4 ;
//     }
//     return returns ;
// }

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"systemWideElement",        getSystemWideElement},
    {"windowElement",            getWindowElement},
    {"applicationElement",       getApplicationElement},
    {"applicationElementForPID", getApplicationElementForPID},
//     {"textMarker",               textMarkerTesting},

    {NULL,                       NULL}
} ;

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// } ;

int luaopen_hs__asm_axuielement_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil
                               objectFunctions:userdata_metaLib] ;

    luaopen_hs__asm_axuielement_observer(L) ; lua_setfield(L, -2, "observer") ;

// For reference, since the object __init wrapper in init.lua and the keys for elementSearch don't
// actually use them in case the user wants to use an Application defined attribute or action not
// defined in the OS X headers.
    pushAttributesTable(L) ;              lua_setfield(L, -2, "attributes") ;
    pushParamaterizedAttributesTable(L) ; lua_setfield(L, -2, "parameterizedAttributes") ;
    pushActionsTable(L) ;                 lua_setfield(L, -2, "actions") ;

// ditto on these, since they are are actually results, not query-able parameters or actionable
// commands; however they can be used with elementSearch as values in the criteria to find such.
    pushRolesTable(L) ;                   lua_setfield(L, -2, "roles") ;
    pushSubrolesTable(L) ;                lua_setfield(L, -2, "subroles") ;
    pushDirectionsTable(L) ;              lua_setfield(L, -2, "directions") ;

    return 1 ;
}
