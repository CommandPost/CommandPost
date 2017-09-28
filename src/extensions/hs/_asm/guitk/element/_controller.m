@import Cocoa ;
@import LuaSkin ;

// NOTE: Should only contain methods which can be applied to all NSControll based elements
//
//       These will be made available to any element which sets _inheritController in its luaopen_* function,
//       so enything which should be kept to a subset of such elements should be coded in the relevant element
//       files and not here.
//
//       If an element file already defines a method that is named here, the existing method will be used for
//       that element -- it will not be replaced by the common method.

static const char * const USERDATA_TAG = "hs._asm.guitk.element._controller" ;

#define CONTROL_SIZE @{ \
    @"regular" : @(NSControlSizeRegular), \
    @"small"   : @(NSControlSizeSmall), \
    @"mini"    : @(NSControlSizeMini), \
}

#define CONTROL_TINT @{ \
    @"default"  : @(NSDefaultControlTint), \
    @"blue"     : @(NSBlueControlTint), \
    @"graphite" : @(NSGraphiteControlTint), \
    @"clear"    : @(NSClearControlTint), \
}

#define TEXT_ALIGNMENT @{                       \
    @"left"      : @(NSTextAlignmentLeft),      \
    @"center"    : @(NSTextAlignmentCenter),    \
    @"right"     : @(NSTextAlignmentRight),     \
    @"justified" : @(NSTextAlignmentJustified), \
    @"natural"   : @(NSTextAlignmentNatural),   \
}

#pragma mark - Common NSController Methods

static int control_textAlignment(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TANY, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *alignment = TEXT_ALIGNMENT[key] ;
        if (alignment) {
            control.alignment = [alignment unsignedIntegerValue] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[TEXT_ALIGNMENT allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *alignment = @(control.alignment) ;
        NSArray *temp = [TEXT_ALIGNMENT allKeysForObject:alignment];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized control tint %@ -- notify developers", USERDATA_TAG, alignment]] ;
            lua_pushnil(L) ;
        }
    }
    return 1;
}

static int control_controlTint(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TANY, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *controlTint = CONTROL_TINT[key] ;
        if (controlTint) {
            control.cell.controlTint = [controlTint unsignedIntegerValue] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[CONTROL_TINT allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *controlTint = @(control.cell.controlTint) ;
        NSArray *temp = [CONTROL_TINT allKeysForObject:controlTint];
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

static int control_controlSize(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TANY, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *controlSize = CONTROL_SIZE[key] ;
        if (controlSize) {
            control.controlSize = [controlSize unsignedIntegerValue] ;
//             [control sizeToFit] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[CONTROL_SIZE allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *controlSize = @(control.controlSize) ;
        NSArray *temp = [CONTROL_SIZE allKeysForObject:controlSize];
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

static int control_highlighted(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, control.highlighted) ;
    } else {
        control.highlighted = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int control_enabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, control.enabled) ;
    } else {
        control.enabled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int control_font(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TANY, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:control.font] ;
    } else {
        control.font = [skin luaObjectAtIndex:2 toClass:"NSFont"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int control_continuous(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    if (lua_type(L, 1) != LUA_TUSERDATA) {
        return luaL_error(L, "ERROR: incorrect type '%s' for argument 1 (expected userdata)", lua_typename(L, lua_type(L, 1))) ;
    }
    NSControl *control = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, control.continuous) ;
    } else {
        control.continuous = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}


#pragma mark - Hammerspoon/Lua Infrastructure

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"font",          control_font},
    {"highlight",     control_highlighted},
    {"enabled",       control_enabled},
    {"controlSize",   control_controlSize},
    {"controlTint",   control_controlTint},
    {"textAlignment", control_textAlignment},
    {"continuous",    control_continuous},
    {NULL,            NULL}
};

int luaopen_hs__asm_guitk_element__controller(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

    [skin pushNSObject:@[
        @"font",
        @"highlight",
        @"enabled",
        @"controlTint",
        @"controlSize",
        @"textAlignment",
        @"continuous",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;

    return 1;
}
