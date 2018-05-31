@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.menubar.menu" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static inline NSPoint PointWithFlippedYCoordinate(NSPoint thePoint) {
    return NSMakePoint(thePoint.x, [[NSScreen screens][0] frame].size.height - thePoint.y) ;
}

@interface HSMenu : NSMenu <NSMenuDelegate>
@property int  callbackRef ;
@property int  selfRefCount ;
@property BOOL trackOpen ;
@property BOOL trackClose ;
@property BOOL trackUpdate ;
@property BOOL trackHighlight ;
@end

@implementation HSMenu

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithTitle:title] ;
    if (self) {
        _callbackRef    = LUA_NOREF ;
        _selfRefCount   = 0 ;
        _trackOpen      = NO ;
        _trackClose     = NO ;
        _trackUpdate    = YES ;
        _trackHighlight = NO ;

        self.autoenablesItems = NO ;
        self.delegate         = self ;
    }
    return self ;
}

- (void)performCallbackMessage:(NSString *)message with:(id)data {
    if (_callbackRef != LUA_NOREF) {
        LuaSkin   *skin = [LuaSkin shared] ;
        lua_State *L    = skin.L ;
        int       count = 2 ;
        [skin pushLuaRef:refTable ref:_callbackRef] ;
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

- (void)menuWillOpen:(__unused NSMenu *)menu {
    if (_trackOpen) [self performCallbackMessage:@"open" with:nil] ;
}

- (void)menuDidClose:(__unused NSMenu *)menu {
    if (_trackClose) [self performCallbackMessage:@"close" with:nil] ;
}

- (void) menuNeedsUpdate:(__unused NSMenu *)menu {
    if (_trackUpdate) [self performCallbackMessage:@"update" with:nil] ;
}

- (void)menu:(__unused NSMenu *)menu willHighlightItem:(NSMenuItem *)item {
    if (_trackHighlight) [self performCallbackMessage:@"highlight" with:item] ;
}

// - (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action;
// - (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel;
// - (NSRect)confinementRectForMenu:(NSMenu *)menu onScreen:(NSScreen *)screen;
// - (NSInteger)numberOfItemsInMenu:(NSMenu *)menu;

@end

#pragma mark - Module Functions

static int menu_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    NSString *title = (lua_gettop(L)) == 1 ? [skin toNSObjectAtIndex:1] : [[NSUUID UUID] UUIDString] ;

    HSMenu *menu = [[HSMenu alloc] initWithTitle:title] ;
    if (menu) {
        [skin pushNSObject:menu] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

// make sure to document that for a dynamically generated menu, the menu structure should be rebuilt
// during the update callback, not the open one (which is why update is the first flag)
static int menu_callbackFlags(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, menu.trackUpdate) ;
        lua_pushboolean(L, menu.trackOpen) ;
        lua_pushboolean(L, menu.trackClose) ;
        lua_pushboolean(L, menu.trackHighlight) ;
        return 4 ;
    } else {
        // this works because an absent item will be LUA_TNONE
        if (lua_type(L, 2) == LUA_TBOOLEAN) menu.trackUpdate    = (BOOL)lua_toboolean(L, 2) ;
        if (lua_type(L, 3) == LUA_TBOOLEAN) menu.trackOpen      = (BOOL)lua_toboolean(L, 3) ;
        if (lua_type(L, 4) == LUA_TBOOLEAN) menu.trackClose     = (BOOL)lua_toboolean(L, 4) ;
        if (lua_type(L, 5) == LUA_TBOOLEAN) menu.trackHighlight = (BOOL)lua_toboolean(L, 5) ;
        lua_pushvalue(L, 1) ;
        return 1 ;
    }
}

static int menu_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        menu.callbackRef = [skin luaUnref:refTable ref:menu.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            menu.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (menu.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:menu.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int menu_showsStateColumn(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, menu.showsStateColumn) ;
    } else {
        menu.showsStateColumn = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menu_highlightedItem(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (menu.highlightedItem) {
        [skin pushNSObject:menu.highlightedItem] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_size(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    [skin pushNSSize:menu.size] ;
    return 1 ;
}

static int menu_popupMenu(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TBREAK | LS_TVARARG] ;
    HSMenu     *menu    = [skin toNSObjectAtIndex:1] ;
    NSPoint    location = PointWithFlippedYCoordinate([skin tableToPointAtIndex:2]) ;
    NSMenuItem *item    = nil ;

    BOOL darkMode = false ;
    int itemIdx = 3 ;

    if (lua_gettop(L) > 2) {
        if ((lua_type(L, 3) == LUA_TBOOLEAN) || (lua_type(L, 3) == LUA_TNIL)) {
            if (lua_type(L, 3) == LUA_TBOOLEAN) {
                darkMode = (BOOL)lua_toboolean(L, 3) ;
            } else {
                NSString *ifStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] ;
                darkMode = (ifStyle && [ifStyle isEqualToString:@"Dark"]) ;
            }
            lua_remove(L, 3) ;
            itemIdx++ ;
        }
    }
    if (lua_gettop(L) > 2) {
        switch(lua_type(L, 3)) {
            case LUA_TUSERDATA:
                [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TUSERDATA, "hs._asm.guitk.menubar.menu.item", LS_TBREAK] ;
                item = [skin toNSObjectAtIndex:3] ;
                break ;
            case LUA_TNUMBER:
                [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
                NSInteger idx = lua_tointeger(L, 3) ;
                if ((idx < 1) || (idx > menu.numberOfItems)) {
                    return luaL_argerror(L, itemIdx, "index out of bounds") ;
                }
                item = [menu itemAtIndex:(idx - 1)] ;
                break ;
            default:
                return luaL_argerror(L, itemIdx, "expected integer index or hs._asm.guitk.menubar.menu.item userdata") ;
        }
    }
    if (item && ![menu isEqualTo:item.menu]) return luaL_argerror(L, itemIdx, "specified item is not in this menu") ;

// TODO: test put in background thread so no blocking? Actually only blocks things in default
//       runloop mode -- console, timer, few other things... want to to move timers at least
//       out of default and into common modes and see what breaks; should check other stuff as well.

//     [menu popUpMenuPositioningItem:item atLocation:location inView:nil] ;

    // support darkMode for popup menus
    NSRect contentRect = NSMakeRect(location.x, location.y, 0, 0) ;
    NSWindow *tmpWindow = [[NSWindow alloc] initWithContentRect:contentRect
                                                      styleMask:0
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO] ;
    tmpWindow.releasedWhenClosed = NO ;
    tmpWindow.appearance = [NSAppearance appearanceNamed:(darkMode ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight)] ;
    [tmpWindow orderFront:nil] ;
    [menu popUpMenuPositioningItem:item atLocation:NSMakePoint(0, 0) inView:tmpWindow.contentView] ;
    [tmpWindow close] ;

    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int menu_minimumWidth(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu     *menu    = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, menu.minimumWidth) ;
    } else {
        CGFloat width = lua_tonumber(L, 2) ;
        menu.minimumWidth = (width < 0) ? 0 : width ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menu_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu     *menu    = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:menu.title] ;
    } else {
        menu.title = [skin toNSObjectAtIndex:2] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menu_font(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:menu.font] ;
    } else {
        menu.font = [skin luaObjectAtIndex:2 toClass:"NSFont"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int menu_supermenu(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (menu.supermenu) {
        [skin pushNSObject:menu.supermenu] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_numberOfItems(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    lua_pushinteger(L, menu.numberOfItems) ;
    return 1 ;
}

static int menu_itemArray(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;

    if (menu.itemArray) {
        [skin pushNSObject:menu.itemArray] ;
    } else {
        lua_newtable(L) ;
    }
    return 1 ;
}

static int menu_insertItemAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TUSERDATA, "hs._asm.guitk.menubar.menu.item",
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TBREAK] ;
    HSMenu     *menu = [skin toNSObjectAtIndex:1] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:2] ;
    NSInteger idx = (lua_type(L, -1) == LUA_TNUMBER) ? (lua_tointeger(L, -1) - 1) : menu.numberOfItems ;
    if ((idx < 0) || (idx > menu.numberOfItems)) return luaL_argerror(L, lua_gettop(L), "index out of bounds") ;

    if (item.menu) {
        return luaL_argerror(L, 2, "item already assigned to a menu") ;
    }

    [skin luaRetain:refTable forNSObject:item] ;
    [menu insertItem:item atIndex:idx] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int menu_itemAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    HSMenu     *menu = [skin toNSObjectAtIndex:1] ;
    NSInteger  idx   = lua_tointeger(L, 2) ;
    NSMenuItem *item = nil ;

    if (!((idx < 1) || (idx > menu.numberOfItems))) item = [menu itemAtIndex:(idx - 1)] ;

    if (item) {
        [skin pushNSObject:item] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_removeItemAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSMenu     *menu = [skin toNSObjectAtIndex:1] ;
    NSInteger idx = ((lua_type(L, -1) == LUA_TNUMBER) ? lua_tointeger(L, -1) : menu.numberOfItems) - 1 ;
    if ((idx < 0) || (idx >= menu.numberOfItems)) return luaL_argerror(L, lua_gettop(L), "index out of bounds") ;

    NSMenuItem *item = [menu itemAtIndex:idx] ;
    [skin luaRelease:refTable forNSObject:item] ;
    [menu removeItem:item] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int menu_removeAll(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu     *menu = [skin toNSObjectAtIndex:1] ;

    if (menu.itemArray) {
        for (NSMenuItem *item in menu.itemArray) [skin luaRelease:refTable forNSObject:item] ;
        [menu removeAllItems] ;
    }
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int menu_indexOfItem(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs._asm.guitk.menubar.menu.item", LS_TBREAK] ;
    HSMenu     *menu = [skin toNSObjectAtIndex:1] ;
    NSMenuItem *item = [skin toNSObjectAtIndex:2] ;

    NSInteger idx = [menu indexOfItem:item] + 1 ;
    if (idx > 0) {
        lua_pushinteger(L, idx) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_indexOfItemWithRepresentedObject(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;
    id     obj   = (lua_type(L, 2) != LUA_TNIL) ? [skin toNSObjectAtIndex:2] : nil ;

    NSInteger idx = [menu indexOfItemWithRepresentedObject:obj] + 1 ;
    if (idx > 0) {
        lua_pushinteger(L, idx) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_indexOfItemWithSubmenu(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSMenu *menu = [skin toNSObjectAtIndex:1] ;
    HSMenu *item = [skin toNSObjectAtIndex:2] ;

    NSInteger idx = [menu indexOfItemWithSubmenu:item] + 1 ;
    if (idx > 0) {
        lua_pushinteger(L, idx) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_indexOfItemWithTag(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    HSMenu    *menu = [skin toNSObjectAtIndex:1] ;
    NSInteger tag   = lua_tointeger(L, 2) ;

    NSInteger idx = [menu indexOfItemWithTag:tag] + 1 ;
    if (idx > 0) {
        lua_pushinteger(L, idx) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int menu_indexOfItemWithTitle(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    HSMenu   *menu  = [skin toNSObjectAtIndex:1] ;
    NSString *title = [skin toNSObjectAtIndex:2] ;

    NSInteger idx = [menu indexOfItemWithTitle:title] + 1 ;
    if (idx > 0) {
        lua_pushinteger(L, idx) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

// // ?? - (void)performActionForItemAtIndex:(NSInteger)index;

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSMenu(lua_State *L, id obj) {
    HSMenu *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSMenu *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSMenuFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSMenu *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSMenu, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSMenu *obj = [skin luaObjectAtIndex:1 toClass:"HSMenu"] ;
    NSString *title = obj.title ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSMenu *obj1 = [skin luaObjectAtIndex:1 toClass:"HSMenu"] ;
        HSMenu *obj2 = [skin luaObjectAtIndex:2 toClass:"HSMenu"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSMenu *obj = get_objectFromUserdata(__bridge_transfer HSMenu, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef    = [skin luaUnref:refTable ref:obj.callbackRef] ;
            obj.delegate = nil ;
            if (obj.itemArray) {
                for (NSMenuItem *item in obj.itemArray) [skin luaRelease:refTable forNSObject:item] ;
                [obj removeAllItems] ;
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
    {"highlightedItem",     menu_highlightedItem},
    {"callback",            menu_callback},
    {"showsState",          menu_showsStateColumn},
    {"popupMenu",           menu_popupMenu},
    {"size",                menu_size},
    {"minimumWidth",        menu_minimumWidth},
    {"title",               menu_title},
    {"font",                menu_font},
    {"supermenu",           menu_supermenu},
    {"items",               menu_itemArray},
    {"itemCount",           menu_numberOfItems},
    {"insert",              menu_insertItemAtIndex},
    {"itemAtIndex",         menu_itemAtIndex},
    {"remove",              menu_removeItemAtIndex},
    {"removeAll",           menu_removeAll},
    {"indexOfItem",         menu_indexOfItem},
    {"indexWithAttachment", menu_indexOfItemWithRepresentedObject},
    {"indexWithSubmenu",    menu_indexOfItemWithSubmenu},
    {"indexWithTag",        menu_indexOfItemWithTag},
    {"indexWithTitle",      menu_indexOfItemWithTitle},
    {"callbackFlags",       menu_callbackFlags},

    {"__tostring",          userdata_tostring},
    {"__eq",                userdata_eq},
    {"__gc",                userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", menu_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_menubar_menu(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSMenu         forClass:"HSMenu"];
    [skin registerLuaObjectHelper:toHSMenuFromLua forClass:"HSMenu"
                                             withUserdataMapping:USERDATA_TAG];

    return 1;
}
