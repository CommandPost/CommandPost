// Uses associated objects to "add" callback and selfRef -- this is done instead of
// subclassing so we don't have to add special code in menu.m to deal with regular
// menu items and separator items; forcing an NSMenuItem for a separator into an
// HSMenuItem object seems... disingenuous at best.

@import Cocoa ;
@import LuaSkin ;
@import ObjectiveC.runtime ;

static void *CALLBACKREF_KEY  = @"HS_callbackRefKey" ;
static void *SELFREFCOUNT_KEY = @"HS_selfRefCountKey" ;

static const char * const USERDATA_TAG = "hs._asm.guitk.menubar.menu.item" ;
static int refTable = LUA_NOREF;

static NSDictionary *MENU_ITEM_STATES ;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static void defineInternalDictionaryies() {
    MENU_ITEM_STATES = @{
        @"on"    : @(NSOnState),
        @"off"   : @(NSOffState),
        @"mixed" : @(NSMixedState),
    } ;
}

@interface NSMenuItem (HammerspoonAdditions)
@property (nonatomic) int  callbackRef ;
@property (nonatomic) int  selfRefCount ;
@end

@implementation NSMenuItem (HammerspoonAdditions)

+ (instancetype)newWithTitle:(NSString *)title {
    NSMenuItem *item = nil ;
    if ([title isEqualToString:@"-"]) {
        item = [NSMenuItem separatorItem] ;
    } else {
        item = [[NSMenuItem alloc] initWithTitle:title action:@selector(itemSelected:) keyEquivalent:@""] ;
    }
    if (item) {
        item.callbackRef  = LUA_NOREF ;
        item.selfRefCount = 0 ;
        item.target       = item ;
    }
    return item ;
}

- (void)setCallbackRef:(int)value {
    NSNumber *valueWrapper = [NSNumber numberWithInt:value];
    objc_setAssociatedObject(self, CALLBACKREF_KEY, valueWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int)callbackRef {
    NSNumber *valueWrapper = objc_getAssociatedObject(self, CALLBACKREF_KEY) ;
    if (!valueWrapper) {
        valueWrapper = @(LUA_NOREF) ;
        [self setCallbackRef:valueWrapper.intValue] ;
    }
    return valueWrapper.intValue ;
}

- (void)setSelfRefCount:(int)value {
    NSNumber *valueWrapper = [NSNumber numberWithInt:value];
    objc_setAssociatedObject(self, SELFREFCOUNT_KEY, valueWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int)selfRefCount {
    NSNumber *valueWrapper = objc_getAssociatedObject(self, SELFREFCOUNT_KEY) ;
    if (!valueWrapper) {
        valueWrapper = @(0) ;
        [self setSelfRefCount:valueWrapper.intValue] ;
    }
    return valueWrapper.intValue ;
}

// requires the menu to have autoenableItems = YES and then enabled is ignored in preference of this
// for *every* item, so probably not going to implement this...
// - (BOOL)validateMenuItem:(NSMenuItem *)menuItem ;

- (void) itemSelected:(__unused id)sender { [self performCallbackMessage:@"select" with:nil] ; }

- (void)performCallbackMessage:(NSString *)message with:(id)data {
    if (self.callbackRef != LUA_NOREF) {
        LuaSkin   *skin = [LuaSkin shared] ;
        lua_State *L    = skin.L ;
        int       count = 2 ;
        [skin pushLuaRef:refTable ref:self.callbackRef] ;
        [skin pushNSObject:self] ;
        [skin pushNSObject:message] ;
        if (data) {
            count++ ;
            [skin pushNSObject:data] ;
        }
        if (![skin protectedCallAndTraceback:count nresults:0]) {
            [skin logError:[NSString stringWithFormat:@"%s:callback error - %s", USERDATA_TAG, lua_tostring(L, -1)]] ;
            lua_pop(L, 1) ;
        }
    }
}

@end

#pragma mark - Module Functions

static int menuitem_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBREAK] ;

    NSString           *title ;
    NSAttributedString *attributedTitle ;

    if (lua_type(L, 1) == LUA_TUSERDATA) {
        [skin checkArgs:LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
        attributedTitle = [skin toNSObjectAtIndex:1] ;
        title = attributedTitle.string ;
    } else {
        [skin checkArgs:LS_TSTRING, LS_TBREAK] ;
        title = [skin toNSObjectAtIndex:1] ;
    }

    NSMenuItem *item = [NSMenuItem newWithTitle:title] ;
    if (item) {
        if (attributedTitle) item.attributedTitle = attributedTitle ;
        [skin pushNSObject:item] ;
    } else {
        lua_pushnil(L) ;
    }
//     NSMenuItem *item ;
//     if ([title isEqualToString:@"-"]) {
//         item = [NSMenuItem separatorItem] ;
//     } else {
//         item = [[NSMenuItem alloc] initWithTitle:title action:@selector(itemSelected:) keyEquivalent:@""] ;
//     }
//
//     if (item) {
// // do this here so that both separator items *and* regular menu items get a selfRefCount
// // maybe do a class level alloc/initializer?
//         item.callbackRef  = LUA_NOREF ;
//         item.selfRefCount = 0 ;
//         item.target       = item ;
//         [skin pushNSObject:item] ;
//     } else {
//         lua_pushnil(L) ;
//     }
    return 1 ;
}

#pragma mark - Module Methods

static int menuitem_state(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        NSNumber *state = @(item.state) ;
        NSArray *temp = [MENU_ITEM_STATES allKeysForObject:state];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized state %@ -- notify developers", USERDATA_TAG, state]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *state = MENU_ITEM_STATES[key] ;
        if (state) {
            item.state = [state integerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[MENU_ITEM_STATES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

static int menuitem_indentationLevel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, item.indentationLevel) ;
    } else {
        NSInteger level = lua_tointeger(L, 2) ;
        item.indentationLevel = (level < 0) ? 0 : ((level > 15) ? 15 : level) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_toolTip(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.toolTip] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.toolTip = nil ;
        } else {
            item.toolTip = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_image(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,  LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.image] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.image = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            item.image = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_mixedStateImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,  LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.mixedStateImage] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.mixedStateImage = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            item.mixedStateImage = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_offStateImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,  LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.offStateImage] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.offStateImage = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            item.offStateImage = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_onStateImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,  LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.onStateImage] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.onStateImage = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.image", LS_TBREAK] ;
            item.onStateImage = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushstring(L, "-") ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.title] ;
    } else if (lua_type(L, 1) == LUA_TBOOLEAN) {
        [skin pushNSObject:(lua_toboolean(L, 1) ? item.attributedTitle : item.title)] ;
    } else {
        if (lua_type(L, 2) == LUA_TUSERDATA) {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
            NSAttributedString *title = [skin toNSObjectAtIndex:2] ;
            item.title = title.string ;
            item.attributedTitle = title ;
        } else if (lua_type(L, 2) == LUA_TNIL) {
            item.attributedTitle = nil ;
            item.title = @"" ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
            item.attributedTitle = nil ;
            item.title = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_enabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, item.enabled) ;
    } else {
        item.enabled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_hidden(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, item.hidden) ;
    } else {
        item.hidden = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_view(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        if (item.view && [skin canPushNSObject:item.view]) {
            [skin pushNSObject:item.view] ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            if (item.view && [skin canPushNSObject:item.view]) [skin luaRelease:refTable forNSObject:item.view] ;
            item.view = nil ;
        } else {
            NSView *view = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
            if (!view || ![view isKindOfClass:[NSView class]]) {
                return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
            }
            if (item.view && [skin canPushNSObject:item.view]) [skin luaRelease:refTable forNSObject:item.view] ;
            [skin luaRetain:refTable forNSObject:view] ;
            item.view = view ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_submenu(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.submenu] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            if (item.submenu && [skin canPushNSObject:item.submenu]) [skin luaRelease:refTable forNSObject:item.submenu] ;
            item.menu = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs._asm.guitk.menubar.menu", LS_TBREAK] ;
            NSMenu *newMenu = [skin toNSObjectAtIndex:2] ;
            if (newMenu.supermenu) {
                return luaL_argerror(L, 2, "menu is already assigned somewhere else") ;
            }
            if (item.submenu && [skin canPushNSObject:item.submenu]) [skin luaRelease:refTable forNSObject:item.submenu] ;
            [skin luaRetain:refTable forNSObject:newMenu] ;
            item.submenu = newMenu ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 2) {
        item.callbackRef = [skin luaUnref:refTable ref:item.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            item.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (item.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:item.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int menuitem_tag(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, item.tag) ;
    } else {
        item.tag = lua_tointeger(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_representedObject(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.representedObject] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.representedObject = nil ;
        } else {
            item.representedObject = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_allowsKeyEquivalentWhenHidden(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        if (@available(macOS 10.13, *)) {
            lua_pushboolean(L, item.allowsKeyEquivalentWhenHidden) ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:keyWhenHidden - method only available in macOS 10.13 and newer", USERDATA_TAG]] ;
            lua_pushnil(L) ;
        }
    } else {
        if (@available(macOS 10.13, *)) {
            item.allowsKeyEquivalentWhenHidden = (BOOL)lua_toboolean(L, 2) ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:keyWhenHidden - method only available in macOS 10.13 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

// see https://stackoverflow.com/questions/33764644/option-context-menu-in-cocoa
static int menuitem_alternate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, item.alternate) ;
    } else {
        item.alternate = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_keyEquivalent(lua_State *L) {
// do mapping to special characters in lua
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:item.keyEquivalent] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            item.keyEquivalent = @"" ;
        } else {
            item.keyEquivalent = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_keyEquivalentModifierMask(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.separatorItem) {
        if (lua_gettop(L) == 1) {
            lua_pushnil(L) ;
        } else {
            lua_pushvalue(L, 1) ;
        }
        return 1 ;
    }

    if (lua_gettop(L) == 1) {
        NSEventModifierFlags flags = item.keyEquivalentModifierMask ;
        lua_newtable(L) ;
        if ((flags & NSEventModifierFlagShift) == NSEventModifierFlagShift) {
            lua_pushboolean(L, YES) ; lua_setfield(L, -2, "shift") ;
        }
        if ((flags & NSEventModifierFlagControl) == NSEventModifierFlagControl) {
            lua_pushboolean(L, YES) ; lua_setfield(L, -2, "ctrl") ;
        }
        if ((flags & NSEventModifierFlagOption) == NSEventModifierFlagOption) {
            lua_pushboolean(L, YES) ; lua_setfield(L, -2, "alt") ;
        }
        if ((flags & NSEventModifierFlagCommand) == NSEventModifierFlagCommand) {
            lua_pushboolean(L, YES) ; lua_setfield(L, -2, "cmd") ;
        }
        if ((flags & NSEventModifierFlagFunction) == NSEventModifierFlagFunction) {
            lua_pushboolean(L, YES) ; lua_setfield(L, -2, "fn") ;
        }
    } else {
        NSEventModifierFlags flags = 0 ; //(NSEventModifierFlags)0 ;
        if ((lua_getfield(L, 2, "shift") != LUA_TNIL) && lua_toboolean(L, -1)) flags |= NSEventModifierFlagShift ;
        if ((lua_getfield(L, 2, "ctrl")  != LUA_TNIL) && lua_toboolean(L, -1)) flags |= NSEventModifierFlagControl ;
        if ((lua_getfield(L, 2, "alt")   != LUA_TNIL) && lua_toboolean(L, -1)) flags |= NSEventModifierFlagOption ;
        if ((lua_getfield(L, 2, "cmd")   != LUA_TNIL) && lua_toboolean(L, -1)) flags |= NSEventModifierFlagCommand ;
        if ((lua_getfield(L, 2, "fn")    != LUA_TNIL) && lua_toboolean(L, -1)) flags |= NSEventModifierFlagFunction ;
        item.keyEquivalentModifierMask = flags ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menuitem_menu(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.menu) {
        [skin pushNSObject:item.menu] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menuitem_parentItem(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    if (item.parentItem) {
        [skin pushNSObject:item.parentItem] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menuitem_hiddenOrHasHiddenAncestor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, item.hiddenOrHasHiddenAncestor) ;
    return 1 ;
}

static int menuitem_highlighted(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, item.highlighted) ;
    return 1 ;
}

#pragma mark - Module Constants

static int pushSpecialCharacters(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_newtable(L) ;
    unichar c ;
    c = NSUpArrowFunctionKey      ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "up") ;
    c = NSDownArrowFunctionKey    ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "down") ;
    c = NSLeftArrowFunctionKey    ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "left") ;
    c = NSRightArrowFunctionKey   ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "right") ;
    c = NSF1FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f1") ;
    c = NSF2FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f2") ;
    c = NSF3FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f3") ;
    c = NSF4FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f4") ;
    c = NSF5FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f5") ;
    c = NSF6FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f6") ;
    c = NSF7FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f7") ;
    c = NSF8FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f8") ;
    c = NSF9FunctionKey           ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f9") ;
    c = NSF10FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f10") ;
    c = NSF11FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f11") ;
    c = NSF12FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f12") ;
    c = NSF13FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f13") ;
    c = NSF14FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f14") ;
    c = NSF15FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f15") ;
    c = NSF16FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f16") ;
    c = NSF17FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f17") ;
    c = NSF18FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f18") ;
    c = NSF19FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f19") ;
    c = NSF20FunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "f20") ;
//     c = NSDeleteFunctionKey       ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "NSDeleteFunctionKey") ;
    c = NSHomeFunctionKey         ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "home") ;
    c = NSEndFunctionKey          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "end") ;
    c = NSPageUpFunctionKey       ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "pageup") ;
    c = NSPageDownFunctionKey     ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "pagedown") ;
    c = NSClearDisplayFunctionKey ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "padclear") ;
    c = NSHelpFunctionKey         ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "help") ;
    c = NSModeSwitchFunctionKey   ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "fn") ;

    c = NSEnterCharacter          ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "padenter") ;
    c = NSBackspaceCharacter      ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "delete") ;
    c = NSTabCharacter            ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "tab") ;
//     c = NSNewlineCharacter        ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "NSNewlineCharacter") ;
//     c = NSFormFeedCharacter       ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "NSFormFeedCharacter") ;
    c = NSCarriageReturnCharacter ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "return") ;
    c = NSBackTabCharacter        ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "backtab") ;
    c = 0x001b                    ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "escape") ;
    c = NSDeleteCharacter         ; [skin pushNSObject:[NSString stringWithCharacters:&c length:1]] ; lua_setfield(L, -2, "forwarddelete") ;

    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushNSMenuItem(lua_State *L, id obj) {
    NSMenuItem *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(NSMenuItem *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toNSMenuItemFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    NSMenuItem *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge NSMenuItem, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    NSMenuItem *obj = [skin luaObjectAtIndex:1 toClass:"NSMenuItem"] ;
    NSString *title = obj.title ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        NSMenuItem *obj1 = [skin luaObjectAtIndex:1 toClass:"NSMenuItem"] ;
        NSMenuItem *obj2 = [skin luaObjectAtIndex:2 toClass:"NSMenuItem"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    NSMenuItem *obj = get_objectFromUserdata(__bridge_transfer NSMenuItem, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            if (obj.view) {
                if ([skin canPushNSObject:obj.view]) [skin luaRelease:refTable forNSObject:obj.view] ;
                obj.view = nil ;
            }
            if (obj.submenu) {
                if ([skin canPushNSObject:obj.submenu]) [skin luaRelease:refTable forNSObject:obj.submenu] ;
                obj.submenu = nil ;
            }
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
    {"state",            menuitem_state},
    {"indentationLevel", menuitem_indentationLevel},
    {"tooltip",          menuitem_toolTip},
    {"image",            menuitem_image},
    {"mixedStateImage",  menuitem_mixedStateImage},
    {"offStateImage",    menuitem_offStateImage},
    {"onStateImage",     menuitem_onStateImage},
    {"title",            menuitem_title},
    {"enabled",          menuitem_enabled},
    {"hidden",           menuitem_hidden},
    {"view",             menuitem_view},
    {"submenu",          menuitem_submenu},
    {"callback",         menuitem_callback},
    {"tag",              menuitem_tag},
    {"attachment",       menuitem_representedObject},
    {"keyWhenHidden",    menuitem_allowsKeyEquivalentWhenHidden},
    {"alternate",        menuitem_alternate},
    {"keyEquivalent",    menuitem_keyEquivalent},
    {"keyModifiers",     menuitem_keyEquivalentModifierMask},

    {"menu",             menuitem_menu},
    {"parentItem",       menuitem_parentItem},
    {"isHidden",         menuitem_hiddenOrHasHiddenAncestor},
    {"highlighted",      menuitem_highlighted},

    {"__tostring",       userdata_tostring},
    {"__eq",             userdata_eq},
    {"__gc",             userdata_gc},
    {NULL,               NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", menuitem_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_menubar_menuItem(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushNSMenuItem         forClass:"NSMenuItem"];
    [skin registerLuaObjectHelper:toNSMenuItemFromLua forClass:"NSMenuItem"
                                             withUserdataMapping:USERDATA_TAG];

    pushSpecialCharacters(L) ; lua_setfield(L, -2, "_characterMap") ;

    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"state",
        @"indentationLevel",
        @"tooltip",
        @"image",
        @"mixedStateImage",
        @"offStateImage",
        @"onStateImage",
        @"title",
        @"enabled",
        @"hidden",
        @"view",
        @"submenu",
        @"callback",
        @"tag",
        @"attachment",
        @"alternate",
        @"keyEquivalent",
        @"keyModifiers",
    ]] ;
    if (@available(macOS 10.13, *)) {
        lua_pushstring(L, "keyWhenHidden") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    lua_setfield(L, -2, "_propertyList") ;
    lua_pop(L, 1) ;

    return 1;
}
