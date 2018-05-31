
/// === hs._asm.guitk.element.image ===
///
/// Provides an image holder element `hs._asm.guitk`. The image can be static, specified by you, or it can be an editable element, allowing the user to change the image through drag-and-drop or cut-and-paste.
///
/// * This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.image" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

static NSDictionary *IMAGE_FRAME_STYLES ;
static NSDictionary *IMAGE_ALIGNMENTS ;
static NSDictionary *IMAGE_SCALING_TYPES ;

#pragma mark - Support Functions and Classes

static void defineInternalDictionaryies() {
    IMAGE_FRAME_STYLES = @{
        @"none"   : @(NSImageFrameNone),
        @"photo"  : @(NSImageFramePhoto),
        @"bezel"  : @(NSImageFrameGrayBezel),
        @"groove" : @(NSImageFrameGroove),
        @"button" : @(NSImageFrameButton),
    } ;

    IMAGE_ALIGNMENTS = @{
        @"center"      : @(NSImageAlignCenter),
        @"top"         : @(NSImageAlignTop),
        @"topLeft"     : @(NSImageAlignTopLeft),
        @"topRight"    : @(NSImageAlignTopRight),
        @"left"        : @(NSImageAlignLeft),
        @"bottom"      : @(NSImageAlignBottom),
        @"bottomLeft"  : @(NSImageAlignBottomLeft),
        @"bottomRight" : @(NSImageAlignBottomRight),
        @"right"       : @(NSImageAlignRight),
    } ;

    IMAGE_SCALING_TYPES = @{
        @"proportionallyDown"     : @(NSImageScaleProportionallyDown),
        @"axesIndependently"      : @(NSImageScaleAxesIndependently),
        @"none"                   : @(NSImageScaleNone),
        @"proportionallyUpOrDown" : @(NSImageScaleProportionallyUpOrDown),
    } ;
}

@interface HSASMGUITKElementImage : NSImageView
@property int selfRefCount ;
@property int callbackRef ;
@end

@implementation HSASMGUITKElementImage

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

- (void)performCallback:(__unused id)sender {
    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        [skin pushLuaRef:refTable ref:_callbackRef] ;
        [skin pushNSObject:self] ;
        if (![skin protectedCallAndTraceback:1 nresults:0]) {
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
                                              withObject:@[ self ]
                                           waitUntilDone:YES] ;
            }
        }
    }
}

@end

#pragma mark - Module Functions

/// hs._asm.guitk.element.image.new([frame]) -> imageObject
/// Constructor
/// Creates a new image holder element for `hs._asm.guitk`.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for element.
///
/// Returns:
///  * the imageObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
///
///  * If you do not assign an image to the element with [hs._asm.guitk.element.image:image](#image) after creating a new image element, the element will not have a default height or width; when assigning the element to an `hs._asm.guitk.manager`, be sure to specify them in the frame details or the element may not be visible.
static int image_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementImage *image = [[HSASMGUITKElementImage alloc] initWithFrame:frameRect];
    if (image) {
        if (lua_gettop(L) != 1) [image setFrameSize:[image fittingSize]] ;
        [skin pushNSObject:image] ;
    } else {
        lua_pushnil(L) ;
    }

    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk.element:allowsCutCopyPaste([state]) -> imageObject | boolean
/// Method
/// Get or set whether or not the image holder element allows the user to cut, copy, and paste an image to or from the element.
///
/// Parameters:
///  * `state` - an optional boolean, default true, indicating whether or not the user can cut, copy, and paste images to or from the element.
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
static int image_allowsCutCopyPaste(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, image.allowsCutCopyPaste) ;
    } else {
        image.allowsCutCopyPaste = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element:animates([state]) -> imageObject | boolean
/// Method
/// Get or set whether or not an animated GIF that is assigned to the imageObject should be animated or static.
///
/// Parameters:
///  * `state` - an optional boolean indicating whether or not animated GIF images can be animated.
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
static int image_animates(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, image.animates) ;
    } else {
        image.animates = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element:editable([state]) -> imageObject | boolean
/// Method
/// Get or set whether or not the image holder element allows the user to drag an image or image file onto the element.
///
/// Parameters:
///  * `state` - an optional boolean, default false, indicating whether or not the user can drag an image or image file onto the element.
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
static int image_editable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, image.editable) ;
    } else {
        image.editable = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.image:imageAlignment([alignment]) -> imageObject | string
/// Method
/// Get or set the alignment of the image within the image element.
///
/// Parameters:
///  * `alignment` - an optional string, default "center", specifying the images alignment within the element frame. Valid strings are as follows:
///    * "topLeft"     - the image's top left corner will match the element frame's top left corner
///    * "top"         - the image's top match the element frame's top and will be centered horizontally
///    * "topRight"    - the image's top right corner will match the element frame's top right corner
///    * "left"        - the image's left side will match the element frame's left side and will be centered vertically
///    * "center"      - the image will be centered vertically and horizontally within the element frame
///    * "right"       - the image's right side will match the element frame's right side and will be centered vertically
///    * "bottomLeft"  - the image's bottom left corner will match the element frame's bottom left corner
///    * "bottom"      - the image's bottom match the element frame's bottom and will be centered horizontally
///    * "bottomRight" - the image's bottom right corner will match the element frame's bottom right corner
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
static int image_imageAlignment(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *type = @(image.imageAlignment) ;
        NSArray *temp = [IMAGE_ALIGNMENTS allKeysForObject:type] ;
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized alignment %@ -- notify developers", USERDATA_TAG, type]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *type = IMAGE_ALIGNMENTS[key] ;
        if (type) {
            image.imageAlignment = [type unsignedIntegerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[IMAGE_ALIGNMENTS allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.image:imageFrameStyle([style]) -> imageObject | string
/// Method
/// Get or set the visual frame drawn around the image element area.
///
/// Parameters:
///  * `style` - an optional string, default "none", specifying the frame to draw around the image element area. Valid strings are as follows:
///    * "none"   - no frame is drawing around the image element frame
///    * "photo"  - a thin black outline with a white background and a dropped shadow.
///    * "bezel"  - a gray, concave bezel with no background that makes the image look sunken
///    * "groove" - a thin groove with a gray background that looks etched around the image
///    * "button" - a convex bezel with a gray background that makes the image stand out in relief, like a butto
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
///
/// Notes:
///  * Apple considers the photo, groove, and button style frames "stylistically obsolete" and if a frame is required, recommend that you use the bezel style or draw your own to more closely match the OS look and feel.
static int image_imageFrameStyle(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *type = @(image.imageFrameStyle) ;
        NSArray *temp = [IMAGE_FRAME_STYLES allKeysForObject:type] ;
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized frame style %@ -- notify developers", USERDATA_TAG, type]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *type = IMAGE_FRAME_STYLES[key] ;
        if (type) {
            image.imageFrameStyle = [type unsignedIntegerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[IMAGE_FRAME_STYLES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.image:imageScaling([scale]) -> imageObject | string
/// Method
/// Get or set the scaling applied to the image if it doesn't fit the image element area exactly
///
/// Parameters:
///  * `scale` - an optional string, default "proportionallyDown", specifying how to scale the image when it doesn't fit the element area exactly. Valid strings are as follows:
///    * "proportionallyDown"     - shrink the image, preserving the aspect ratio, to fit the element frame if the image is larger than the element frame
///    * "axesIndependently"      - shrink or expand the image to fully fill the element frame. This does not preserve the aspect ratio
///    * "none"                   - perform no scaling or resizing of the image
///    * "proportionallyUpOrDown" - shrink or expand the image to fully fill the element frame, preserving the aspect ration
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
static int image_imageScaling(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *type = @(image.imageScaling) ;
        NSArray *temp = [IMAGE_SCALING_TYPES allKeysForObject:type] ;
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized frame style %@ -- notify developers", USERDATA_TAG, type]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *type = IMAGE_SCALING_TYPES[key] ;
        if (type) {
            image.imageScaling = [type unsignedIntegerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[IMAGE_SCALING_TYPES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.image:image([image]) -> imageObject | hs.image | nil
/// Method
/// Get or set the image currently being displayed in the image element.
///
/// Parameters:
///  * `image` - an optional `hs.image` object, or explicit nil to remove, representing the image currently being displayed by the image element.
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
///
/// Notes:
///  * If the element is editable or supports cut-and-paste, any change made by the user to the image will be available to Hammerspoon through this method.
static int image_image(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:image.image] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            image.image = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            image.image = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.image:callback([fn | nil]) -> imageObject | fn | nil
/// Method
/// Get or set the callback function which will be invoked whenever the user changes the image of the element by dragging or pasting an image into it.
///
/// Parameters:
///  * `fn` - a lua function, or explicit nil to remove, which will be invoked when the image inside the element is changed by the user.
///
/// Returns:
///  * if a value is provided, returns the imageObject ; otherwise returns the current value.
///
/// Notes:
///  * The image callback will receive one argument and should return none. The argument will be the imageObject userdata.
///    * Use [hs._asm.guitk.element.image:image](#image) on the argument to get the new image.
static int image_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementImage *image = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        image.callbackRef = [skin luaUnref:refTable ref:image.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            image.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (image.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:image.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementImage(lua_State *L, id obj) {
    HSASMGUITKElementImage *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementImage *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementImageFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementImage *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementImage, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementImage *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementImage"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementImage *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementImage"] ;
        HSASMGUITKElementImage *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementImage"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementImage *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementImage, L, 1, USERDATA_TAG) ;
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
    {"allowsCutCopyPaste", image_allowsCutCopyPaste},
    {"animates",           image_animates},
    {"editable",           image_editable},
    {"imageAlignment",     image_imageAlignment},
    {"imageFrameStyle",    image_imageFrameStyle},
    {"imageScaling",       image_imageScaling},
    {"image",              image_image},
    {"callback",           image_callback},

    {"__tostring",         userdata_tostring},
    {"__eq",               userdata_eq},
    {"__gc",               userdata_gc},
    {NULL,                 NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", image_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_element_image(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementImage         forClass:"HSASMGUITKElementImage"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementImageFromLua forClass:"HSASMGUITKElementImage"
                                                       withUserdataMapping:USERDATA_TAG];
    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"allowsCutCopyPaste",
        @"animates",
        @"editable",
        @"imageAlignment",
        @"imageFrameStyle",
        @"imageScaling",
        @"image",
        @"callback",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritControl") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
