@import Cocoa ;
@import LuaSkin ;

// TODO:
// *  Write our own conversion tool here since CFPropertyListRef is known to be:
// *      limited to the following types: CFData, CFString, CFArray, CFDictionary, CFDate, CFBoolean, and CFNumber
// *      keys for CFDictionary must be strings
// *  add our own formats for date in/out like described below?
// *  to force data type when Hammerspoon thinks it is a valid string?
// *  Remaining methods -- evaluate and decide
//    Document
//    NSArchivedObject support
//
//    Add explicit date and data setters for hs.settings parity? not really needed with table support, but may be easier in some instances
//    How to merge with settings/plist?

// // See http://www.cocoabuilder.com/archive/cocoa/72061-cfpreferences-vs-nsuserdefaults.html
// // * Note that we can't write for kCFPreferencesAnyUser without root
// // * if applicationID exists in perHost and anyHost directories, which gets read/set? is that sufficient reason to add these even with the limitation that kCFPreferencesAnyUser can't be set?


static const char * const USERDATA_TAG = "hs._asm.cfpreferences" ; // used in warnings
static int refTable = LUA_NOREF;

#pragma mark - Support Functions and Classes

static int pushCFPropertyListToLua(lua_State *L, CFPropertyListRef obj) ;
static CFPropertyListRef luaObjectToCFPropertyListRef(lua_State *L, int idx) ;

static NSDate* date_from_string(NSString* dateString) {
    // rfc3339 (Internet Date/Time) formated date.  More or less.
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *date = [rfc3339DateFormatter dateFromString:dateString];
    return date;
}

#pragma mark - Module Functions

static int cfpreferences_copyAppValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    BOOL     useSimplified  = YES ;
    NSString *key           = [skin toNSObjectAtIndex:1] ;
    NSString *applicationID = (lua_type(L, 2) == LUA_TSTRING) ? [skin toNSObjectAtIndex:2]
                                                              : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    CFStringRef userName = kCFPreferencesCurrentUser ;
    CFStringRef hostName = kCFPreferencesAnyHost ;

    switch(lua_gettop(L)) {
        case 2:
            if (lua_type(L, 2) == LUA_TBOOLEAN) {
                useSimplified = NO ;
                userName = lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 3:
            useSimplified = NO ;
            if (lua_type(L, 2) == LUA_TBOOLEAN) {
                userName = lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
                hostName = lua_toboolean(L, 3) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            } else { // lua_type(L, 2) == LUA_TSTRING
                userName = lua_toboolean(L, 3) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 4:
            useSimplified = NO ;
            userName = lua_toboolean(L, 3) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            hostName = lua_toboolean(L, 4) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            break ;
    }

    CFPropertyListRef results = NULL ;
    if (useSimplified) {
        results = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)applicationID) ;
    } else {
        results = CFPreferencesCopyValue((__bridge CFStringRef)key, (__bridge CFStringRef)applicationID, userName, hostName) ;
    }

    if (results != NULL) {
        pushCFPropertyListToLua(L, results) ;
        CFRelease(results) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int cfpreferences_getAppBooleanValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *key           = [skin toNSObjectAtIndex:1] ;
    NSString *applicationID = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    Boolean  existsAndValid = false ;
    Boolean  result = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, (__bridge CFStringRef)applicationID, &existsAndValid) ;
    if (existsAndValid) {
        lua_pushboolean(L, result) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int cfpreferences_getAppIntegerValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *key           = [skin toNSObjectAtIndex:1] ;
    NSString *applicationID = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    Boolean  existsAndValid = false ;
    CFIndex  result = CFPreferencesGetAppIntegerValue((__bridge CFStringRef)key, (__bridge CFStringRef)applicationID, &existsAndValid) ;
    if (existsAndValid) {
        lua_pushinteger(L, result) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int cfpreferences_appSynchronize(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    BOOL     useSimplified  = YES ;
    NSString *applicationID = (lua_type(L, 1) == LUA_TSTRING) ? [skin toNSObjectAtIndex:1]
                                                              : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    CFStringRef userName = kCFPreferencesCurrentUser ;
    CFStringRef hostName = kCFPreferencesAnyHost ;

    switch(lua_gettop(L)) {
        case 1:
            if (lua_type(L, 1) == LUA_TBOOLEAN) {
                useSimplified = NO ;
                userName = lua_toboolean(L, 1) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 2:
            useSimplified = NO ;
            if (lua_type(L, 1) == LUA_TBOOLEAN) {
                userName = lua_toboolean(L, 1) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
                hostName = lua_toboolean(L, 2) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            } else { // lua_type(L, 1) == LUA_TSTRING
                userName = lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 3:
            useSimplified = NO ;
            userName = lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            hostName = lua_toboolean(L, 3) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            break ;
    }

    if (useSimplified) {
        lua_pushboolean(L, CFPreferencesAppSynchronize((__bridge CFStringRef)applicationID)) ;
    } else {
        lua_pushboolean(L, CFPreferencesSynchronize((__bridge CFStringRef)applicationID, userName, hostName)) ;
    }
    return 1 ;
}

static int cfpreferences_appValueIsForced(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *key           = [skin toNSObjectAtIndex:1] ;
    NSString *applicationID = (lua_gettop(L) == 2) ? [skin toNSObjectAtIndex:2] : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    lua_pushboolean(L, CFPreferencesAppValueIsForced((__bridge CFStringRef)key, (__bridge CFStringRef)applicationID)) ;
    return 1 ;
}

static int cfpreferences_copyKeyList(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *applicationID = (lua_gettop(L) > 0) ? [skin toNSObjectAtIndex:1] : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    CFStringRef userName    = (lua_gettop(L) > 1) ? (lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser) : kCFPreferencesCurrentUser ;
    CFStringRef hostName    = (lua_gettop(L) > 2) ? (lua_toboolean(L, 3) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost) : kCFPreferencesAnyHost ;
    CFArrayRef results = CFPreferencesCopyKeyList((__bridge CFStringRef)applicationID, userName, hostName) ;
    if (results != NULL) {
        pushCFPropertyListToLua(L, results) ;
        CFRelease(results) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int cfpreferences_setAppValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TANY, LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    BOOL              useSimplified  = YES ;
    NSString          *key           = [skin toNSObjectAtIndex:1] ;
    CFPropertyListRef value          = (lua_type(L, 2) != LUA_TNIL) ? luaObjectToCFPropertyListRef(L, 2) : NULL ;
    NSString          *applicationID = (lua_type(L, 3) == LUA_TSTRING) ? [skin toNSObjectAtIndex:3]
                                                                       : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    CFStringRef userName = kCFPreferencesCurrentUser ;
    CFStringRef hostName = kCFPreferencesAnyHost ;

    switch(lua_gettop(L)) {
        case 3:
            if (lua_type(L, 3) == LUA_TBOOLEAN) {
                useSimplified = NO ;
                userName = lua_toboolean(L, 3) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 4:
            useSimplified = NO ;
            if (lua_type(L, 3) == LUA_TBOOLEAN) {
                userName = lua_toboolean(L, 3) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
                hostName = lua_toboolean(L, 4) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            } else { // lua_type(L, 2) == LUA_TSTRING
                userName = lua_toboolean(L, 4) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            }
            break ;
        case 5:
            useSimplified = NO ;
            userName = lua_toboolean(L, 4) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser ;
            hostName = lua_toboolean(L, 5) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost ;
            break ;
    }

    if (value == NULL && lua_type(L, 2) != LUA_TNIL) {
        return luaL_argerror(L, 2, "invalid value specified; details in log") ;
    }

    if (CFEqual(userName, kCFPreferencesAnyUser)) {
        [skin logWarn:[NSString stringWithFormat:@"%s.setValue with anyUser set to true requires administrator privileges which is not supported by Hammerspoon; this is expected to fail.", USERDATA_TAG]] ;
    }

    if (useSimplified) {
        CFPreferencesSetAppValue((__bridge CFStringRef)key, value, (__bridge CFStringRef)applicationID) ;
    } else {
        CFPreferencesSetValue((__bridge CFStringRef)key, value, (__bridge CFStringRef)applicationID, userName, hostName) ;
    }
    return 0 ;
}

// // Easier to iterate in lua, so not including
// CFDictionaryRef CFPreferencesCopyMultiple(_Nullable CFArrayRef keysToFetch, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName);
// void CFPreferencesSetMultiple(_Nullable CFDictionaryRef keysToSet, _Nullable CFArrayRef keysToRemove, CFStringRef applicationID, CFStringRef userName, CFStringRef hostName);

// // Would allow adding into the search space for hs.settings, though set would still write to specified target
// void CFPreferencesAddSuitePreferencesToApp(CFStringRef applicationID, CFStringRef suiteID);
// void CFPreferencesRemoveSuitePreferencesFromApp(CFStringRef applicationID, CFStringRef suiteID);

// Not sure about these...
// Uundocumented:
extern CFPropertyListRef _CFPreferencesCopyApplicationMap(CFStringRef userName, CFStringRef hostName) __attribute__((weak_import));
extern void              _CFPreferencesFlushCachesForIdentifier(CFStringRef applicationID, CFStringRef userName) __attribute__((weak_import));

static int cfpreferences_flushCachesForIdentifier(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *applicationID = (lua_gettop(L) > 0) ? [skin toNSObjectAtIndex:1] : (__bridge NSString *)kCFPreferencesCurrentApplication ;
    CFStringRef userName    = (lua_gettop(L) > 1) ? (lua_toboolean(L, 2) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser) : kCFPreferencesCurrentUser ;
    if (&_CFPreferencesFlushCachesForIdentifier != NULL) {
        _CFPreferencesFlushCachesForIdentifier((__bridge CFStringRef)applicationID, userName) ;
        lua_pushboolean(L, YES) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s.applicationMap - private function _CFPreferencesFlushCachesForIdentifier not defined in this OS version; returning nil", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int cfpreferences_copyApplicationMap(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    CFStringRef userName = (lua_gettop(L) > 0) ? (lua_toboolean(L, 1) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser) : kCFPreferencesCurrentUser ;
    CFStringRef hostName = (lua_gettop(L) > 1) ? (lua_toboolean(L, 2) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost) : kCFPreferencesAnyHost ;
    if (&_CFPreferencesCopyApplicationMap != NULL) {
        CFPropertyListRef results = _CFPreferencesCopyApplicationMap(userName, hostName) ;
        if (results != NULL) {
            [skin pushNSObject:(__bridge_transfer id)results] ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s.applicationMap - private function _CFPreferencesCopyApplicationMap not defined in this OS version; returning nil", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// Deprecated, so we do the same weak import and check before actually using it
_Nullable CFArrayRef CFPreferencesCopyApplicationList(CFStringRef userName, CFStringRef hostName) __attribute__((weak_import));

static int cfpreferences_copyApplicationList(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    CFStringRef userName = (lua_gettop(L) > 0) ? (lua_toboolean(L, 1) ? kCFPreferencesAnyUser : kCFPreferencesCurrentUser) : kCFPreferencesCurrentUser ;
    CFStringRef hostName = (lua_gettop(L) > 1) ? (lua_toboolean(L, 2) ? kCFPreferencesAnyHost : kCFPreferencesCurrentHost) : kCFPreferencesAnyHost ;
    if (&CFPreferencesCopyApplicationList != NULL) {
        CFPropertyListRef results = CFPreferencesCopyApplicationList(userName, hostName) ;
        if (results != NULL) {
            [skin pushNSObject:(__bridge_transfer id)results] ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s.applicationMap - deprecated function CFPreferencesCopyApplicationList not defined in this OS version; returning nil", USERDATA_TAG]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}
#pragma clang diagnostic pop

#pragma mark - Module Methods

#pragma mark - Module Constants

// static int push_preferencesKeys(lua_State *L) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     lua_newtable(L) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesAnyApplication] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesCurrentApplication] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesAnyHost] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesCurrentHost] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesAnyUser] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     [skin pushNSObject:(__bridge NSString *)kCFPreferencesCurrentUser] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//     return 1 ;
// }

#pragma mark - Lua conversion helpers

// NSDate *date = [skin luaObjectAtIndex:idx toClass:"NSDate"] ;
// NSDate *date = [skin toNSObjectAtIndex:idx] ;
// C-API
// Returns an NSDate object as described in the table on the Lua Stack at idx.
//
// The table should have one of the following formats:
//
// { -- output of `os.time()` plus optional float portion for fraction of a second
//     number,
//     __luaSkinType = "NSDate" -- optional if using the luaObjectAtIndex:toClass: , required if using toNSObjectAtIndex:
// }
//
// { -- rfc3339 string (supported by hs.settings) AKA "Internet Date and Time Timestamp Format"
//     'YYYY-MM-DD[T]HH:MM:SS[Z]',
//     __luaSkinType = "NSDate" -- optional if using the luaObjectAtIndex:toClass: , required if using toNSObjectAtIndex:
// }
//
// { -- this matches the output of `os.date("*t")` -- are there other fields we should optionally allow since macOS can be more precise?
//     day   = integer,
//     hour  = integer,
//     isdst = boolean,
//     min   = integer,
//     month = integer,
//     sec   = integer,
//     wday  = integer, // ignored
//     yday  = integer, // ignored
//     year  = integer,
//     ns    = integer,
//     __luaSkinType = "NSDate" -- optional if using the luaObjectAtIndex:toClass: , required if using toNSObjectAtIndex:
// }
static id table_toNSDate(lua_State *L, int idx) {
    NSDate *theDate = nil ;
    LuaSkin *skin = [LuaSkin shared];
    if (lua_type(L, idx) == LUA_TTABLE) {
        if (luaL_len(L, idx) != 0) {
            if (lua_rawgeti(L, idx, 1) == LUA_TNUMBER) {
                theDate = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval) lua_tonumber(L,-1)] ;
            } else if (lua_type(L, -1) == LUA_TSTRING) {
                theDate = date_from_string([NSString stringWithUTF8String:lua_tostring(L, -1)]) ;
            }
            if (!theDate) {
                [skin logWarn:[NSString stringWithFormat:@"%s:table_toNSDate - expected # of seconds since 1970-01-01 00:00:00Z or string in the format of 'YYYY-MM-DD[T]HH:MM:SS[Z]' (rfc3339) at index 1, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
            }
            lua_pop(L, 1) ;
        } else {
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init] ;

            if (lua_getfield(L, idx, "day") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.day = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for day, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "hour") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.hour = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for hour, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            // check after hour, since we're going to manipulate it directly
            if (lua_getfield(L, idx, "isdst") != LUA_TNIL) {
                if (lua_type(L, -1) == LUA_TBOOLEAN) {
                    if (lua_toboolean(L, -1)) dateComponents.hour = dateComponents.hour - 1 ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected boolean for isdst, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "min") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.minute = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for min, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "month") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.month = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for month, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "sec") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.second = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for sec, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "year") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.year = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for year, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            if (lua_getfield(L, idx, "ns") != LUA_TNIL) {
                if (lua_isinteger(L, -1)) {
                    dateComponents.nanosecond = lua_tointeger(L, -1) ;
                } else {
                    [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSDate - expected integer for ns, found %s; ignoring field", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
                }
            }
            lua_pop(L, 1) ;

            NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            theDate = [gregorianCalendar dateFromComponents:dateComponents];
        }
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:table_toNSDate - expected table, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, idx))]] ;
    }
    return theDate ;
}

// NSData *data = [skin luaObjectAtIndex:idx toClass:"NSData"] ;
// NSData *data = [skin toNSObjectAtIndex:idx] ;
// C-API
// Returns an NSData object as described in the table on the Lua Stack at idx.
//
// The table should have one of the following formats:
//
// { -- array of 8bit integers
//     int, [int, ...]
//     __luaSkinType = "NSDate" -- optional if using the luaObjectAtIndex:toClass: , required if using toNSObjectAtIndex:
// }
//
// { -- lua string treated as concatenated bytes
//     'dataAsLuaByteString',
//     __luaSkinType = "NSData" -- optional if using the luaObjectAtIndex:toClass: , required if using toNSObjectAtIndex:
// }
static id table_toNSData(lua_State *L, int idx) {
    NSData *theData = nil ;
    LuaSkin *skin = [LuaSkin shared];
    if (lua_type(L, idx) == LUA_TTABLE) {
        if (lua_rawgeti(L, idx, 1) == LUA_TSTRING) {
            theData = [skin toNSObjectAtIndex:-1 withOptions:LS_NSLuaStringAsDataOnly] ;
        } else if (lua_isinteger(L, -1)) {
            // we're ignoring the byte already on the stack so the pop at the end of this if-then-else is balanced
            NSInteger arraySize = luaL_len(L, idx) ;
            NSMutableData *tempData = [[NSMutableData alloc] init] ;
            BOOL isGood = YES ;
            for (NSInteger i = 0 ; i < arraySize ; i++) {
                if ((lua_rawgeti(L, idx, i + 1) == LUA_TNUMBER) && lua_isinteger(L, -1)) {
                    NSUInteger luaByte = (NSUInteger)lua_tointeger(L, -1) ;
                    if (luaByte > 255) [skin logInfo:[NSString stringWithFormat:@"%s:table_toNSData - expected integer byte value (0-255) at index %ld; using LSB", USERDATA_TAG, i + 1]] ;
                    uint8_t byte = (uint8_t)(luaByte & 0xff) ;
                    [tempData appendBytes:&byte length:1] ;
                } else {
                    [skin logWarn:[NSString stringWithFormat:@"%s:table_toNSData - expected integer, found %s at index %ld", USERDATA_TAG, lua_typename(L, lua_type(L, -1)), i + 1]] ;
                    isGood = NO ;
                }
                lua_pop(L, 1) ;
                if (!isGood) break ;
            }
            if (isGood) theData = [tempData copy] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:table_toNSData - expected table with lua byte string or array of integers, found %s at index 1", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;
    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s:table_toNSData - expected table, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, idx))]] ;
    }
    return theData ;
}

// These are used internally but won't be published to LuaSkin because they would break too many existing things; maybe if
// they turn out to be really useful and we decide a fundamental change is worth the compatibility headaches or there is a
// fundamental rewrite

static int pushNSDateAsTable(lua_State *L, id obj) {
    LuaSkin *skin = [LuaSkin shared] ;
    if ([obj isKindOfClass:[NSDate class]]) {
        NSDate *value = obj ;
        lua_newtable(L) ;
        [skin pushNSObject:@"NSDate"] ; lua_setfield(L, -2, "__luaSkinType") ;
        lua_pushnumber(L, [value timeIntervalSince1970]) ;
        lua_rawseti(L, -2, 1) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"%s:pushNSDateAsTable - expected NSDate object; received %@", USERDATA_TAG, obj]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int pushNSDataAsTable(lua_State *L, id obj) {
    LuaSkin *skin = [LuaSkin shared] ;
    if ([obj isKindOfClass:[NSData class]]) {
        NSData *value = obj ;
        lua_newtable(L) ;
        [skin pushNSObject:@"NSData"] ; lua_setfield(L, -2, "__luaSkinType") ;
        const uint8_t *bytesBlock = value.bytes ;
        for (NSUInteger i = 0 ; i < value.length ; i++) {
            uint8_t byte = bytesBlock[i] ;
            lua_pushinteger(L, byte) ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
    } else {
        [skin logError:[NSString stringWithFormat:@"%s:pushNSDataAsTable - expected NSData object; received %@", USERDATA_TAG, obj]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

// CFPropertyListRef conversion tools -- again. used internally only because LuaSkin currently has no support for CF types

//     Because we're getting the CFPropertyListRef from the CFPreferences* functions, we can be confident they're not
//     malformed (e.g. contain loops, dictionary keys are strings, not a data type not checked below, etc.)
//     A more generic CFType checker would have to check for these...
static int pushCFPropertyListToLua(lua_State *L, CFPropertyListRef obj) {
    if (obj != NULL) {
        LuaSkin *skin = [LuaSkin shared] ;
        CFTypeID typeID = CFGetTypeID(obj) ;
        // CFData, CFString, CFArray, CFDictionary, CFDate, CFBoolean, and CFNumber
        if (typeID == CFDataGetTypeID()) {
            pushNSDataAsTable(L, (__bridge NSData *)obj) ;
        } else if (typeID == CFStringGetTypeID()) {
            [skin pushNSObject:(__bridge NSString *)obj] ;
        } else if (typeID == CFArrayGetTypeID()) {
            lua_newtable(L) ;
            for(id thing in (__bridge NSArray *)obj) {
                pushCFPropertyListToLua(L, (__bridge CFTypeRef)thing) ;
                lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
            }
        } else if (typeID == CFDictionaryGetTypeID()) {
            lua_newtable(L) ;
            NSArray *keys = [(__bridge NSDictionary *)obj allKeys] ;
            NSArray *values = [(__bridge NSDictionary *)obj allValues] ;
            for (unsigned long i = 0 ; i < [keys count] ; i++) {
                pushCFPropertyListToLua(L, (__bridge CFTypeRef)[keys objectAtIndex:i]) ;
                pushCFPropertyListToLua(L, (__bridge CFTypeRef)[values objectAtIndex:i]) ;
                lua_settable(L, -3) ;
            }
        } else if (typeID == CFDateGetTypeID()) {
            pushNSDateAsTable(L, (__bridge NSDate *)obj) ;
        } else if (typeID == CFBooleanGetTypeID()) {
            lua_pushboolean(L, CFBooleanGetValue(obj)) ;
        } else if (typeID == CFNumberGetTypeID()) {
            [skin pushNSObject:(__bridge NSNumber *)obj] ;
        } else if (typeID == CFNullGetTypeID()) {
            [skin pushNSObject:(__bridge NSNull *)obj] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:pushCFPropertyListToLua - unrecognized or invalid property type %ld", USERDATA_TAG, typeID]] ;
            lua_pushnil(L) ;
        }
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static CFPropertyListRef luaObjectToCFPropertyListRef(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    CFPropertyListRef obj = NULL ;

    switch(lua_type(L, idx)) {
        case LUA_TNIL:        // already NULL, so nothing to do
            break ;
        case LUA_TNUMBER:
            if (lua_isinteger(L, idx)) {
                lua_Integer holder = lua_tointeger(L, idx) ;
                obj = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &holder) ;
            } else {
                lua_Number holder = lua_tonumber(L, idx) ;
                obj = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &holder) ;
            }
            break ;
        case LUA_TBOOLEAN:
            obj = lua_toboolean(L, idx) ? kCFBooleanTrue : kCFBooleanFalse ;
            break ;
        case LUA_TSTRING: {
            id holder = [skin toNSObjectAtIndex:idx] ;
            if ([holder isKindOfClass:[NSString class]]) {
                obj = (__bridge_retained CFStringRef)holder ;
            } else {
                obj = (__bridge_retained CFDataRef)holder ;
            }
        } break ;
        case LUA_TTABLE: {
            BOOL treatAsRealTable = YES ;
            if (lua_getfield(L, idx, "__luaSkinType") != LUA_TNIL) {
                id possibleObj = [skin toNSObjectAtIndex:idx] ;
                if ([possibleObj isKindOfClass:[NSData class]]) {
                    obj = (__bridge_retained CFDataRef)possibleObj ;
                } else if ([possibleObj isKindOfClass:[NSDate class]]) {
                    obj = (__bridge_retained CFDateRef)possibleObj ;
                } else {
                    [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - __luaSkinType table %s not supported for conversion to CFPropertyListRef type", USERDATA_TAG, lua_tostring(L, -1)]] ;
                }
                treatAsRealTable = NO ;
            }
            lua_pop(L, 1) ;
// If this is made more global, this section will need a rewrite -- this version is CFPropertyListRef specific and:
//    assumes that any table with a length must be an array and ignores non consecutive integer indexes
//    requires dictionary keys to be strings
            if (treatAsRealTable) {
                if (luaL_len(L, idx) > 0) {
                    CFMutableArrayRef holder = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks) ;
                    for (lua_Integer i = 0 ; i < luaL_len(L, idx) ; i++) {
                        lua_geti(L, idx, i + 1) ;
                        CFTypeRef theVal = luaObjectToCFPropertyListRef(L, -1) ;
                        if (theVal && CFGetTypeID(theVal) != CFNullGetTypeID()) {
                            CFArrayAppendValue(holder, theVal) ;
                        } else {
                            [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - nil value at index %lld not supported in CFPropertyListRef array", USERDATA_TAG, i + 1]] ;
                            lua_pop(L, 1) ;
                            CFRelease(holder) ;
                            holder = NULL ;
                            break ;
                        }
                        if (theVal) CFRelease(theVal) ;
                        lua_pop(L, 1) ;
                    }
                    obj = holder ;
                } else {
                    CFMutableDictionaryRef holder = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks) ;
                    lua_pushnil(L) ;
                    while (lua_next(L, idx) != 0) {
                        if (lua_type(L, -2) == LUA_TSTRING) {
                            CFTypeRef theKey = CFStringCreateWithCString(kCFAllocatorDefault, lua_tostring(L, -2), kCFStringEncodingUTF8) ;
                            if (theKey) {
                                CFTypeRef theVal = luaObjectToCFPropertyListRef(L, -1) ;
                                if (theVal && CFGetTypeID(theVal) != CFNullGetTypeID()) {
                                    CFDictionarySetValue(holder, theKey, theVal) ;
                                } else {
                                    [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - nil value for key %@ not supported in CFPropertyListRef dictionary", USERDATA_TAG, (__bridge NSString *)theKey]] ;
                                    lua_pop(L, 2) ;
                                    CFRelease(theKey) ;
                                    CFRelease(holder) ;
                                    holder = NULL ;
                                    break ;
                                }
                                if (theKey) CFRelease(theKey) ;
                                if (theVal) CFRelease(theVal) ;
                            } else {
                                [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - key must be valid UTF8 string in CFPropertyListRef dictionary", USERDATA_TAG]] ;
                                lua_pop(L, 2) ;
                                CFRelease(holder) ;
                                holder = NULL ;
                                break ;
                            }
                        } else {
                            [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - key must be valid UTF8 string, not %s, in CFPropertyListRef dictionary", USERDATA_TAG, lua_typename(L, lua_type(L, -2))]] ;
                            lua_pop(L, 2) ;
                            CFRelease(holder) ;
                            holder = NULL ;
                            break ;
                        }
                        lua_pop(L, 1) ;
                    }
                    obj = holder ;
                }
            }
        } break ;
//         case LUA_TFUNCTION:
//         case LUA_TUSERDATA:
//         case LUA_TTHREAD:
//         case LUA_TLIGHTUSERDATA:
        default:
            [skin logWarn:[NSString stringWithFormat:@"%s:luaObjectToCFPropertyListRef - type %s not supported for conversion to CFPropertyListRef type", USERDATA_TAG, lua_typename(L, lua_type(L, idx))]] ;
            break ;
    }
    return obj ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"getValue",        cfpreferences_copyAppValue},
    {"getBoolean",      cfpreferences_getAppBooleanValue},
    {"getInteger",      cfpreferences_getAppIntegerValue},
    {"synchronize",     cfpreferences_appSynchronize},
    {"valueIsForced",   cfpreferences_appValueIsForced},
    {"keyList",         cfpreferences_copyKeyList},
    {"setValue",        cfpreferences_setAppValue},

    {"applicationList", cfpreferences_copyApplicationList},
    {"applicationMap",  cfpreferences_copyApplicationMap},
    {"flushCaches",     cfpreferences_flushCachesForIdentifier},

    {NULL,         NULL}
};

int luaopen_hs__asm_cfpreferences_internal(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

//     push_preferencesKeys(L) ; lua_setfield(L, -2, "predefinedKeys") ;

// should move this to hs.settings or hs.plist if this ends up in core
    // we're only doing the table to NSDate helper since LuaSkin already turns NSDate into a time number when going
    // the other way and it would break too many things to change that now... maybe if we do a fundamental rewrite
    [skin registerLuaObjectHelper:table_toNSDate forClass:"NSDate" withTableMapping:"NSDate"];
    // alternate input methods for NSData since LuaSkin already turns it into a lua string and changing would break
    // too many things
    [skin registerLuaObjectHelper:table_toNSData forClass:"NSData" withTableMapping:"NSData"];

    return 1;
}
