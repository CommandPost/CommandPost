@import Cocoa ;
@import LuaSkin ;

// NOTE: Should only contain methods which can be applied to all NSView based elements (i.e. all of them)
//
//       These will be made available to any element which sets _inheritView in its luaopen_* function,
//       so enything which should be kept to a subset of such elements should be coded in the relevant element
//       files and not here.
//
//       If an element file already defines a method that is named here, the existing method will be used for
//       that element -- it will not be replaced by the common method.

/// === hs._asm.guitk.element._view ===
///
/// Common methods inherited by all elements defined as submodules. This does not include elements which come from other Hammerspoon modules (currently this is limited to canvas objects, but may be extended to include webview and possibly chooser.)
///
/// macOS Developer Note: Understanding this is not required for use of the methods provided by this submodule, but for those interested, `hs._asm.guitk` works by providing a framework for displaying macOS objects which are subclasses of the NSView class; macOS methods which belong to NSView and are not overridden or superseded by more specific or appropriate element specific methods are defined here so that they can be used by all elements which share this common ancestor.

static const char * const USERDATA_TAG = "hs._asm.guitk.element._view" ;

static NSDictionary *VIEW_FOCUSRINGTYPE ;

static void defineInternalDictionaryies() {
    VIEW_FOCUSRINGTYPE = @{
        @"default"  : @(NSFocusRingTypeDefault),
        @"none"     : @(NSFocusRingTypeNone),
        @"exterior" : @(NSFocusRingTypeExterior),
    } ;
}

#pragma mark - Common NSView Methods

/// hs._asm.guitk.element._view:fittingSize() -> table
/// Method
/// Returns a table with `h` and `w` keys specifying the element's fitting size as defined by macOS and the element's current properties.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table with `h` and `w` keys specifying the elements fitting size
///
/// Notes:
///  * The dimensions provided can be used to determine a minimum size for the element to display fully based on its current properties and may change as these change.
///  * Not all elements provide one or both of these fields; in such a case, the value for the missing or unspecified field will be 0.
///  * If you do not specify an elements height or width with `hs._asm.guitk.manager:elementFrameDetails`, with the elements constructor, or with [hs._asm.guitk.element._view:frameSize](#frameSize), the value returned by this method will be used instead; in cases where a specific dimension is not defined by this method, you should make sure to specify it or the element may not be visible.
static int view_fittingSize(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }
    [skin pushNSSize:view.fittingSize] ;
    return 1 ;
}

/// hs._asm.guitk.element._view:frameSize([size]) -> elementObject | table
/// Method
/// Get or set the frame size of the element.
///
/// Parameters:
///  * `size` - a size-table specifying the height and width of the element's frame
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
///
/// Notes:
///  * a size-table is a table with key-value pairs specifying the size (keys `h` and `w`) the element should be resized to.
///  * if the element is assigned directly to an `hs._asm.guitk` window object, setting the frame will have no effect.
///
///  * in general, it is more useful to adjust the element's size with `hs._asm.guitk.manager:elementFrameDetails` because this supports percentages and auto-resizing based on the size of the element's parent.  This method may be useful, however, when pre-building content before it has been added to a manager and the size cannot be assigned with its constructor.
static int view_frameSize(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (lua_gettop(L) == 1) {
        [skin pushNSSize:view.frame.size] ;
    } else {
        if (!(view.window && [view isEqualTo:view.window.contentView])) {
            NSSize newSize = [skin tableToSizeAtIndex:2] ;
            [view setFrameSize:newSize] ;
            // prevent existing frame details from resetting the change
            NSView *viewParent       = view.superview ;
            SEL    resetFrameDetails = NSSelectorFromString(@"resetFrameSizeDetailsFor:") ;
            if (viewParent && [viewParent respondsToSelector:resetFrameDetails]) {
                [viewParent performSelectorOnMainThread:resetFrameDetails withObject:view waitUntilDone:YES] ;
            }
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:_nextResponder() -> userdata
/// Method
/// Get the parent of the current element, usually a `hs._asm.guitk.manager` or `hs._asm.guitk` userdata object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the userdata representing the parent container of the element, usually a `hs._asm.guitk.manager` or `hs._asm.guitk` userdata object or nil if the element is currently not assigned to a window or manager or if the parent is not controllable through Hammerspoon.
///
/// Notes:
///  * The metamethods for `hs._asm.guitk.element` are designed so that you usually shouldn't need to access this method directly very often.
///  * The name "nextResponder" comes from the macOS user interface internal organization and refers to the object which is further up the responder chain when determining the target for user activity.
static int view__nextResponder(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (view.nextResponder) {
        [skin pushNSObject:view.nextResponder] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:tooltip([tooltip]) -> elementObject | string
/// Method
/// Get or set the tooltip for the element
///
/// Parameters:
///  * `tooltip` - a string, or nil to remove, specifying the tooltip to display when the mouse pointer hovers over the element
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
///
/// Notes:
///  * Tooltips are displayed when the window is active and the mouse pointer hovers over an element.
static int view_toolTip(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:view.toolTip] ;
    } else {
        if (lua_type(L, 2) != LUA_TSTRING) {
            view.toolTip = nil ;
        } else {
            view.toolTip = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:rotation([angle]) -> elementObject | number
/// Method
/// Get or set the rotation of the element about its center.
///
/// Parameters:
///  * `angle` - an optional number representing the number of degrees the element should be rotated clockwise around its center
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
///
/// Notes:
///  * Not all elements rotate cleanly, e.g. button elements with an image in them may skew the image or alter its size depending upon the specific angle of rotation. At this time it is not known if this can be easily addressed or not.

// If you're digging this deep to learn why the note above, a quick intial search suggests that this method is old and manipulating the layer directly is the more "modern" way to do it, but this would require some significant changes and will be delayed until absolutely necessary

static int view_frameCenterRotation(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, view.frameCenterRotation) ;
    } else {
        view.frameCenterRotation = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:hidden([state | nil]) -> elementObject | boolean
/// Method
/// Get or set whether or not the element is currently hidden
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the element should be hidden. If you specify an explicit nil, this method will return whether or not this element *or any of its parents* are currently hidden.
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
///
/// Notes:
///  * If no argument is provided, this method will return whether or not the element itself has been explicitly hidden; when an explicit nil is provided as the argument, this method will return whether or not this element or any of its parent objects are hidden, since hiding the parent will also hide all of the elements of the parent.
///
///  * When used as a property through the `hs._asm.guitk.manager` metamethods, this property can only get or set whether or not the element itself is explicitly hidden.
static int view_hidden(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, view.hidden) ;
    } else if (lua_type(L, 2) == LUA_TNIL) {
        lua_pushboolean(L, view.hiddenOrHasHiddenAncestor) ;
    } else {
        view.hidden = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:alphaValue([alpha]) -> elementObject | number
/// Method
/// Get or set the alpha level of the element.
///
/// Parameters:
///  * `alpha` - an optional number, default 1.0, specifying the alpha level (0.0 - 1.0, inclusive) for the element.
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
static int view_alphaValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, view.alphaValue) ;
    } else {
        CGFloat newAlpha = luaL_checknumber(L, 2);
        view.alphaValue = ((newAlpha < 0.0) ? 0.0 : ((newAlpha > 1.0) ? 1.0 : newAlpha)) ;
        lua_pushvalue(L, 1);
    }
    return 1 ;
}

/// hs._asm.guitk.element._view:focusRingType([type]) -> elementObject | string
/// Method
/// Get or set the focus ring type for the element
///
/// Parameters:
///  * `type` - an optional string specifying the focus ring type for the element.  Valid strings are as follows:
///    * "default"  - The default focus ring behavior for the element will be used when the element is the input focus; usually this is identical to "exterior".
///    * "none"     - No focus ring will be drawn around the element when it is the input focus
///    * "Exterior" - The standard Aqua focus ring will be drawn around the element when it is the input focus
///
/// Returns:
///  * if an argument is provided, returns the elementObject userdata; otherwise returns the current value
///
/// Notes:
///  * Setting this for an element that cannot be an active element has no effect.
///  * When an element is rotated with [hs._asm.guitk.element._view:rotation](#rotation), the focus ring may not appear properly; if you are using angles other then the four cardinal directions (0, 90, 180, or 270), it may be visually more appropriate to set this to "none".
static int view_focusRingType(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TANY, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSView *view = (lua_type(L, 1) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:1] : nil ;
    if (!view || ![view isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 1, "expected userdata representing a gui element (NSView subclass)") ;
    }

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *focusRingType = VIEW_FOCUSRINGTYPE[key] ;
        if (focusRingType) {
            view.focusRingType = [focusRingType unsignedIntegerValue] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[VIEW_FOCUSRINGTYPE allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *focusRingType = @(view.focusRingType) ;
        NSArray *temp = [VIEW_FOCUSRINGTYPE allKeysForObject:focusRingType];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized focus ring type %@ -- notify developers", USERDATA_TAG, focusRingType]] ;
            lua_pushnil(L) ;
        }
    }
    return 1;
}

#pragma mark - Hammerspoon/Lua Infrastructure

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"tooltip",        view_toolTip},
    {"rotation",       view_frameCenterRotation},
    {"hidden",         view_hidden},
    {"alphaValue",     view_alphaValue},
    {"focusRingType",  view_focusRingType},
    {"fittingSize",    view_fittingSize},
    {"frameSize",      view_frameSize},
    {"_nextResponder", view__nextResponder},
    {NULL,             NULL}
};

int luaopen_hs__asm_guitk_element__view(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

    [skin pushNSObject:@[
        @"tooltip",
        @"rotation",
        @"hidden",
        @"alphaValue",
        @"focusRingType",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;

    return 1;
}
