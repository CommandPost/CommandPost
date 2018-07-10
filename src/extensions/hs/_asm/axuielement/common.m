#import "common.h"

// keep this current with Hammerspoon's method for creating new hs.application and hs.window objects

// I *think* these will work with @cmsj's WIP updates to window/application/uielement

@protocol PlaceHoldersForInterim
- (id)initWithPid:(pid_t)pid ;
- (id)initWithAXUIElementRef:(AXUIElementRef)winRef ;
@end

extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out) ;

BOOL new_application(lua_State* L, pid_t pid) {
    Class HSA = NSClassFromString(@"HSapplication") ;
    if (HSA) {
        id obj = [[HSA alloc] initWithPid:pid] ;
        if (obj) {
            [[LuaSkin shared] pushNSObject:obj] ;
            return true ;
        } else {
            return false ;
        }
    } else {
        AXUIElementRef* appptr = lua_newuserdata(L, sizeof(AXUIElementRef));
        AXUIElementRef app = AXUIElementCreateApplication(pid);
        *appptr = app;

        if (!app) return false;

        luaL_getmetatable(L, "hs.application");
        lua_setmetatable(L, -2);

        lua_newtable(L);
        lua_pushinteger(L, pid);
        lua_setfield(L, -2, "pid");
        lua_setuservalue(L, -2);
        return true;
    }
}

void new_window(lua_State* L, AXUIElementRef win) {
    Class HSW = NSClassFromString(@"HSwindow") ;
    if (HSW) {
        id obj = [[HSW alloc] initWithAXUIElementRef:win] ;
        [[LuaSkin shared] pushNSObject:obj] ;
    } else {
        AXUIElementRef* winptr = lua_newuserdata(L, sizeof(AXUIElementRef));
        *winptr = win;

        luaL_getmetatable(L, "hs.window");
        lua_setmetatable(L, -2);

        lua_newtable(L);

        pid_t pid;
        if (AXUIElementGetPid(win, &pid) == kAXErrorSuccess) {
            lua_pushinteger(L, pid);
            lua_setfield(L, -2, "pid");
        }

        CGWindowID winid;
        AXError err = _AXUIElementGetWindow(win, &winid);
        if (!err) {
            lua_pushinteger(L, winid);
            lua_setfield(L, -2, "id");
        }

        lua_setuservalue(L, -2);
    }
}

// Not sure if the alreadySeen trick is working here, but it hasn't crashed yet... of course I don't think I've found any loops that don't have a userdata object in-between that drops us back to Lua before deciding whether or not to delve deeper, either, so... should be safe in CFDictionary and CFArray, since they toll-free bridge; don't use for others -- fails for setting with AXUIElementRef as key, at least...

// AXTextMarkerRef, and AXTextMarkerRangeRef mentioned as well, but private, so... no joy for now.
static int pushCFTypeHamster(lua_State *L, CFTypeRef theItem, NSMutableDictionary *alreadySeen, int refTable) {
    LuaSkin *skin = [LuaSkin shared] ;

    if (!theItem) {
        lua_pushnil(L) ;
        return 1 ;
    }

    CFTypeID theType = CFGetTypeID(theItem) ;
    if      (theType == CFArrayGetTypeID()) {
        if (alreadySeen[(__bridge id)theItem]) {
            [skin pushLuaRef:refTable ref:[alreadySeen[(__bridge id)theItem] intValue]] ;
            return 1 ;
        }
        lua_newtable(L) ;
        alreadySeen[(__bridge id)theItem] = [NSNumber numberWithInt:[skin luaRef:refTable]] ;
        [skin pushLuaRef:refTable ref:[alreadySeen[(__bridge id)theItem] intValue]] ; // put it back on the stack
        for(id thing in (__bridge NSArray *)theItem) {
            pushCFTypeHamster(L, (__bridge CFTypeRef)thing, alreadySeen, refTable) ;
            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
    } else if (theType == CFDictionaryGetTypeID()) {
        if (alreadySeen[(__bridge id)theItem]) {
            [skin pushLuaRef:refTable ref:[alreadySeen[(__bridge id)theItem] intValue]] ;
            return 1 ;
        }
        lua_newtable(L) ;
        alreadySeen[(__bridge id)theItem] = [NSNumber numberWithInt:[skin luaRef:refTable]] ;
        [skin pushLuaRef:refTable ref:[alreadySeen[(__bridge id)theItem] intValue]] ; // put it back on the stack
        NSArray *keys = [(__bridge NSDictionary *)theItem allKeys] ;
        NSArray *values = [(__bridge NSDictionary *)theItem allValues] ;
        for (unsigned long i = 0 ; i < [keys count] ; i++) {
            pushCFTypeHamster(L, (__bridge CFTypeRef)[keys objectAtIndex:i], alreadySeen, refTable) ;
            pushCFTypeHamster(L, (__bridge CFTypeRef)[values objectAtIndex:i], alreadySeen, refTable) ;
            lua_settable(L, -3) ;
        }
    } else if (theType == AXValueGetTypeID()) {
        AXValueType valueType = AXValueGetType((AXValueRef)theItem) ;
        if (valueType == kAXValueCGPointType) {
            CGPoint thePoint ;
            AXValueGetValue((AXValueRef)theItem, kAXValueCGPointType, &thePoint) ;
            lua_newtable(L) ;
              lua_pushnumber(L, thePoint.x) ; lua_setfield(L, -2, "x") ;
              lua_pushnumber(L, thePoint.y) ; lua_setfield(L, -2, "y") ;
        } else if (valueType == kAXValueCGSizeType) {
            CGSize theSize ;
            AXValueGetValue((AXValueRef)theItem, kAXValueCGSizeType, &theSize) ;
            lua_newtable(L) ;
              lua_pushnumber(L, theSize.height) ; lua_setfield(L, -2, "h") ;
              lua_pushnumber(L, theSize.width) ;  lua_setfield(L, -2, "w") ;
        } else if (valueType == kAXValueCGRectType) {
            CGRect theRect ;
            AXValueGetValue((AXValueRef)theItem, kAXValueCGRectType, &theRect) ;
            lua_newtable(L) ;
              lua_pushnumber(L, theRect.origin.x) ;    lua_setfield(L, -2, "x") ;
              lua_pushnumber(L, theRect.origin.y) ;    lua_setfield(L, -2, "y") ;
              lua_pushnumber(L, theRect.size.height) ; lua_setfield(L, -2, "h") ;
              lua_pushnumber(L, theRect.size.width) ;  lua_setfield(L, -2, "w") ;
        } else if (valueType == kAXValueCFRangeType) {
            CFRange theRange ;
            AXValueGetValue((AXValueRef)theItem, kAXValueCFRangeType, &theRange) ;
            lua_newtable(L) ;
              lua_pushinteger(L, theRange.location) ; lua_setfield(L, -2, "loc") ;
              lua_pushinteger(L, theRange.length) ;   lua_setfield(L, -2, "len") ;
        } else if (valueType == kAXValueAXErrorType) {
            AXError theError ;
            AXValueGetValue((AXValueRef)theItem, kAXValueAXErrorType, &theError) ;
            lua_newtable(L) ;
              lua_pushinteger(L, theError) ;                 lua_setfield(L, -2, "_code") ;
              lua_pushstring(L, AXErrorAsString(theError)) ; lua_setfield(L, -2, "error") ;
//         } else if (valueType == kAXValueIllegalType) {
        } else {
            lua_pushfstring(L, "unrecognized value type (%p)", theItem) ;
        }
    } else if (theType == CFAttributedStringGetTypeID()) {
        [skin pushNSObject:(__bridge NSAttributedString *)theItem] ;
    } else if (theType == CFNullGetTypeID()) {
        [skin pushNSObject:(__bridge NSNull *)theItem] ;
    } else if (theType == CFBooleanGetTypeID() || theType == CFNumberGetTypeID()) {
        [skin pushNSObject:(__bridge NSNumber *)theItem] ;
    } else if (theType == CFDataGetTypeID()) {
        [skin pushNSObject:(__bridge NSData *)theItem] ;
    } else if (theType == CFDateGetTypeID()) {
        [skin pushNSObject:(__bridge NSDate *)theItem] ;
    } else if (theType == CFStringGetTypeID()) {
        [skin pushNSObject:(__bridge NSString *)theItem] ;
    } else if (theType == CFURLGetTypeID()) {
        [skin pushNSObject:(__bridge_transfer NSString *)CFRetain(CFURLGetString(theItem))] ;
    } else if (theType == AXUIElementGetTypeID()) {
        pushAXUIElement(L, theItem) ;
    } else if (theType == AXObserverGetTypeID()) {
        pushAXObserver(L, theItem) ;
// Thought I'd found the missing framework, but apparently not
//     } else if (theType == wkGetAXTextMarkerTypeID()) {
//         lua_newtable(L) ;
//         struct TextMarkerData textMarkerData ;
//         BOOL valid = wkGetBytesFromAXTextMarker(theItem, &textMarkerData, sizeof(textMarkerData)) ;
//         lua_pushboolean(L, (BOOL)valid) ; lua_setfield(L, -2, "valid") ;
//         if (valid) {
//             lua_pushinteger(L, textMarkerData.axID) ; lua_setfield(L, -2, "axID") ;
// //             Node* node;
//             lua_pushinteger(L, textMarkerData.offset) ; lua_setfield(L, -2, "offset") ;
//             lua_pushinteger(L, textMarkerData.characterStartIndex) ; lua_setfield(L, -2, "characterStartIndex") ;
//             lua_pushinteger(L, textMarkerData.characterOffset) ; lua_setfield(L, -2, "characterOffset") ;
//             lua_pushboolean(L, textMarkerData.ignored) ; lua_setfield(L, -2, "ignored") ;
//             switch(textMarkerData.affinity) {
//                 case UPSTREAM:   lua_pushstring(L, "upstream") ; break ;
//                 case DOWNSTREAM: lua_pushstring(L, "downstream") ; break ;
//                 default:
//                     [skin pushNSObject:[NSString stringWithFormat:@"unrecognized affinity value:%d, notify developers", textMarkerData.affinity]] ;
//                     break ;
//             }
//             lua_setfield(L, -2, "affinity") ;
//         }
//     } else if (theType == wkGetAXTextMarkerRangeTypeID()) {
//         lua_newtable(L) ;
//         CFTypeRef startRange = wkCopyAXTextMarkerRangeStart(theItem) ;
//         pushCFTypeHamster(L, startRange, alreadySeen, refTable) ;
//         lua_setfield(L, -2, "start") ;
//         if (startRange) CFRelease(startRange) ;
//         CFTypeRef rangeEnd = wkCopyAXTextMarkerRangeEnd(theItem) ;
//         pushCFTypeHamster(L, rangeEnd, alreadySeen, refTable) ;
//         lua_setfield(L, -2, "end") ;
//         if (rangeEnd) CFRelease(rangeEnd) ;
    } else {
          NSString *typeLabel = [NSString stringWithFormat:@"unrecognized type: %lu", theType] ;
          [skin logDebug:[NSString stringWithFormat:@"%s:%@", USERDATA_TAG, typeLabel]];
          lua_pushstring(L, [typeLabel UTF8String]) ;
      }
    return 1 ;
}

// gets the count of items in a table irrespective of whether they are keyed or indexed
static lua_Integer countn (lua_State *L, int idx) {
  lua_Integer max = 0;
  luaL_checktype(L, idx, LUA_TTABLE);
  lua_pushnil(L);  /* first key */
  while (lua_next(L, idx)) {
    lua_pop(L, 1);  /* remove value */
    max++ ;
  }
  return max ;
}

// AXTextMarkerRef, and AXTextMarkerRangeRef mentioned as well, but private, so... no joy for now.
static CFTypeRef lua_toCFTypeHamster(lua_State *L, int idx, NSMutableDictionary *seen) {
    LuaSkin *skin = [LuaSkin shared] ;
    int index = lua_absindex(L, idx) ;

    CFTypeRef value = kCFNull ;

    if (seen[[NSValue valueWithPointer:lua_topointer(L, index)]]) {
        [skin logWarn:[NSString stringWithFormat:@"%s:multiple references to same table not currently supported for conversion", USERDATA_TAG]] ;
        return kCFNull ;
        // once I figure out (a) if we want to support this,
        //                   (b) if we should add a flag like we do for LuaSkin's NS version,
        //               and (c) the best way to store a CFTypeRef in an NSDictionary
        // value = CFRetain(pull CFTypeRef from @{seen}) ;
    } else if (lua_absindex(L, lua_gettop(L)) >= index) {
        int theType = lua_type(L, index) ;
        if (theType == LUA_TSTRING) {
            id holder = [skin toNSObjectAtIndex:index] ;
            if ([holder isKindOfClass:[NSString class]]) {
                value = (__bridge_retained CFStringRef)holder ;
            } else {
                value = (__bridge_retained CFDataRef)holder ;
            }
        } else if (theType == LUA_TBOOLEAN) {
            value = lua_toboolean(L, index) ? kCFBooleanTrue : kCFBooleanFalse ;
        } else if (theType == LUA_TNUMBER) {
            if (lua_isinteger(L, index)) {
                lua_Integer holder = lua_tointeger(L, index) ;
                value = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &holder) ;
            } else {
                lua_Number holder = lua_tonumber(L, index) ;
                value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &holder) ;
            }
        } else if (theType == LUA_TTABLE) {
        // rect, point, and size are regularly tables in Hammerspoon, differentiated by which of these
        // keys are present.
            BOOL hasX      = (lua_getfield(L, index, "x")        != LUA_TNIL) ; lua_pop(L, 1) ;
            BOOL hasY      = (lua_getfield(L, index, "y")        != LUA_TNIL) ; lua_pop(L, 1) ;
            BOOL hasH      = (lua_getfield(L, index, "h")        != LUA_TNIL) ; lua_pop(L, 1) ;
            BOOL hasW      = (lua_getfield(L, index, "w")        != LUA_TNIL) ; lua_pop(L, 1) ;
        // objc-style indexing for range
            BOOL hasLoc    = (lua_getfield(L, index, "location") != LUA_TNIL) ; lua_pop(L, 1) ;
            BOOL hasLen    = (lua_getfield(L, index, "length")   != LUA_TNIL) ; lua_pop(L, 1) ;
        // lua-style indexing for range
            BOOL hasStarts = (lua_getfield(L, index, "starts")   != LUA_TNIL) ; lua_pop(L, 1) ;
            BOOL hasEnds   = (lua_getfield(L, index, "ends")     != LUA_TNIL) ; lua_pop(L, 1) ;
        // AXError type
            BOOL hasError  = (lua_getfield(L, index, "_code")    != LUA_TNIL) ; lua_pop(L, 1) ;
        // since date is just a number or string, we'll have to make it a "psuedo" table so that it can
        // be uniquely specified on the lua side
            BOOL hasDate   = (lua_getfield(L, index, "_date")    != LUA_TNIL) ; lua_pop(L, 1) ;
        // since url is just a string, we'll have to make it a "psuedo" table so that it can be uniquely
        // specified on the lua side
            BOOL hasURL    = (lua_getfield(L, index, "_URL")     != LUA_TNIL) ; lua_pop(L, 1) ;

            if (hasX && hasY && hasH && hasW) { // CGRect
                lua_getfield(L, index, "x") ;
                lua_getfield(L, index, "y") ;
                lua_getfield(L, index, "w") ;
                lua_getfield(L, index, "h") ;
                CGRect holder = CGRectMake(luaL_checknumber(L, -4), luaL_checknumber(L, -3), luaL_checknumber(L, -2), luaL_checknumber(L, -1)) ;
                value = AXValueCreate(kAXValueCGRectType, &holder) ;
                lua_pop(L, 4) ;
            } else if (hasX && hasY) {          // CGPoint
                lua_getfield(L, index, "x") ;
                lua_getfield(L, index, "y") ;
                CGPoint holder = CGPointMake(luaL_checknumber(L, -2), luaL_checknumber(L, -1)) ;
                value = AXValueCreate(kAXValueCGPointType, &holder) ;
                lua_pop(L, 2) ;
            } else if (hasH && hasW) {          // CGSize
                lua_getfield(L, index, "w") ;
                lua_getfield(L, index, "h") ;
                CGSize holder = CGSizeMake(luaL_checknumber(L, -2), luaL_checknumber(L, -1)) ;
                value = AXValueCreate(kAXValueCGSizeType, &holder) ;
                lua_pop(L, 2) ;
            } else if (hasLoc && hasLen) {      // CFRange objc style
                lua_getfield(L, index, "location") ;
                lua_getfield(L, index, "length") ;
                CFRange holder = CFRangeMake(luaL_checkinteger(L, -2), luaL_checkinteger(L, -1)) ;
                value = AXValueCreate(kAXValueCFRangeType, &holder) ;
                lua_pop(L, 2) ;
            } else if (hasStarts && hasEnds) {  // CFRange lua style
// NOTE: Negative indexes and UTF8 as bytes can't be handled here without context.
//       Maybe on lua side in wrapper functions?
                lua_getfield(L, index, "starts") ;
                lua_getfield(L, index, "ends") ;
                lua_Integer starts = luaL_checkinteger(L, -2) ;
                lua_Integer ends   = luaL_checkinteger(L, -1) ;
                CFRange holder = CFRangeMake(starts - 1, ends + 1 - starts) ;
                value = AXValueCreate(kAXValueCFRangeType, &holder) ;
                lua_pop(L, 2) ;
            } else if (hasError) {              // AXError
                lua_getfield(L, index, "_code") ;
                AXError holder = (AXError)(unsigned long long)luaL_checkinteger(L, -1) ;
                value = AXValueCreate(kAXValueAXErrorType, &holder) ;
                lua_pop(L, 1) ;
            } else if (hasURL) {                // CFURL
                lua_getfield(L, index, "_url") ;
                value = CFURLCreateWithString(kCFAllocatorDefault, (__bridge CFStringRef)[skin toNSObjectAtIndex:-1], NULL) ;
                lua_pop(L, 1) ;
            } else if (hasDate) {               // CFDate
                int dateType = lua_getfield(L, index, "_date") ;
                if (dateType == LUA_TNUMBER) {
                    value = CFDateCreate(kCFAllocatorDefault, [[NSDate dateWithTimeIntervalSince1970:lua_tonumber(L, -1)] timeIntervalSinceReferenceDate]) ;
                } else if (dateType == LUA_TSTRING) {
                    // rfc3339 (Internet Date/Time) formated date.  More or less.
                    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init] ;
                    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] ;
                    [rfc3339DateFormatter setLocale:enUSPOSIXLocale] ;
                    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"] ;
                    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]] ;
                    value = (__bridge_retained CFDateRef)[rfc3339DateFormatter dateFromString:[skin toNSObjectAtIndex:-1]] ;
                } else {
                    lua_pop(L, 1) ;
                    [skin logError:[NSString stringWithFormat:@"%s:invalid date format specified for conversion", USERDATA_TAG]] ;
                    return kCFNull ;
                }
                lua_pop(L, 1) ;
            } else {                            // real CFDictionary or CFArray
              seen[[NSValue valueWithPointer:lua_topointer(L, index)]] = @(YES) ;
              if (luaL_len(L, index) == countn(L, index)) { // CFArray
                  CFMutableArrayRef holder = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks) ;
                  for (lua_Integer i = 0 ; i < luaL_len(L, index) ; i++ ) {
                      lua_geti(L, index, i + 1) ;
                      CFTypeRef theVal = lua_toCFTypeHamster(L, -1, seen) ;
                      CFArrayAppendValue(holder, theVal) ;
                      if (theVal) CFRelease(theVal) ;
                      lua_pop(L, 1) ;
                  }
                  value = holder ;
              } else {                                      // CFDictionary
                  CFMutableDictionaryRef holder = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks) ;
                  lua_pushnil(L) ;
                  while (lua_next(L, index) != 0) {
                      CFTypeRef theKey = lua_toCFTypeHamster(L, -2, seen) ;
                      CFTypeRef theVal = lua_toCFTypeHamster(L, -1, seen) ;
                      CFDictionarySetValue(holder, theKey, theVal) ;
                      if (theKey) CFRelease(theKey) ;
                      if (theVal) CFRelease(theVal) ;
                      lua_pop(L, 1) ;
                  }
                  value = holder ;
              }
            }
        } else if (theType == LUA_TUSERDATA) {
            if (luaL_testudata(L, index, "hs.styledtext")) {
                value = (__bridge_retained CFAttributedStringRef)[skin toNSObjectAtIndex:index] ;
            } else if (luaL_testudata(L, index, USERDATA_TAG)) {
                value = CFRetain(get_axuielementref(L, index, USERDATA_TAG)) ;
            } else if (luaL_testudata(L, index, OBSERVER_TAG)) {
                value = CFRetain(get_axobserverref(L, index, OBSERVER_TAG)) ;
            } else {
//                 lua_pop(L, 1) ; <-- I think this is an error
                [skin logError:[NSString stringWithFormat:@"%s:unrecognized userdata is not supported for conversion", USERDATA_TAG]] ;
                return kCFNull ;
            }
        } else if (theType != LUA_TNIL) { // value already set to kCFNull, no specific match necessary
//             lua_pop(L, 1) ; <-- I think this is an error
            [skin logError:[NSString stringWithFormat:@"%s:type %s not supported for conversion", USERDATA_TAG, lua_typename(L, theType)]] ;
            return kCFNull ;
        }
    }
    return value ;
}

int pushCFTypeToLua(lua_State *L, CFTypeRef theItem, int refTable) {
    LuaSkin *skin = [LuaSkin shared];
    NSMutableDictionary *alreadySeen = [[NSMutableDictionary alloc] init] ;
    pushCFTypeHamster(L, theItem, alreadySeen, refTable) ;
    for (id entry in alreadySeen) {
        [skin luaUnref:refTable ref:[alreadySeen[entry] intValue]] ;
    }
    return 1 ;
}

CFTypeRef lua_toCFType(lua_State *L, int idx) {
    NSMutableDictionary *seen = [[NSMutableDictionary alloc] init] ;
    return lua_toCFTypeHamster(L, idx, seen) ;
}
