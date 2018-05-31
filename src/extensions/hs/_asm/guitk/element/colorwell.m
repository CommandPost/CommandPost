
// TODO:
//    Document
//    Example
//    e.g. g = require("hs._asm.guitk") ; g.element.colorwell.ignoresAlpha(false) ; w = g.new{x = 100, y = 100, h = 200, w = 200}:passthroughCallback(function(...) print(timestamp(), finspect(...)) end):contentManager(g.element.colorwell.new()):show()

/// === hs._asm.guitk.element.colorwell ===
///
/// Provides acolorwell element `hs._asm.guitk`. A colorwell is a rectangular swatch of color which the user can click on to pop up the color picker for choosing a new color.
///
/// * This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.colorwell" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

@interface HSASMGUITKElementColorWell : NSColorWell
@property int selfRefCount ;
@property int callbackRef ;
@end

@implementation HSASMGUITKElementColorWell

- (instancetype)initWithFrame:(NSRect)frameRect {
    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _callbackRef  = LUA_NOREF ;
        _selfRefCount = 0 ;
        self.target = self ;
        self.action = @selector(performCallback:) ;
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

- (void) deactivate {
    [super deactivate] ;
    [self callbackHamster:@[ self, @"didEndEditing", self.color ]] ;
}

- (void) activate:(BOOL)state {
    [super activate:state] ;
    [self callbackHamster:@[ self, @"didBeginEditing" ]] ;
}

- (void)performCallback:(__unused id)sender {
    if (self.continuous) [self callbackHamster:@[ self, @"colorDidChange", self.color ]] ;
}

@end

#pragma mark - Module Functions
/// hs._asm.guitk.element.colorwell.new([frame]) -> colorwellObject
/// Constructor
/// Creates a new colorwell element for `hs._asm.guitk`.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for the element.
///
/// Returns:
///  * the colorwellObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
///
///  * The colorwell element does not have a default height or width; when assigning the element to an `hs._asm.guitk.manager`, be sure to specify them in the frame details or the element may not be visible.
static int colorwell_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementColorWell *well = [[HSASMGUITKElementColorWell alloc] initWithFrame:frameRect];
    if (well) {
        if (lua_gettop(L) != 1) [well setFrameSize:[well fittingSize]] ;
        [skin pushNSObject:well] ;
    } else {
        lua_pushnil(L) ;
    }

    return 1 ;
}

/// hs._asm.guitk.element.colorwell.ignoresAlpha([state]) -> boolean
/// Function
/// Get or set whether or not the alpha component is ignored in the color picker.
///
/// Parameters:
///  * `state` - an optional boolean, default true, indicating whether or not the alpha channel should ignored (suppressed) in the color picker.
///
/// Returns:
///  * a boolean representing the, possibly new, state.
///
/// Note:
///  * When set to true, the alpha channel is not editable. If you assign a color that has an alpha component other than 1.0 with [hs._asm.guitk.element.colorwell:color](#color), the alpha component will be set to 1.0.
///
/// * The color picker is not unique to each element -- if you require the alpha channel for some colorwells but not others, make sure to call this function from the callback when the picker is opened for each specific colorwell element -- see [hs._asm.guitk.element.colorwell:callback](#callback).
static int colorwell_ignoresAlpha(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    if (lua_gettop(L) == 1) {
        [NSColor setIgnoresAlpha:(BOOL)lua_toboolean(L, 1)] ;
    }
    lua_pushboolean(L, [NSColor ignoresAlpha]) ;
    return 1 ;
}

/// hs._asm.guitk.element.colorwell.panelVisible([state]) -> boolean
/// Function
/// Get or set whether the color picker panel is currently open and visible or not.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the color picker is currently visible, displaying or closing it as specified.
///
/// Returns:
///  * a boolean representing the, possibly new, state
///
/// Notes:
///  * if a colorwell is currently the active element, invoking this function with a false argument will trigger the colorwell's close callback -- see [hs._asm.guitk.element.colorwell:callback](#callback).
static int colorwell_pickerVisible(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;

    NSColorPanel *picker = [NSColorPanel sharedColorPanel] ;
    if (lua_gettop(L) == 1) {
        if (lua_toboolean(L, 1)) {
            [picker makeKeyAndOrderFront:nil] ;
        } else {
            [picker close] ;
        }
    }
    lua_pushboolean(L, picker.visible) ;
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk.element.colorwell:callback([fn | nil]) -> colorwellObject | fn | nil
/// Method
/// Get or set the callback function which will be invoked when the user uses the color picker to modify the colorwell element.
///
/// Parameters:
///  * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user uses the color picker to modify the colorwell element.
///
/// Returns:
///  * if a value is provided, returns the colorwellObject ; otherwise returns the current value.
///
/// Notes:
///  * The callback function should expect arguments as described below and return none:
///    * When the colorwell is activated the callback will receive the following arguments:
///      * the colorwell userdata object
///      * the message string "didBeginEditing" indicating that the colorwell element has become active
///    * When the colorwell is deactivated the callback will receive the following arguments:
///      * the colorwell userdata object
///      * the message string "didEndEditing" indicating that the colorwell element is no longer active
///      * a table describing the new color as defined by the `hs.drawing.color` module.
///    * When the user selects or changes a color in the color picker, and `hs._asm.guitk.element._control:continuous` is true for the element, the callback will receive the following arguments:
///      * the colorwell userdata object
///      * the message string "colorDidChange" indicating that the user has selected or modified the color currently chosen in the color picker panel.
///      * a table describing the currently selected color as defined by the `hs.drawing.color` module.
static int colorwell_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementColorWell *well = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        well.callbackRef = [skin luaUnref:refTable ref:well.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            well.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (well.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:well.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.colorwell:bordered([enabled]) -> colorwellObject | boolean
/// Method
/// Get or set whether the colorwell element has a rectangular border around it.
///
/// Parameters:
///  * `enabled` - an optional boolean, default true, specifying whether or not a border should be drawn around the colorwell element.
///
/// Returns:
///  * if a value is provided, returns the colorwellObject ; otherwise returns the current value.
static int colorwell_bordered(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementColorWell *well = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, well.bordered) ;
    } else {
        well.bordered = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.colorwell:active([state]) -> colorwellObject | boolean
/// Method
/// Get or set whether the colorwell element is the currently active element.
///
/// Parameters:
///  * `state` - an optional boolean, specifying whether the colorwell element should be activated (true) or deactivated (false).
///
/// Returns:
///  * if a value is provided, returns the colorwellObject ; otherwise returns the current value.
///
/// Notes:
///  * if you pass true to this method and the color picker panel is not currently visible, it will be made visible.
///  * however, it won't be dismissed when you pass false; to achieve this, use [hs._asm.guitk.element.colorwell:callback](#callback) like this:
///
///  ~~~lua
///  colorwell:callback(function(obj, msg, color)
///      if msg == "didBeginEditing" then
///         -- do what you want when the color picker is opened
///       elseif msg == "colorDidChange" then
///         -- do what you want with the color as it changes
///       elseif msg == "didEndEditing" then
///         hs._asm.guitk.element.colorwell.panelVisible(false)
///         -- now do what you want with the newly chosen color
///       end
///  end)
///  ~~~
static int colorwell_active(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementColorWell *well = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, well.active) ;
    } else {
        if (lua_toboolean(L, 2)) {
            [well activate:YES] ;
        } else {
            [well deactivate] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.colorwell:color([color]) -> colorwellObject | table
/// Method
/// Get or set the color currently being displayed by the colorwell element
///
/// Parameters:
///  * an optional table defining a color as specified in the `hs.drawing.color` module to set the colorwell to.
///
/// Returns:
///  * if a value is provided, returns the colorwellObject ; otherwise returns the current value.
///
/// Notes:
///  * if assigning a new color and [hs._asm.guitk.element.colorwell.ignoresAlpha](#ignoresAlpha) is currently true, the alpha channel of the color will be ignored and internally changed to 1.0.
static int colorwell_color(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementColorWell *well = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:well.color] ;
    } else {
        well.color = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementColorWell(lua_State *L, id obj) {
    HSASMGUITKElementColorWell *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementColorWell *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementColorWellFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementColorWell *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementColorWell, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementColorWell *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementColorWell"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementColorWell *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementColorWell"] ;
        HSASMGUITKElementColorWell *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementColorWell"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementColorWell *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementColorWell, L, 1, USERDATA_TAG) ;
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

static int meta_gc(lua_State* __unused L) {
    [[NSColorPanel sharedColorPanel] close] ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"bordered",   colorwell_bordered},
    {"active",     colorwell_active},
    {"callback",   colorwell_callback},
    {"color",      colorwell_color},

    {"__tostring", userdata_tostring},
    {"__eq",       userdata_eq},
    {"__gc",       userdata_gc},
    {NULL,         NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",          colorwell_new},
    {"ignoresAlpha", colorwell_ignoresAlpha},
    {"panelVisible", colorwell_pickerVisible},
    {NULL,           NULL}
};

// Metatable for module, if needed
static const luaL_Reg module_metaLib[] = {
    {"__gc", meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_guitk_element_colorwell(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementColorWell         forClass:"HSASMGUITKElementColorWell"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementColorWellFromLua forClass:"HSASMGUITKElementColorWell"
                                                       withUserdataMapping:USERDATA_TAG];
    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"bordered",
        @"active",
        @"callback",
        @"color",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritControl") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
