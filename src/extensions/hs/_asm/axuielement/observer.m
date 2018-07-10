#import "common.h"

/// === hs._asm.axuielement.observer ===
///
/// This submodule allows you to create observers for accessibility elements and be notified when they trigger notifications. Not all notifications are supported by all elements and not all elements support notifications, so some trial and error will be necessary, but for compliant applications, this can allow your code to be notified when an application's user interface changes in some way.
///
/// This is very much a work in progress, so bugs and comments are welcome.

#define DEBUGGING_METHODS

static int refTable = LUA_NOREF ;

static CFMutableDictionaryRef observerDetails = NULL ;

static CFStringRef keySelfRefCount = CFSTR("selfRefCount") ;
static CFStringRef keyCallbackRef  = CFSTR("callbackRef") ;
static CFStringRef keyIsRunning    = CFSTR("isRunning") ;
static CFStringRef keyWatching     = CFSTR("watching") ;

#pragma mark - Support Functions


int pushAXObserver(lua_State *L, AXObserverRef observer) {
    CFMutableDictionaryRef details = CFDictionaryGetValue(observerDetails, observer) ;
    if (!details) {
        details = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks) ;
        CFDictionarySetValue(details, keySelfRefCount, (__bridge CFNumberRef)@(0)) ;
        CFDictionarySetValue(details, keyCallbackRef,  (__bridge CFNumberRef)@(LUA_NOREF)) ;
        CFDictionarySetValue(details, keyIsRunning,    kCFBooleanFalse) ;
        CFDictionarySetValue(details, keyWatching,     CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)) ;

        CFDictionarySetValue(observerDetails, observer, details) ;
    }

    int selfRefCount = [(__bridge NSNumber *)CFDictionaryGetValue(details, keySelfRefCount) intValue] ;
    selfRefCount++ ;
    CFDictionarySetValue(details, keySelfRefCount, (__bridge CFNumberRef)@(selfRefCount)) ;

    AXObserverRef* thePtr = lua_newuserdata(L, sizeof(AXObserverRef)) ;
    *thePtr = CFRetain(observer) ;
    luaL_getmetatable(L, OBSERVER_TAG) ;
    lua_setmetatable(L, -2) ;
    return 1 ;
}

// reduce duplication in meta_gc and userdata_gc

static void purgeWatchers(const void *key, const void *value, void *context) {
    AXUIElementRef    element       = key ;
    CFMutableArrayRef notifications = value ;
    AXObserverRef     observer      = context ;

    for (CFIndex i = 0 ; i < CFArrayGetCount(notifications) ; i++) {
        CFStringRef what = CFArrayGetValueAtIndex(notifications, i) ;
        AXObserverRemoveNotification(observer, element, what) ;
    }
    CFArrayRemoveAllValues(notifications) ;
}

static void cleanupAXObserver(AXObserverRef observer, CFMutableDictionaryRef details) {
    LuaSkin *skin = [LuaSkin shared] ;

    int callbackRef = [(__bridge NSNumber *)CFDictionaryGetValue(details, keyCallbackRef) intValue] ;
    callbackRef = [skin luaUnref:refTable ref:callbackRef] ;
    CFDictionarySetValue(details, keyCallbackRef, (__bridge CFNumberRef)@(callbackRef)) ;

    Boolean isRunning = CFBooleanGetValue(CFDictionaryGetValue(details, keyIsRunning)) ;
    if (isRunning) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), kCFRunLoopCommonModes) ;
        CFDictionarySetValue(details, keyIsRunning, kCFBooleanFalse) ;
    }

    CFMutableDictionaryRef watching = CFDictionaryGetValue(details, keyWatching) ;
    CFDictionaryApplyFunction(watching, purgeWatchers, observer) ;
    CFDictionaryRemoveAllValues(watching) ;
}

static void observerCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, CFDictionaryRef info, __unused void *refcon) {
    LuaSkin   *skin = [LuaSkin shared] ;
    lua_State *L    = skin.L ;

    CFMutableDictionaryRef details = CFDictionaryGetValue(observerDetails, observer) ;
    if (!details) {
        [skin logWarn:[NSString stringWithFormat:@"%s:callback triggered for unregistered observer", OBSERVER_TAG]] ;
    } else {
        int callbackRef = [(__bridge NSNumber *)CFDictionaryGetValue(details, keyCallbackRef) intValue] ;
        if (callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:callbackRef] ;
            pushAXObserver(L, observer) ;
            pushAXUIElement(L, element) ;
            [skin pushNSObject:(__bridge NSString *)notification] ;
            if (info) {
                pushCFTypeToLua(L, info, refTable) ;
            } else {
                lua_newtable(L) ;
            }
            if (![skin protectedCallAndTraceback:4 nresults:0]) {
                [skin logError:[NSString stringWithFormat:@"%s:callback error:%s", OBSERVER_TAG, lua_tostring(L, -1)]] ;
                lua_pop(L, 1) ;
            }
        }
    }
}

#pragma mark - Module Functions

/// hs._asm.axuielement.observer.new(pid) -> observerObject
/// Constructor
/// Creates a new observer object for the application with the specified process ID.
///
/// Parameters:
///  * `pid` - the process ID of the application.
///
/// Returns:
///  * a new observerObject; generates an error if the pid does not exist or if the object cannot be created.
///
/// Notes:
///  * If you already have the `hs.application` object for an application, you can get its process ID with `hs.application:pid()`
///  * If you already have an `hs._asm.axuielement` from the application you wish to observe (it doesn't have to be the application axuielement object, just one belonging to the application), you can get the process ID with `hs._asm.axuielement:pid()`.
static int observer_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    pid_t         appPid   = (pid_t)lua_tointeger(L, 1) ;
    AXObserverRef observer = NULL ;
    AXError       err      = AXObserverCreateWithInfoCallback(appPid, observerCallback, &observer) ;

    if (err != kAXErrorSuccess) return luaL_error(L, AXErrorAsString(err)) ;

    pushAXObserver(L, observer) ;
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.axuielement.observer:start() -> observerObject
/// Method
/// Start observing the application and trigger callbacks for the elements and notifications assigned.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the observerObject
///
/// Notes:
///  * This method does nothing if the observer is already running
static int observer_start(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;

    Boolean isRunning = CFBooleanGetValue(CFDictionaryGetValue(details, keyIsRunning)) ;
    if (!isRunning) {
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), kCFRunLoopCommonModes) ;
        CFDictionarySetValue(details, keyIsRunning, kCFBooleanTrue) ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.axuielement.observer:stop() -> observerObject
/// Method
/// Stop observing the application; no further callbacks will be generated.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the observerObject
///
/// Notes:
///  * This method does nothing if the observer is not currently running
static int observer_stop(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;

    Boolean isRunning = CFBooleanGetValue(CFDictionaryGetValue(details, keyIsRunning)) ;
    if (isRunning) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), kCFRunLoopCommonModes) ;
        CFDictionarySetValue(details, keyIsRunning, kCFBooleanFalse) ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.axuielement.observer:isRunning() -> boolean
/// Method
/// Returns true or false indicating whether the observer is currently watching for notifications and generating callbacks.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean value indicating whether or not the observer is currently active.
static int observer_isRunning(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;

    lua_pushboolean(L, CFBooleanGetValue(CFDictionaryGetValue(details, keyIsRunning))) ;
    return 1 ;
}

/// hs._asm.axuielement.observer:callback([fn | nil]) -> observerObject | fn | nil
/// Method
/// Get or set the callback for the observer.
///
/// Parameters:
///  * `fn` - a function, or an explicit nil to remove, specifying the callback to the observer will invoke when the assigned elements generate notifications.
///
/// Returns:
///  * If an argument is provided, the observerObject; otherwise the current value.
///
/// Notes:
///  * the callback should expect 4 arguments and return none. The arguments passed to the callback will be as follows:
///    * the observerObject itself
///    * the `hs._asm.axuielement` object for the accessibility element which generated the notification
///    * a string specifying the specific notification which was received
///    * a table containing key-value pairs with more information about the notification, if the element and notification type provide it. Commonly this will be an empty table indicating that no additional detail was provided.
static int observer_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;

    int callbackRef = [(__bridge NSNumber *)CFDictionaryGetValue(details, keyCallbackRef) intValue] ;
    if (lua_gettop(L) == 2) {
        callbackRef = [skin luaUnref:refTable ref:callbackRef] ;
        CFDictionarySetValue(details, keyCallbackRef, (__bridge CFNumberRef)@(callbackRef)) ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            callbackRef = [skin luaRef:refTable] ;
            CFDictionarySetValue(details, keyCallbackRef, (__bridge CFNumberRef)@(callbackRef)) ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.axuielement.observer:addWatcher(element, notification) -> observerObject
/// Method
/// Registers the specified notification for the specified accesibility element with the observer.
///
/// Parameters:
///  * `element`      - the `hs._asm.axuielement` representing an accessibility element of the application the observer was created for.
///  * `notification` - a string specifying the notification.
///
/// Returns:
///  * the observerObject; generates an error if watcher cannot be registered
///
/// Notes:
///  * multiple notifications for the same accessibility element can be registered by invoking this method multiple times with the same element but different notification strings.
///  * if the specified element and notification string are already registered, this method does nothing.
///  * the notification string is application dependent and can be any string that the application developers choose; some common ones are found in `hs._asm.axuielement.observer.notifications`, but the list is not exhaustive nor is an application or element required to provide them.
static int observer_addWatchedElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG,
                    LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING,
                    LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;
    AXUIElementRef         element  = get_axuielementref(L, 2, USERDATA_TAG) ;
    NSString               *what    = [skin toNSObjectAtIndex:3] ;

    CFMutableDictionaryRef watching      = CFDictionaryGetValue(details, keyWatching) ;
    CFMutableArrayRef      notifications = CFDictionaryGetValue(watching, element) ;

    Boolean exists = false ;
    if (notifications) {
        exists = CFArrayContainsValue(notifications, CFRangeMake(0, CFArrayGetCount(notifications)), (__bridge CFStringRef)what) ;
    } else {
        notifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks) ;
        CFDictionarySetValue(watching, element, notifications) ;
    }
    if (!exists) {
        AXError err = AXObserverAddNotification(observer, element, (__bridge CFStringRef)what, NULL) ;
        if (err != kAXErrorSuccess) return luaL_error(L, AXErrorAsString(err)) ;
        CFArrayAppendValue(notifications, (__bridge CFStringRef)what) ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.axuielement.observer:removeWatcher(element, notification) -> observerObject
/// Method
/// Unregisters the specified notification for the specified accessibility element from the observer.
///
/// Parameters:
///  * `element`      - the `hs._asm.axuielement` representing an accessibility element of the application the observer was created for.
///  * `notification` - a string specifying the notification.
///
/// Returns:
///  * the observerObject; generates an error if watcher cannot be unregistered
///
/// Notes:
///  * if the specified element and notification string are not currently registered with the observer, this method does nothing.
static int observer_removeWatchedElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG,
                    LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING,
                    LS_TBREAK] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;
    AXUIElementRef         element  = get_axuielementref(L, 2, USERDATA_TAG) ;
    NSString               *what    = [skin toNSObjectAtIndex:3] ;

    CFMutableDictionaryRef watching      = CFDictionaryGetValue(details, keyWatching) ;
    CFMutableArrayRef      notifications = CFDictionaryGetValue(watching, element) ;

    CFIndex exists = -1 ;
    if (notifications) {
        exists = CFArrayGetFirstIndexOfValue(notifications, CFRangeMake(0, CFArrayGetCount(notifications)), (__bridge CFStringRef)what) ;
    } else {
        notifications = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks) ;
        CFDictionarySetValue(watching, element, notifications) ;
    }
    if (exists > -1) {
        AXError err = AXObserverRemoveNotification(observer, element, (__bridge CFStringRef)what) ;
        if (err != kAXErrorSuccess) return luaL_error(L, AXErrorAsString(err)) ;
        CFArrayRemoveValueAtIndex(notifications, exists) ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.axuielement.observer:watching([element]) -> table
/// Method
/// Returns a table of the notifications currently registered with the observer.
///
/// Parameters:
///  * `element` - an optional `hs._asm.axuielement` to return a list of registered notifications for.
///
/// Returns:
///  * a table containing the currently registered notifications
///
/// Notes:
///  * If an element is specified, then the table returned will contain a list of strings specifying the specific notifications that the observer is watching that element for.
///  * If no argument is specified, then the table will contain key-value pairs in which each key will be an `hs._asm.axuielement` that is being observed and the corresponding value will be a table containing a list of strings specifying the specific notifications that the observer is watching for from from that element.
static int observer_watchedElements(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TBREAK | LS_TVARARG] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;
    AXUIElementRef         element  = NULL ;
    if (lua_gettop(L) > 1) {
        [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
        element = get_axuielementref(L, 2, USERDATA_TAG) ;
    }

    CFMutableDictionaryRef watching = CFDictionaryGetValue(details, keyWatching) ;
    if (element) {
        CFMutableArrayRef notifications = CFDictionaryGetValue(watching, element) ;
        if (notifications) {
            pushCFTypeToLua(L, notifications, refTable) ;
        } else {
            lua_newtable(L) ;
        }
    } else {
        pushCFTypeToLua(L, watching, refTable) ;
    }
    return 1 ;
}

#ifdef DEBUGGING_METHODS
static int observer_internalDetails(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    CFMutableDictionaryRef details = observerDetails ;
    if (lua_gettop(L) > 0) {
        [skin checkArgs:LS_TUSERDATA, OBSERVER_TAG, LS_TBREAK] ;
        AXObserverRef       observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
        details  = CFDictionaryGetValue(observerDetails, observer) ;
    }
    pushCFTypeToLua(L, details, refTable) ;
    return 1 ;
}
#endif

#pragma mark - Module Constants

/// hs._asm.axuielement.observer.notifications[]
/// Constant
/// A table of common accessibility object notification names, provided for reference.
///
/// Notes:
///  * Notifications are application dependent and can be any string that the application developers choose; this list provides the suggested notification names found within the macOS Framework headers, but the list is not exhaustive nor is an application or element required to provide them.
static int pushNotificationsTable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
// Focus notifications
    [skin pushNSObject:(__bridge NSString *)kAXMainWindowChangedNotification] ;       lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedWindowChangedNotification] ;    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXFocusedUIElementChangedNotification] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Application notifications
    [skin pushNSObject:(__bridge NSString *)kAXApplicationActivatedNotification] ;    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXApplicationDeactivatedNotification] ;  lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXApplicationHiddenNotification] ;       lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXApplicationShownNotification] ;        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Window notifications
    [skin pushNSObject:(__bridge NSString *)kAXWindowCreatedNotification] ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowMovedNotification] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowResizedNotification] ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowMiniaturizedNotification] ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXWindowDeminiaturizedNotification] ;    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// New drawer, sheet, and help tag notifications
    [skin pushNSObject:(__bridge NSString *)kAXDrawerCreatedNotification] ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSheetCreatedNotification] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXHelpTagCreatedNotification] ;          lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Element notifications
    [skin pushNSObject:(__bridge NSString *)kAXValueChangedNotification] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXUIElementDestroyedNotification] ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXElementBusyChangedNotification] ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Menu notifications
    [skin pushNSObject:(__bridge NSString *)kAXMenuOpenedNotification] ;              lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuClosedNotification] ;              lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXMenuItemSelectedNotification] ;        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Table and outline view notifications
    [skin pushNSObject:(__bridge NSString *)kAXRowCountChangedNotification] ;         lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXRowCollapsedNotification] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXRowExpandedNotification] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
// Miscellaneous notifications
    [skin pushNSObject:(__bridge NSString *)kAXSelectedChildrenChangedNotification] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXResizedNotification] ;                 lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXMovedNotification] ;                   lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXCreatedNotification] ;                 lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXAnnouncementRequestedNotification] ;   lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXLayoutChangedNotification] ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedCellsChangedNotification] ;    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedChildrenMovedNotification] ;   lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedColumnsChangedNotification] ;  lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedRowsChangedNotification] ;     lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXSelectedTextChangedNotification] ;     lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXTitleChangedNotification] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:(__bridge NSString *)kAXUnitsChangedNotification] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;

    return 1 ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
//     AXObserverRef observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: (%p)", OBSERVER_TAG, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    AXObserverRef          observer = get_axobserverref(L, 1, OBSERVER_TAG) ;
    CFMutableDictionaryRef details  = CFDictionaryGetValue(observerDetails, observer) ;

    if (!details) {
        [skin logWarn:[NSString stringWithFormat:@"%s:__gc triggered for unregistered observer", OBSERVER_TAG]] ;
    } else {
        int selfRefCount = [(__bridge NSNumber *)CFDictionaryGetValue(details, keySelfRefCount) intValue] ;
        selfRefCount-- ;
        CFDictionarySetValue(details, keySelfRefCount, (__bridge CFNumberRef)@(selfRefCount)) ;
        if (selfRefCount == 0) {
            cleanupAXObserver(observer, details) ;
            CFDictionaryRemoveValue(observerDetails, observer) ;
            CFRelease(observer) ;
        }
    }
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

static int userdata_eq(lua_State* L) {
    AXObserverRef observer1 = get_axobserverref(L, 1, OBSERVER_TAG) ;
    AXObserverRef observer2 = get_axobserverref(L, 2, OBSERVER_TAG) ;
    lua_pushboolean(L, CFEqual(observer1, observer2)) ;
    return 1 ;
}

static void purgeObserver(const void *key, const void *value, __unused void *context) {
    AXObserverRef          observer = key ;
    CFMutableDictionaryRef details  = value ;
    cleanupAXObserver(observer, details) ;
}

static int meta_gc(lua_State* __unused L) {
    CFDictionaryApplyFunction(observerDetails, purgeObserver, NULL) ;
    CFDictionaryRemoveAllValues(observerDetails) ;
    observerDetails = NULL ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"start",         observer_start},
    {"stop",          observer_stop},
    {"isRunning",     observer_isRunning},
    {"callback",      observer_callback},
    {"addWatcher",    observer_addWatchedElement},
    {"removeWatcher", observer_removeWatchedElement},
    {"watching",      observer_watchedElements},

#ifdef DEBUGGING_METHODS
    {"_internals",    observer_internalDetails},
#endif

    {"__tostring",    userdata_tostring},
    {"__eq",          userdata_eq},
    {"__gc",          userdata_gc},
    {NULL,            NULL}
} ;

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",        observer_new},
#ifdef DEBUGGING_METHODS
    {"_internals", observer_internalDetails},
#endif
    {NULL,         NULL}
} ;

// Metatable for module, if needed
static const luaL_Reg module_metaLib[] = {
    {"__gc", meta_gc},
    {NULL,   NULL}
} ;

int luaopen_hs__asm_axuielement_observer(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:OBSERVER_TAG
                                     functions:moduleLib
                                 metaFunctions:module_metaLib
                               objectFunctions:userdata_metaLib] ;

    observerDetails = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks) ;

    pushNotificationsTable(L) ; lua_setfield(L, -2, "notifications") ;

    return 1 ;
}
