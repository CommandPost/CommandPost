// TODO: bar uses a system color for it's color which is why customColor doesn't work as well when indeterminate... can we determine what that color is and adjust the filter accordingly?

/// === hs._asm.guitk.element.progress ===
///
/// Provides spinning and bar progress indicator elements for use with `hs._asm.guitk`.
///
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import LuaSkin ;
@import QuartzCore ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.progress" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

static NSDictionary *PROGRESS_SIZE ;
static NSDictionary *PROGRESS_TINT ;

#pragma mark - Support Functions and Classes

static void defineInternalDictionaryies() {
    PROGRESS_SIZE = @{
        @"regular" : @(NSControlSizeRegular),
        @"small"   : @(NSControlSizeSmall),
        @"mini"    : @(NSControlSizeMini),
    } ;

    PROGRESS_TINT = @{
        @"default"  : @(NSDefaultControlTint),
        @"blue"     : @(NSBlueControlTint),
        @"graphite" : @(NSGraphiteControlTint),
        @"clear"    : @(NSClearControlTint),
    } ;
}

@interface HSASMGUITKElementProgress : NSProgressIndicator
@property            int     selfRefCount ;
@end

@implementation HSASMGUITKElementProgress
- (id)initWithFrame:(NSRect)frameRect {
    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _selfRefCount = 0 ;
        self.usesThreadedAnimation = YES ;
    }
    return self;
}

- (BOOL)isFlipped {
    return YES ;
}

// Code from http://stackoverflow.com/a/32396595
//
// Color works for spinner (both indeterminate and determinate) and partially for bar:
//    indeterminate bar becomes a solid, un-animating color; determinate bar looks fine.
- (void)setCustomColor:(NSColor *)aColor {
    if (aColor) {
        CIFilter *colorPoly = [CIFilter filterWithName:@"CIColorPolynomial"];
        [colorPoly setDefaults];

        CIVector *redVector   = [CIVector vectorWithX:aColor.redComponent   Y:0 Z:0 W:0] ;
        CIVector *greenVector = [CIVector vectorWithX:aColor.greenComponent Y:0 Z:0 W:0] ;
        CIVector *blueVector  = [CIVector vectorWithX:aColor.blueComponent  Y:0 Z:0 W:0] ;
        [colorPoly setValue:redVector   forKey:@"inputRedCoefficients"];
        [colorPoly setValue:greenVector forKey:@"inputGreenCoefficients"];
        [colorPoly setValue:blueVector  forKey:@"inputBlueCoefficients"];
        [self setContentFilters:[NSArray arrayWithObject:colorPoly]];
    } else {
        [self setContentFilters:[NSArray array]];
    }
}

- (NSColor *)customColor {
    CIFilter *colorPoly = self.contentFilters.firstObject ;
    if (colorPoly) {
        CIVector *redVector   = [colorPoly valueForKey:@"inputRedCoefficients"] ;
        CIVector *greenVector = [colorPoly valueForKey:@"inputGreenCoefficients"] ;
        CIVector *blueVector  = [colorPoly valueForKey:@"inputBlueCoefficients"] ;
        return [NSColor colorWithSRGBRed:redVector.X green:greenVector.X blue:blueVector.X alpha:1.0] ;
    } else {
        return nil ;
    }
}

@end

#pragma mark - Module Functions

/// hs._asm.guitk.element.progress.new([frame]) -> progressIndicatorObject
/// Constructor
/// Creates a new Progress Indicator element for `hs._asm.guitk`.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for the progress indicator object.
///
/// Returns:
///  * the progressIndicatorObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
///
///  * The bar progress indicator type does not have a default width; if you are assigning the progress element to an `hs._asm.guitk.manager`, be sure to specify a width in the frame details or the element may not be visible.
static int progress_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementProgress *progress = [[HSASMGUITKElementProgress alloc] initWithFrame:frameRect];
    if (progress) {
        if (lua_gettop(L) != 1) [progress setFrameSize:[progress fittingSize]] ;
        [skin pushNSObject:progress] ;
    } else {
        lua_pushnil(L) ;
    }

    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk.element.progress:start() -> progressObject
/// Method
/// If the progress indicator is indeterminate, starts the animation for the indicator.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the progress indicator object
///
/// Notes:
///  * This method has no effect if the indicator is not indeterminate.
static int progress_start(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    [progress startAnimation:nil];
    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.guitk.element.progress:stop() -> progressObject
/// Method
/// If the progress indicator is indeterminate, stops the animation for the indicator.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the progress indicator object
///
/// Notes:
///  * This method has no effect if the indicator is not indeterminate.
static int progress_stop(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    [progress stopAnimation:nil];
    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.guitk.element.progress:threaded([flag]) -> progressObject | boolean
/// Method
/// Get or set whether or not the animation for an indicator occurs in a separate process thread.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not the animation for the indicator should occur in a separate thread.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is true.
///  * If this flag is set to false, the indicator animation speed may fluctuate as Hammerspoon performs other activities, though not reliably enough to provide an "activity level" feedback indicator.
static int progress_threaded(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.usesThreadedAnimation = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, progress.usesThreadedAnimation) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:indeterminate([flag]) -> progressObject | boolean
/// Method
/// Get or set whether or not the progress indicator is indeterminate.  A determinate indicator displays how much of the task has been completed. An indeterminate indicator shows simply that the application is busy.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not the indicator is indeterminate.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is true.
///  * If this setting is set to false, you should also take a look at [hs._asm.guitk.element.progress:min](#min) and [hs._asm.guitk.element.progress:max](#max), and periodically update the status with [hs._asm.guitk.element.progress:value](#value) or [hs._asm.guitk.element.progress:increment](#increment)
static int progress_indeterminate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.indeterminate = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, progress.indeterminate) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:bezeled([flag]) -> progressObject | boolean
/// Method
/// Get or set whether or not the progress indicator’s frame has a three-dimensional bezel.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not the indicator's frame is bezeled.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is true.
///  * In my testing, this setting does not seem to have much, if any, effect on the visual aspect of the indicator and is provided in this module in case this changes in a future OS X update (there are some indications that it may have had a greater effect in previous versions).
static int progress_bezeled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.bezeled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, progress.bezeled) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:visibleWhenStopped([flag]) -> progressObject | boolean
/// Method
/// Get or set whether or not the progress indicator is visible when animation has been stopped.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not the progress indicator is visible when animation has stopped.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is true.
static int progress_displayedWhenStopped(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.displayedWhenStopped = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, progress.displayedWhenStopped) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:circular([flag]) -> progressObject | boolean
/// Method
/// Get or set whether or not the progress indicator is circular or a in the form of a progress bar.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not the indicator is circular (true) or a progress bar (false)
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is false.
///  * An indeterminate circular indicator is displayed as the spinning star seen during system startup.
///  * A determinate circular indicator is displayed as a pie chart which fills up as its value increases.
///  * An indeterminate progress indicator is displayed as a rounded rectangle with a moving pulse.
///  * A determinate progress indicator is displayed as a rounded rectangle that fills up as its value increases.
static int progress_circular(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.style = (BOOL)lua_toboolean(L, 2) ? NSProgressIndicatorSpinningStyle : NSProgressIndicatorBarStyle ;
//         [progress sizeToFit] ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, (progress.style == NSProgressIndicatorSpinningStyle)) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:value([value]) -> progressObject | number
/// Method
/// Get or set the current value of the progress indicator's completion status.
///
/// Parameters:
///  * `value` - an optional number indicating the current extent of the progress.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default value for this is 0.0
///  * This value has no effect on the display of an indeterminate progress indicator.
///  * For a determinate indicator, this will affect how "filled" the bar or circle is.  If the value is lower than [hs._asm.guitk.element.progress:min](#min), then it will be set to the current minimum value.  If the value is greater than [hs._asm.guitk.element.progress:max](#max), then it will be set to the current maximum value.
static int progress_value(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.doubleValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushnumber(L, progress.doubleValue) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:min([value]) -> progressObject | number
/// Method
/// Get or set the minimum value (the value at which the progress indicator should display as empty) for the progress indicator.
///
/// Parameters:
///  * `value` - an optional number indicating the minimum value.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default value for this is 0.0
///  * This value has no effect on the display of an indeterminate progress indicator.
///  * For a determinate indicator, the behavior is undefined if this value is greater than [hs._asm.guitk.element.progress:max](#max).
static int progress_min(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.minValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushnumber(L, progress.minValue) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:max([value]) -> progressObject | number
/// Method
/// Get or set the maximum value (the value at which the progress indicator should display as full) for the progress indicator.
///
/// Parameters:
///  * `value` - an optional number indicating the maximum value.
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default value for this is 100.0
///  * This value has no effect on the display of an indeterminate progress indicator.
///  * For a determinate indicator, the behavior is undefined if this value is less than [hs._asm.guitk.element.progress:min](#min).
static int progress_max(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 2) {
        progress.maxValue = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushnumber(L, progress.maxValue) ;
    }
    return 1;
}

/// hs._asm.guitk.element.progress:increment(value) -> progressObject
/// Method
/// Increment the current value of a progress indicator's progress by the amount specified.
///
/// Parameters:
///  * `value` - the value by which to increment the progress indicator's current value.
///
/// Returns:
///  * the progress indicator object
///
/// Notes:
///  * Programmatically, this is equivalent to `hs._asm.guitk.element.progress:value(hs._asm.guitk.element.progress:value() + value)`, but is faster.
static int progress_increment(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;
    [progress incrementBy:lua_tonumber(L, 2)] ;
    lua_pushvalue(L, 1) ;
    return 1;
}

/// hs._asm.guitk.element.progress:tint([tint]) -> progressObject | string
/// Method
/// Get or set the indicator's tint.
///
/// Parameters:
///  * `tint` - an optional string specifying the tint of the progress indicator.  May be one of "default", "blue", "graphite", or "clear".
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is "default".
///  * In my testing, this setting does not seem to have much, if any, effect on the visual aspect of the indicator and is provided in this module in case this changes in a future OS X update (there are some indications that it may have had an effect in previous versions).
static int progress_controlTint(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *controlTint = PROGRESS_TINT[key] ;
        if (controlTint) {
            progress.controlTint = [controlTint unsignedIntegerValue] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[PROGRESS_TINT allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *controlTint = @(progress.controlTint) ;
        NSArray *temp = [PROGRESS_TINT allKeysForObject:controlTint];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized control tint %@ -- notify developers", USERDATA_TAG, controlTint]] ;
            lua_pushnil(L) ;
        }
    }
    return 1;
}

/// hs._asm.guitk.element.progress:indicatorSize([size]) -> progressObject | string
/// Method
/// Get or set the indicator's size.
///
/// Parameters:
///  * `size` - an optional string specifying the size of the progress indicator object.  May be one of "regular", "small", or "mini".
///
/// Returns:
///  * if a value is provided, returns the progress indicator object ; otherwise returns the current value.
///
/// Notes:
///  * The default setting for this is "regular".
///  * For circular indicators, the sizes seem to be 32x32, 16x16, and 10x10 in 10.11.
///  * For bar indicators, the height seems to be 20 and 12; the mini size seems to be ignored, at least in 10.11.
static int progress_controlSize(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *controlSize = PROGRESS_SIZE[key] ;
        if (controlSize) {
            progress.controlSize = [controlSize unsignedIntegerValue] ;
//             [progress sizeToFit] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[PROGRESS_SIZE allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *controlSize = @(progress.controlSize) ;
        NSArray *temp = [PROGRESS_SIZE allKeysForObject:controlSize];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized control size %@ -- notify developers", USERDATA_TAG, controlSize]] ;
            lua_pushnil(L) ;
        }
    }
    return 1;
}

/// hs._asm.guitk.element.progress:color(color) -> progressObject | table | nil
/// Method
/// Get or set the fill color for a progress indicator.
///
/// Parameters:
///  * `color` - an optional table specifying a color as defined in `hs.drawing.color` indicating the color to use for the progress indicator, or an explicit nil to reset the behavior to macOS default.
///
/// Returns:
///  * the progress indicator object
///
/// Notes:
///  * This method is not based upon the methods inherent in the NSProgressIndicator Objective-C class, but rather on code found at http://stackoverflow.com/a/32396595 utilizing a CIFilter object to adjust the view's output.
///  * When a color is applied to a bar indicator, the visible pulsing of the bar is no longer visible; this is a side effect of applying the filter to the view and no workaround is currently known.
static int progress_customColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementProgress *progress = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:progress.customColor] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            progress.customColor = nil ;
        } else {
            NSColor *theColor = [[skin luaObjectAtIndex:2 toClass:"NSColor"] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] ;
            if (theColor) {
                progress.customColor = theColor ;
            } else {
                return luaL_error(L, "color must be expressible in the RGB color space") ;
            }
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementProgress(lua_State *L, id obj) {
    HSASMGUITKElementProgress *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementProgress *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementProgressFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared]  ;
    HSASMGUITKElementProgress *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementProgress, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementProgress *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementProgress"] ;
    NSString *title = nil ;
    if ([obj isIndeterminate]) {
        title = @"indeterminate" ;
    } else {
        title = [NSString stringWithFormat:@"@%.2f of [%.2f, %.2f]", obj.doubleValue,
                                                                     obj.minValue,
                                                                     obj.maxValue] ;
    }
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementProgress *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementProgress"] ;
        HSASMGUITKElementProgress *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementProgress"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementProgress *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementProgress, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
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
    {"start",              progress_start},
    {"stop",               progress_stop},
    {"threaded",           progress_threaded},
    {"indeterminate",      progress_indeterminate},
    {"circular",           progress_circular},
    {"bezeled",            progress_bezeled},
    {"visibleWhenStopped", progress_displayedWhenStopped},
    {"value",              progress_value},
    {"min",                progress_min},
    {"max",                progress_max},
    {"increment",          progress_increment},
    {"indicatorSize",      progress_controlSize},
    {"tint",               progress_controlTint},
    {"color",              progress_customColor},

    {"__tostring",         userdata_tostring},
    {"__eq",               userdata_eq},
    {"__gc",               userdata_gc},
    {NULL,                 NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", progress_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_element_progress(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementProgress         forClass:"HSASMGUITKElementProgress"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementProgressFromLua forClass:"HSASMGUITKElementProgress"
                                                          withUserdataMapping:USERDATA_TAG];
    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"threaded",
        @"indeterminate",
        @"circular",
        @"bezeled",
        @"visibleWhenStopped",
        @"value",
        @"min",
        @"max",
        @"indicatorSize",
        @"tint",
        @"color",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
