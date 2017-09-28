@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.datepicker" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#define DATEPICKER_STYLES @{                                          \
    @"textFieldAndStepper" : @(NSTextFieldAndStepperDatePickerStyle), \
    @"clockAndCalendar"    : @(NSClockAndCalendarDatePickerStyle),    \
    @"textField"           : @(NSTextFieldDatePickerStyle),           \
}

#pragma mark - Support Functions and Classes

@interface HSASMGUITKElementDatePicker : NSDatePicker <NSDatePickerCellDelegate>
@property int selfRefCount ;
@property int callbackRef ;
@end

@implementation HSASMGUITKElementDatePicker

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect] ;
    if (self) {
        _callbackRef  = LUA_NOREF ;
        _selfRefCount = 0 ;
        self.target   = self ;
        self.action   = @selector(performCallback:) ;
        self.delegate = self ;
    }
    return self ;
}

- (void)callbackHamster:(NSArray *)messageParts { // does the "heavy lifting"
    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        [skin pushLuaRef:refTable ref:_callbackRef] ;
        for (id part in messageParts) [skin pushNSObject:part] ;
        if (![skin protectedCallAndTraceback:(int)messageParts.count nresults:0]) {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            lua_pop(skin.L, 1) ;
            [skin logError:[NSString stringWithFormat:@"%s:callback error:%@", USERDATA_TAG, errorMessage]] ;
        }
    } else {
        // allow next responder a chance since we don't have a callback set
        id nextInChain = [self nextResponder] ;
        if (nextInChain) {
            SEL passthroughCallback = NSSelectorFromString(@"preformPassthroughCallback:") ;
            if ([nextInChain respondsToSelector:passthroughCallback]) {
                [nextInChain performSelectorOnMainThread:passthroughCallback
                                              withObject:messageParts
                                           waitUntilDone:YES] ;
            }
        }
    }
}

- (void)performCallback:(__unused id)sender {
    [self callbackHamster:@[ self ]] ;
}

// - (void)datePickerCell:(NSDatePickerCell *)datePickerCell validateProposedDateValue:(NSDate * _Nonnull *)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval {
// }

@end

#pragma mark - Module Functions

static int datepicker_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementDatePicker *picker = [[HSASMGUITKElementDatePicker alloc] initWithFrame:frameRect];
    if (picker) {
        if (lua_gettop(L) != 1) [picker setFrameSize:[picker fittingSize]] ;
        [skin pushNSObject:picker] ;
    } else {
        lua_pushnil(L) ;
    }

    return 1 ;
}

#pragma mark - Module Methods

static int datepicker_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        picker.callbackRef = [skin luaUnref:refTable ref:picker.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            picker.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (picker.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:picker.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int datepicker_bordered(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, picker.bordered) ;
    } else {
        picker.bordered = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_bezeled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, picker.bezeled) ;
    } else {
        picker.bezeled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_drawsBackground(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, picker.drawsBackground) ;
    } else {
        picker.drawsBackground = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_backgroundColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:picker.backgroundColor] ;
    } else {
        picker.backgroundColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_textColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:picker.textColor] ;
    } else {
        picker.textColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_datePickerMode(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, (picker.datePickerMode == NSRangeDateMode)) ;
    } else {
        picker.datePickerMode = (lua_toboolean(L, 2) ? NSRangeDateMode : NSSingleDateMode) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_datePickerStyle(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *datePickerStyle = @(picker.datePickerStyle) ;
        NSArray *temp = [DATEPICKER_STYLES allKeysForObject:datePickerStyle];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized image position %@ -- notify developers", USERDATA_TAG, datePickerStyle]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *datePickerStyle = DATEPICKER_STYLES[key] ;
        if (datePickerStyle) {
            picker.datePickerStyle = [datePickerStyle unsignedIntegerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[DATEPICKER_STYLES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

static int datepicker_datePickerElements(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSDatePickerElementFlags flags = picker.datePickerElements ;
        lua_newtable(L) ;
        if ((flags & NSHourMinuteSecondDatePickerElementFlag) == NSHourMinuteSecondDatePickerElementFlag) {
            lua_pushstring(L, "HMS") ;
        } else if ((flags & NSHourMinuteDatePickerElementFlag) == NSHourMinuteDatePickerElementFlag) {
            lua_pushstring(L, "HM") ;
        } else {
            lua_pushstring(L, "off") ;
        }
        lua_setfield(L, -2, "timeElement") ;
        lua_pushboolean(L, ((flags & NSTimeZoneDatePickerElementFlag) == NSTimeZoneDatePickerElementFlag)) ;
        lua_setfield(L, -2, "includeTimeZone") ;
        if ((flags & NSYearMonthDayDatePickerElementFlag) == NSYearMonthDayDatePickerElementFlag) {
            lua_pushstring(L, "YMD") ;
        } else if ((flags & NSYearMonthDatePickerElementFlag) == NSYearMonthDatePickerElementFlag) {
            lua_pushstring(L, "YM") ;
        } else {
            lua_pushstring(L, "off") ;
        }
        lua_setfield(L, -2, "dateElement") ;
        lua_pushboolean(L, ((flags & NSEraDatePickerElementFlag) == NSEraDatePickerElementFlag)) ;
        lua_setfield(L, -2, "includeEra") ;
    } else {
        NSDatePickerElementFlags flags = (NSDatePickerElementFlags)0 ;
        if (lua_getfield(L, 2, "timeElement") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if ([value isEqualToString:@"HMS"]) {
                flags |= NSHourMinuteSecondDatePickerElementFlag ;
            } else if ([value isEqualToString:@"HM"]) {
                flags |= NSHourMinuteDatePickerElementFlag ;
            } else if (![value isEqualToString:@"off"]) {
                return luaL_argerror(L, 2, "expected HMS, HM, or off for timeElement key") ;
            }
        } else if (lua_type(L, -1) != LUA_TNIL) {
            return luaL_argerror(L, 2, "expected string value for timeElement key") ;
        }
        lua_pop(L, 1) ;
        if (lua_getfield(L, 2, "dateElement") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if ([value isEqualToString:@"YMD"]) {
                flags |= NSYearMonthDayDatePickerElementFlag ;
            } else if ([value isEqualToString:@"YM"]) {
                flags |= NSYearMonthDatePickerElementFlag ;
            } else if (![value isEqualToString:@"off"]) {
                return luaL_argerror(L, 2, "expected YMD, YM, or off for dateElement key") ;
            }
        } else if (lua_type(L, -1) != LUA_TNIL) {
            return luaL_argerror(L, 2, "expected string value for dateElement key") ;
        }
        lua_pop(L, 1) ;
        if (lua_getfield(L, 2, "includeTimeZone") == LUA_TBOOLEAN) {
            if (lua_toboolean(L, -1)) flags |= NSTimeZoneDatePickerElementFlag ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            return luaL_argerror(L, 2, "expected boolean value for inclueTimeZone key") ;
        }
        lua_pop(L, 1) ;
        if (lua_getfield(L, 2, "includeEra") == LUA_TBOOLEAN) {
            if (lua_toboolean(L, -1)) flags |= NSEraDatePickerElementFlag ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            return luaL_argerror(L, 2, "expected boolean value for includeEra key") ;
        }
        lua_pop(L, 1) ;
        picker.datePickerElements = flags ;
    }
    return 1 ;
}

static int datepicker_locale(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:[picker.locale localeIdentifier]] ;
    } else {
        NSLocale *locale = (lua_type(L, 2) == LUA_TNIL) ? [NSLocale currentLocale] : [NSLocale localeWithLocaleIdentifier:[skin toNSObjectAtIndex:2]] ;
        if (locale) {
            picker.locale = locale ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"invalid locale '%@' specified", [skin toNSObjectAtIndex:2]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_timezone(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNUMBER | LS_TINTEGER | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:[picker.timeZone name]] ;
    } else {
        NSTimeZone *newTimeZone ;
        switch(lua_type(L, 2)) {
            case LUA_TNUMBER: {
                newTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:lua_tointeger(L, 2)] ;
            } break ;
            case LUA_TNIL: {
                newTimeZone = [NSTimeZone defaultTimeZone] ;
            } break ;
            case LUA_TSTRING: {
                NSString *label = [skin toNSObjectAtIndex:2] ;
                newTimeZone = [NSTimeZone timeZoneWithName:label] ;
                if (!newTimeZone) newTimeZone = [NSTimeZone timeZoneWithAbbreviation:label] ;
                if (!newTimeZone) return luaL_argerror(L, 2, [[NSString stringWithFormat:@"unrecognized timezone label '%@'", label] UTF8String]) ;
            } break ;
        }
        picker.timeZone = newTimeZone ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_calendar(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING  | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:[picker.calendar calendarIdentifier]] ;
    } else {
        NSCalendar *calendar = (lua_type(L, 2) == LUA_TNIL) ? [NSCalendar currentCalendar] : [NSCalendar calendarWithIdentifier:[skin toNSObjectAtIndex:2]] ;
        if (calendar) {
            picker.calendar = calendar ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"invalid calendar '%@' specified", [skin toNSObjectAtIndex:2]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_timeInterval(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, picker.timeInterval) ;
    } else {
        picker.timeInterval = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_dateValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSDate *date = picker.dateValue ;
        if (date) {
            lua_pushnumber(L, date.timeIntervalSince1970) ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        picker.dateValue = [NSDate dateWithTimeIntervalSince1970:lua_tonumber(L, 2)] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_maxDate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSDate *date = picker.maxDate ;
        if (date) {
            lua_pushnumber(L, date.timeIntervalSince1970) ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            picker.maxDate = nil ;
        } else {
            picker.maxDate = [NSDate dateWithTimeIntervalSince1970:lua_tonumber(L, 2)] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int datepicker_minDate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementDatePicker *picker = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSDate *date = picker.minDate ;
        if (date) {
            lua_pushnumber(L, date.timeIntervalSince1970) ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            picker.minDate = nil ;
        } else {
            picker.minDate = [NSDate dateWithTimeIntervalSince1970:lua_tonumber(L, 2)] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

// @property(copy) NSDate *dateValue;
// @property(copy) NSDate *maxDate;
// @property(copy) NSDate *minDate;

#pragma mark - Module Constants

static int pushCalendarIdentifiers(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    [skin pushNSObject:NSCalendarIdentifierGregorian] ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierBuddhist] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierChinese] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierCoptic] ;              lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierEthiopicAmeteMihret] ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierEthiopicAmeteAlem] ;   lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierHebrew] ;              lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierISO8601] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierIndian] ;              lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierIslamic] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierIslamicCivil] ;        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierJapanese] ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierPersian] ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierRepublicOfChina] ;     lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierIslamicTabular] ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    [skin pushNSObject:NSCalendarIdentifierIslamicUmmAlQura] ;    lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementDatePicker(lua_State *L, id obj) {
    HSASMGUITKElementDatePicker *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementDatePicker *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementDatePickerFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementDatePicker *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementDatePicker, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementDatePicker *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementDatePicker"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementDatePicker *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementDatePicker"] ;
        HSASMGUITKElementDatePicker *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementDatePicker"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementDatePicker *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementDatePicker, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            obj = nil ;
        }
    }
    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"callback",        datepicker_callback},
    {"drawsBackground", datepicker_drawsBackground},
    {"bordered",        datepicker_bordered},
    {"bezeled",         datepicker_bezeled},
    {"backgroundColor", datepicker_backgroundColor},
    {"textColor",       datepicker_textColor},
    {"dateRangeMode",   datepicker_datePickerMode},
    {"pickerStyle",     datepicker_datePickerStyle},
    {"pickerElements",  datepicker_datePickerElements},
    {"locale",          datepicker_locale},
    {"timezone",        datepicker_timezone},
    {"calendar",        datepicker_calendar},
    {"timeInterval",    datepicker_timeInterval},
    {"date",            datepicker_dateValue},
    {"maxDate",         datepicker_maxDate},
    {"minDate",         datepicker_minDate},

    {"__tostring",      userdata_tostring},
    {"__eq",            userdata_eq},
    {"__gc",            userdata_gc},
    {NULL,              NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", datepicker_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_element_datepicker(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementDatePicker         forClass:"HSASMGUITKElementDatePicker"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementDatePickerFromLua forClass:"HSASMGUITKElementDatePicker"
                                                       withUserdataMapping:USERDATA_TAG];

    pushCalendarIdentifiers(L) ; lua_setfield(L, -2, "calendarIdentifiers") ;

    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"callback",
        @"drawsBackground",
        @"bordered",
        @"bezeled",
        @"backgroundColor",
        @"textColor",
        @"dateRangeMode",
        @"pickerStyle",
        @"pickerElements",
        @"locale",
        @"timezone",
        @"calendar",
        @"timeInterval",
        @"date",
        @"minDate",
        @"maxDate",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritController") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
