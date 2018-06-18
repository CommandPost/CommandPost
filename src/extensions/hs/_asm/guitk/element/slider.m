
/// === hs._asm.guitk.element.slider ===
///
/// Provides a slider element for use with `hs._asm.guitk`. Sliders are horizontal or vertical bars representing a range of numeric values which can be selected by adjusting the position of the knob on the slider.
///
/// * This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.slider" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

@interface HSASMGUITKElementSlider : NSSlider
@property int selfRefCount ;
@property int callbackRef ;
@end

@implementation HSASMGUITKElementSlider

- (instancetype)initWithFrame:(NSRect)frameRect {
    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _callbackRef    = LUA_NOREF ;
        _selfRefCount   = 0 ;

        self.target     = self ;
        self.action     = @selector(performCallback:) ;
        self.continuous = false ;
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
            SEL passthroughCallback = NSSelectorFromString(@"performPassthroughCallback:") ;
            if ([nextInChain respondsToSelector:passthroughCallback]) {
                [nextInChain performSelectorOnMainThread:passthroughCallback
                                              withObject:messageParts
                                           waitUntilDone:YES] ;
            }
        }
    }
}

- (void)performCallback:(__unused id)sender {
    [self callbackHamster:@[ self, @(self.doubleValue) ]] ;
}

@end

#pragma mark - Module Functions

/// hs._asm.guitk.element.slider.new([frame]) -> sliderObject
/// Constructor
/// Creates a new slider element for `hs._asm.guitk`.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for the element.
///
/// Returns:
///  * the sliderObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
static int slider_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementSlider *slider = [[HSASMGUITKElementSlider alloc] initWithFrame:frameRect];
    if (slider) {
        if (lua_gettop(L) != 1) [slider setFrameSize:[slider fittingSize]] ;
        [skin pushNSObject:slider] ;
    } else {
        lua_pushnil(L) ;
    }

    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk.element.slider:callback([fn | nil]) -> sliderObject | fn | nil
/// Method
/// Get or set the callback function which will be invoked whenever the user clicks on the slider element.
///
/// Parameters:
///  * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user clicks on the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * The slider callback will receive two arguments and should return none. The arguments will be the sliderObject userdata and the value represented by the sliders new position -- see [hs._asm.guitk.element.slider:value](#value)
static int slider_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        slider.callbackRef = [skin luaUnref:refTable ref:slider.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            slider.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (slider.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:slider.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:tickMarksOnly([state]) -> sliderObject | boolean
/// Method
/// Get or set whether the slider limits values to those specified by tick marks or allows selecting a value between tick marks.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the slider is limited to discrete values indicated by the tick marks (true) or allows values in between as well (false).
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * has no effect if [hs._asm.guitk.element.slider:tickMarks](#tickMarks) is 0
static int slider_allowsTickMarkValuesOnly(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, slider.allowsTickMarkValuesOnly) ;
    } else {
        slider.allowsTickMarkValuesOnly = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:altClickIncrement([value]) -> sliderObject | number
/// Method
/// Get or set the amount the slider will move if the user holds down the alt (option) key while clicking on it.
///
/// Parameters:
///  * `value` - an optional number greater than or equal to 0 specifying the amount the slider will move when the user holds down the alt (option) key while clicking on it.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * If this value is 0, holding down the alt (option) key while clicking on the slider has the same effect that not holding down the modifier does: the slider jumps to the position where the click occurs.
static int slider_altIncrementValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, slider.altIncrementValue) ;
    } else {
        lua_Number value = lua_tonumber(L, 2) ;
        slider.altIncrementValue = (value < 0) ? 0 : value ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:value([value]) -> sliderObject | number
/// Method
/// Get or set the current value of the slider, adjusting the knob position if necessary.
///
/// Parameters:
///  * `value` - an optional number specifying the value for the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * If the value is less than [hs._asm.guitk.element.slider:min](#min), then it will be set to the minimum instead.
///  * If the value is greater than [hs._asm.guitk.element.slider:max](#max), then it will be set to the maximum instead.
static int slider_currentValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, slider.doubleValue) ;
    } else {
        slider.doubleValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return  1 ;
}

/// hs._asm.guitk.element.slider:max([value]) -> sliderObject | number
/// Method
/// Get or set the maximum value the slider can represent.
///
/// Parameters:
///  * `value` - an optional number (default 1.0) specifying the maximum value for the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * If this value is less than [hs._asm.guitk.element.slider:min](#min), the behavior of the slider is undefined.
static int slider_maxValuee(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, slider.maxValue) ;
    } else {
        slider.maxValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:min([value]) -> sliderObject | number
/// Method
/// Get or set the minimum value the slider can represent.
///
/// Parameters:
///  * `value` - an optional number (default 0.0) specifying the minimum value for the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * If this value is greater than [hs._asm.guitk.element.slider:max](#max), the behavior of the slider is undefined.
static int slider_minValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, slider.minValue) ;
    } else {
        slider.minValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:tickMarks([marks]) -> sliderObject | integer
/// Method
/// Get or set the number of tick marks for the slider.
///
/// Parameters:
///  * `marks` - an optional integer (default 0) specifying the number of tick marks for the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * If the slider is linear, the tick marks will be arranged at equal intervals along the slider. If the slider is circular, a single tick mark will be displayed at the top of the slider for any number passed in that is greater than 0 -- see [hs._asm.guitk.element.slider:type](#type).
///  * A circular slider with [hs._asm.guitk.element.slider:tickMarksOnly](#tickMarksOnly) set to true will still be limited to the number of discrete intervals specified by the value set by this method, even though the specific tick marks are not visible.
static int slider_numberOfTickMarks(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, slider.numberOfTickMarks) ;
    } else {
        NSInteger marks = lua_tointeger(L, 2) ;
        slider.numberOfTickMarks = (marks < 0) ? 0 : marks ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:type([type]) -> sliderObject | string
/// Method
/// Get or set whether the slider is linear or circular.
///
/// Parameters:
///  * `type` - an optional string, default "linear", specifying whether the slider is circular ("circular") or linear ("linear")
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * The length of a linear slider will expand to fill the dimension appropriate based on the value of [hs._asm.guitk.element.slider:vertical](#vertical); a circular slider will be anchored to the lower right corner of the element's frame.
static int slider_sliderType(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        switch(slider.sliderType) {
            case NSSliderTypeCircular:
                lua_pushstring(L, "circular") ;
                break ;
            case NSSliderTypeLinear:
                lua_pushstring(L, "linear") ;
                break ;
            default:
                lua_pushstring(L, [[NSString stringWithFormat:@"unrecognized sliderType:%lu", slider.sliderType] UTF8String]) ;
                break ;
        }
    } else {
        NSString *position = [skin toNSObjectAtIndex:2] ;
        if ([position isEqualToString:@"circular"]) {
            slider.sliderType = NSSliderTypeCircular ;
        } else if ([position isEqualToString:@"linear"]) {
            slider.sliderType = NSSliderTypeLinear ;
        } else {
            luaL_argerror(L, 2, "expected circular or linear") ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:tickMarkLocation([location]) -> sliderObject | string
/// Method
/// Get or set where tick marks are displayed for the slider.
///
/// Parameters:
///  * `location` - an optional string, default "trailing", specifying whether the tick marks are displayed to the left/below ("trailing") the slider or to the right/above ("leading") the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * This method has no effect on a circular slider -- see [hs._asm.guitk.element.slider:type](#type).
///  * If [hs._asm.guitk.element.slider:tickMarks](#tickMarks) is 0, this method has no effect.
static int slider_tickMarkPosition(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        switch(slider.tickMarkPosition) {
//             case NSTickMarkPositionAbove:
            case NSTickMarkPositionLeading:
                lua_pushstring(L, "leading") ;
                break ;
//             case NSTickMarkPositionBelow:
            case NSTickMarkPositionTrailing:
                lua_pushstring(L, "trailing") ;
                break ;
            default:
                lua_pushstring(L, [[NSString stringWithFormat:@"unrecognized tickMarkPosition:%lu", slider.tickMarkPosition] UTF8String]) ;
                break ;
        }
    } else {
        NSString *position = [skin toNSObjectAtIndex:2] ;
        if ([position isEqualToString:@"leading"]) {
            slider.tickMarkPosition = NSTickMarkPositionLeading ;
        } else if ([position isEqualToString:@"trailing"]) {
            slider.tickMarkPosition = NSTickMarkPositionTrailing ;
        } else {
            luaL_argerror(L, 2, "expected leading or trailing") ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:trackFillColor([color]) -> sliderObject | table
/// Method
/// Get or set the color of the slider track in appearances that support it.
///
/// Parameters:
///  * `color` - a color table as defined in `hs.drawing.color`, or explicit nil to reset to the default, specifying the color of the track for the slider.
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * This method is only available in macOS 10.12.1 and newer.
///  * This method currently appears to have no effect on the visual appearance on the slider; as it was added to the macOS API in 10.12.1, it is suspected that this may be supported in the future and is included here for when that happens.
static int slider_trackFillColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        if ([slider respondsToSelector:NSSelectorFromString(@"trackFillColor")]) {
            [skin pushNSObject:slider.trackFillColor] ;
        } else {
            lua_pushnil(L) ;
        }
#pragma clang diagnostic pop
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        if ([slider respondsToSelector:NSSelectorFromString(@"trackFillColor")]) {
            if (lua_type(L, 2) == LUA_TNIL) {
                slider.trackFillColor = nil ;
            } else {
                slider.trackFillColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
            }
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:trackFillColor - requries macOS 10.12.1 or later", USERDATA_TAG]] ;
        }
#pragma clang diagnostic pop
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.slider:knobThickness() -> number
/// Method
/// Get the thickness of the knob on the slider.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a number specifying the thickness of the slider's knob in pixels.
///
/// Notes:
///  * The thickness is defined to be the extent of the knob along the long dimension of the bar. In a vertical slider, a knob’s thickness is its height; in a horizontal slider, a knob’s thickness is its width.
static int slider_knobThickness(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    lua_pushnumber(L, slider.knobThickness) ;
    return 1 ;
}

/// hs._asm.guitk.element.slider:vertical([state]) -> sliderObject | boolean
/// Method
/// Get or set whether a linear slider is vertical or horizontal.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not a linear slider is vertical (true) or horizontal (false).
///
/// Returns:
///  * if a value is provided, returns the sliderObject ; otherwise returns the current value.
///
/// Notes:
///  * This method has no effect on a circular slider -- see [hs._asm.guitk.element.slider:type](#type).
static int slider_vertical(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

// TODO: Test in 10.10 -- docs say this has been valid since 10.0, but the compiler disagrees
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, slider.vertical) ;
    } else {
        slider.vertical = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
#pragma clang diagnostic pop
    return 1 ;
}

/// hs._asm.guitk.element.slider:tickMarkValue(mark) -> number
/// Method
/// Get the value represented by the specified tick mark.
///
/// Parameters:
///  * `mark` - an integer, between 1 and [hs._asm.guitk.element.slider:tickMarks](#tickMarks), specifying the tick mark to get the slider value of.
///
/// Returns:
///  * the number represented by the specified tick mark.
static int slider_tickMarkValueAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;
    lua_Integer index = lua_tointeger(L, 2) ;

    NSInteger numberOfTickMarks = slider.numberOfTickMarks ;
    if (index < 1 || index > numberOfTickMarks) {
        if (numberOfTickMarks > 0) {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index must be between 1 and %ld", numberOfTickMarks] UTF8String]) ;
        } else {
            return luaL_argerror(L, 2, "slider does not have any tick marks") ;
        }
    }
    lua_pushnumber(L, [slider tickMarkValueAtIndex:index - 1]) ;
    return 1 ;
}

/// hs._asm.guitk.element.slider:closestTickMarkValue(value) -> number
/// Method
/// Get the value of the tick mark closest to the specified value.
///
/// Parameters:
///  * `value` - the number to find the closest tick mark to.
///
/// Returns:
///  * the number represented by the tick mark closest to the value provided to this method.
///
/// Notes:
///  * Returns `value` if the slider has no tick marks
///  * See also [hs._asm.guitk.element.slider:closestTickMark](#closestTickMark)
static int slider_closestTickMarkValueToValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    lua_pushnumber(L, [slider closestTickMarkValueToValue:lua_tonumber(L, 2)]) ;
    return 1 ;
}

/// hs._asm.guitk.element.slider:closestTickMark(value) -> integer
/// Method
/// Get the index of the tick mark closest to the specified value.
///
/// Parameters:
///  * `value` - the number to find the closest tick mark to.
///
/// Returns:
///  * the index of the the tick mark closest to the value provided to this method.
///
/// Notes:
///  * Returns 0 if the slider has no tick marks
///  * See also [hs._asm.guitk.element.slider:closestTickMarkValue](#closestTickMarkValue)
static int slider_closestTickMarkToValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;
    double value = [slider closestTickMarkValueToValue:lua_tonumber(L, 2)] ;

    NSInteger matchIndex = 0 ;
    NSInteger tickMarks = slider.numberOfTickMarks ;
    if (tickMarks == 1) {
        matchIndex = 1 ;
    } else {
        // c abhors checking doubles for equality, so check if difference is < 1/2 the difference
        // between tick marks instead
        double delta = (slider.maxValue - slider.minValue) / (2 * (tickMarks - 1)) ;

        for (NSInteger i = 0 ; i < tickMarks ; i++) {
            if (fabs(value - [slider tickMarkValueAtIndex:i]) < delta) {
                matchIndex = i + 1 ;
                break ;
            }
        }
    }
    lua_pushinteger(L, matchIndex) ;
    return 1 ;
}

/// hs._asm.guitk.element.slider:rectOfTickMark(index) -> table
/// Method
/// Get the frame table of the tick mark at the specified index
///
/// Parameters:
///  * `index` - an integer specifying the index of the tick mark to get the frame of
///
/// Returns:
///  * a frame table specifying the tick mark's location within the element's frame. The frame coordinates will be relative to the top left corner of the slider's frame in it's parent.
static int slider_rectOfTickMarkAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;
    lua_Integer index = lua_tointeger(L, 2) ;

    NSInteger numberOfTickMarks = slider.numberOfTickMarks ;
    if (index < 1 || index > numberOfTickMarks) {
        if (numberOfTickMarks > 0) {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index must be between 1 and %ld", numberOfTickMarks] UTF8String]) ;
        } else {
            return luaL_argerror(L, 2, "slider does not have any tick marks") ;
        }
    }
    [skin pushNSRect:[slider rectOfTickMarkAtIndex:index - 1]] ;
    return 1 ;
}

/// hs._asm.guitk.element.slider:indexOfTickMarkAt(point) -> integer | nil
/// Method
/// Get the index of the tick mark closest to the specified point
///
/// Parameters:
///  * `point` - a point table containing `x` and `y` coordinates of a point within the slider element's frame
///
/// Returns:
///  * If the specified point is within the frame of a tick mark, returns the index of the matching tick mark; otherwise returns nil.
///
/// Notes:
///  * It is currently not possible to invoke mouse tracking on just a single element; instead you must enable it for the manager the slider belongs to and calculate the point to compare by adjusting it to be relative to the slider elements top left point, e.g.
/// ~~~lua
///    g = require("hs._asm.guitk")
///    w = g.new{ x = 100, y = 100, h = 100, w = 300 }:contentManager(g.manager.new()):show()
///    m = w:contentManager():mouseCallback(function(mgr, message, point)
///                              local geomPoint   = hs.geometry.new(point)
///                              local slider      = mgr(1)
///                              local sliderFrame = slider:frameDetails()._effective
///                              if message == "move" and geomPoint:inside(sliderFrame) then
///                                  local index = slider:indexOfTickMarkAt{
///                                      x = point.x - sliderFrame.x,
///                                      y = point.y - sliderFrame.y
///                                  }
///                                  if index then print("hovering over", index) end
///                              end
///                          end):trackMouseMove(true)
///    m[1] = {
///        _element = g.element.slider.new():tickMarks(10),
///        frameDetails = { h = 100, w = 300 }
///    }
/// ~~~
///  * A more efficient solution is being considered that would allow limiting tracking to only those elements one is interested in but there is no specific eta at this point.
static int slider_indexOfTickMarkAtPoint(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TBREAK] ;
    HSASMGUITKElementSlider *slider = [skin toNSObjectAtIndex:1] ;

    NSInteger tickMark = [slider indexOfTickMarkAtPoint:[skin tableToPointAtIndex:2]] ;
    if (tickMark == NSNotFound) {
        lua_pushnil(L) ;
    } else {
        lua_pushinteger(L, tickMark + 1) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementSlider(lua_State *L, id obj) {
    HSASMGUITKElementSlider *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementSlider *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementSliderFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementSlider *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementSlider, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementSlider *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementSlider"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementSlider *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementSlider"] ;
        HSASMGUITKElementSlider *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementSlider"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementSlider *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementSlider, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            obj.callbackRef = [[LuaSkin shared] luaUnref:refTable ref:obj.callbackRef] ;
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
    {"tickMarksOnly",        slider_allowsTickMarkValuesOnly},
    {"altClickIncrement",    slider_altIncrementValue},
    {"max",                  slider_maxValuee},
    {"min",                  slider_minValue},
    {"tickMarks",            slider_numberOfTickMarks},
    {"type",                 slider_sliderType},
    {"tickMarkLocation",     slider_tickMarkPosition},
    {"trackFillColor",       slider_trackFillColor},
    {"knobThickness",        slider_knobThickness},
    {"vertical",             slider_vertical},
    {"value",                slider_currentValue},
    {"tickMarkValue",        slider_tickMarkValueAtIndex},
    {"closestTickMark",      slider_closestTickMarkToValue},
    {"closestTickMarkValue", slider_closestTickMarkValueToValue},
    {"rectOfTickMark",       slider_rectOfTickMarkAtIndex},
    {"indexOfTickMarkAt",    slider_indexOfTickMarkAtPoint},
    {"callback",             slider_callback},

    {"__tostring",           userdata_tostring},
    {"__eq",                 userdata_eq},
    {"__gc",                 userdata_gc},
    {NULL,                   NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", slider_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_guitk_element_slider(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementSlider         forClass:"HSASMGUITKElementSlider"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementSliderFromLua forClass:"HSASMGUITKElementSlider"
                                             withUserdataMapping:USERDATA_TAG];

    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"tickMarksOnly",
        @"altClickIncrement",
        @"max",
        @"min",
        @"tickMarks",
        @"type",
        @"tickMarkLocation",
        @"vertical",
        @"value",
        @"callback",
    ]] ;
    if ([NSSlider instancesRespondToSelector:NSSelectorFromString(@"trackFillColor")]) {
        lua_pushstring(L, "trackFillColor") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritControl") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
