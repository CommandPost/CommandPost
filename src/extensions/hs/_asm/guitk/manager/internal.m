// TODO:
//   document
//
@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.manager" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static NSNumber *convertPercentageStringToNumber(NSString *stringValue) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale] ;

    formatter.numberStyle = NSNumberFormatterDecimalStyle ;
    NSNumber *tmpValue = [formatter numberFromString:stringValue] ;
    if (!tmpValue) {
        formatter.numberStyle = NSNumberFormatterPercentStyle ;
        tmpValue = [formatter numberFromString:stringValue] ;
    }
    // just to be sure, let's also check with the en_US locale
    if (!tmpValue) {
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"] ;
        formatter.numberStyle = NSNumberFormatterDecimalStyle ;
        tmpValue = [formatter numberFromString:stringValue] ;
        if (!tmpValue) {
            formatter.numberStyle = NSNumberFormatterPercentStyle ;
            tmpValue = [formatter numberFromString:stringValue] ;
        }
    }
    return tmpValue ;
}

@interface HSASMGUITKManager : NSView
@property int        selfRefCount ;
@property int        passthroughCallbackRef ;
@property NSMapTable *subviewDetails ;
@property NSColor    *frameDebugColor ;
@end

@implementation HSASMGUITKManager

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect] ;
    if (self) {
        _selfRefCount           = 0 ;
        _passthroughCallbackRef = LUA_NOREF ;
        _subviewDetails         = [NSMapTable strongToStrongObjectsMapTable] ;
        _frameDebugColor        = nil ;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managerFrameChanged:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:nil] ;

    }
    return self ;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewFrameDidChangeNotification
                                                  object:nil] ;
}

- (void) managerFrameChanged:(NSNotification *)notification {
    if ([notification.object isEqualTo:self]) {
        [self.subviews enumerateObjectsUsingBlock:^(NSView *view, __unused NSUInteger idx, __unused BOOL *stop) {
            [self updateFrameFor:view] ;
        }] ;
    }
}

- (void) updateFrameFor:(NSView *)view {
    NSMutableDictionary *details = [_subviewDetails objectForKey:view] ;
    NSRect frame = view.frame ;
//     [LuaSkin logInfo:[NSString stringWithFormat:@"oldFrame: %@", NSStringFromRect(frame)]] ;
    if (details[@"h"]) {
        NSNumber *value = details[@"h"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.height * value.doubleValue) ;
        }
        frame.size.height = value.doubleValue ;
    } else {
        frame.size.height = view.fittingSize.height ;
    }
    if (details[@"w"]) {
        NSNumber *value = details[@"w"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.width * value.doubleValue) ;
        }
        frame.size.width = value.doubleValue ;
    } else {
        frame.size.width = view.fittingSize.width ;
    }
    if (details[@"x"]) {
        NSNumber *value = details[@"x"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.width * value.doubleValue) ;
        }
        frame.origin.x = value.doubleValue ;
    }
    if (details[@"y"]) {
        NSNumber *value = details[@"y"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.height * value.doubleValue) ;
        }
        frame.origin.y = value.doubleValue ;
    }
    if (details[@"cX"]) {
        NSNumber *value = details[@"cX"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.width * value.doubleValue) ;
        }
        frame.origin.x = value.doubleValue - (frame.size.width / 2) ;
    }
    if (details[@"cY"]) {
        NSNumber *value = details[@"cY"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.height * value.doubleValue) ;
        }
        frame.origin.y = value.doubleValue - (frame.size.height / 2) ;
    }
//     [LuaSkin logInfo:[NSString stringWithFormat:@"newFrame: %@", NSStringFromRect(frame)]] ;
    view.frame = frame ;
}

- (BOOL)isFlipped { return YES; }

- (NSSize)fittingSize {
    NSSize fittedContentSize = NSZeroSize ;

    if ([self.subviews count] > 0) {
        __block NSPoint bottomRight = NSZeroPoint ;
        [self.subviews enumerateObjectsUsingBlock:^(NSView *view, __unused NSUInteger idx, __unused BOOL *stop) {
            NSRect frame             = view.frame ;
            NSPoint frameBottomRight = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height) ;
            NSSize viewFittingSize   = view.fittingSize ;
            if (!CGSizeEqualToSize(viewFittingSize, NSZeroSize)) {
                frameBottomRight = NSMakePoint(frame.origin.x + viewFittingSize.width, frame.origin.y + viewFittingSize.height) ;
            }
            if (frameBottomRight.x > bottomRight.x) bottomRight.x = frameBottomRight.x ;
            if (frameBottomRight.y > bottomRight.y) bottomRight.y = frameBottomRight.y ;
        }] ;

        fittedContentSize = NSMakeSize(bottomRight.x, bottomRight.y) ;
    }
    return fittedContentSize ;
}

- (void)drawRect:(NSRect)dirtyRect {
    if (_frameDebugColor) {
        NSDisableScreenUpdates() ;
        NSGraphicsContext* gc = [NSGraphicsContext currentContext];
        [gc saveGraphicsState];

        [NSBezierPath setDefaultLineWidth:2.0] ;
        [_frameDebugColor setStroke] ;
        [self.subviews enumerateObjectsUsingBlock:^(NSView *view, __unused NSUInteger idx, __unused BOOL *stop) {
            NSRect frame = view.frame ;
            // Since this if for debugging frames, check if a size component approaches/is effectively invisible... .5 point should do
            if ((frame.size.height < 0.5) || (frame.size.width < 0.5)) {
                NSPoint topLeft = NSMakePoint(frame.origin.x, frame.origin.y) ;
                NSPoint btRight = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height) ;
            // comparing floats is problematic, but for our purposes, if the difference is less than 1/2 point this component has no visible width
                if (btRight.x - topLeft.x < 0.5) {
                    topLeft.x -= 5 ;
                    btRight.x += 5 ;
                }
            // comparing floats is problematic, but for our purposes, if the difference is less than 1/2 point this component has no visible height
                if (btRight.y - topLeft.y < 0.5) {
                    topLeft.y -= 5 ;
                    btRight.y += 5 ;
                }
                [NSBezierPath strokeLineFromPoint:topLeft toPoint:btRight] ;
                [NSBezierPath strokeLineFromPoint:NSMakePoint(topLeft.x, btRight.y) toPoint:NSMakePoint(btRight.x, topLeft.y)] ;
            } else {
                [NSBezierPath strokeRect:view.frame] ;
            }
        }] ;
        [gc restoreGraphicsState];
        NSEnableScreenUpdates() ;
    }
    [super drawRect:dirtyRect] ;
}

// perform callback for subviews which don't have a callback defined; see button.m for how to allow this chaining
- (void)preformPassthroughCallback:(NSArray *)arguments {
    if (_passthroughCallbackRef != LUA_NOREF) {
        LuaSkin *skin    = [LuaSkin shared] ;
        int     argCount = 1 ;

        [skin pushLuaRef:refTable ref:_passthroughCallbackRef] ;
        [skin pushNSObject:self] ;
        if (arguments) {
            [skin pushNSObject:arguments] ;
            argCount += 1 ;
        }
        if (![skin protectedCallAndTraceback:argCount nresults:0]) {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            lua_pop(skin.L, 1) ;
            [skin logError:[NSString stringWithFormat:@"%s:passthroughCallback error:%@", USERDATA_TAG, errorMessage]] ;
        }
    } else {
        // allow next responder a chance since we don't have a callback set
        id nextInChain = [self nextResponder] ;
        if (nextInChain) {
            SEL passthroughCallback = NSSelectorFromString(@"preformPassthroughCallback:") ;
            if ([nextInChain respondsToSelector:passthroughCallback]) {
                [nextInChain performSelectorOnMainThread:passthroughCallback
                                              withObject:@[ self, arguments ]
                                           waitUntilDone:YES] ;
            }
        }
    }
}

- (void)didAddSubview:(NSView *)subview {
    LuaSkin   *skin = [LuaSkin shared] ;
//     [skin logInfo:[NSString stringWithFormat:@"%s:didAddSubview - added %@", USERDATA_TAG, subview]] ;
    // increase lua reference count of subview so it won't be collected
    if (![skin luaRetain:refTable forNSObject:subview]) {
        [skin logDebug:[NSString stringWithFormat:@"%s:didAddSubview - unrecognized subview added:%@", USERDATA_TAG, subview]] ;
    }
}

- (void)willRemoveSubview:(NSView *)subview {
    LuaSkin *skin = [LuaSkin shared] ;
//     [skin logInfo:[NSString stringWithFormat:@"%s:willRemoveSubview - removed %@", USERDATA_TAG, subview]] ;
    [skin luaRelease:refTable forNSObject:subview] ;
}

@end

static void validateElementDetailsTable(lua_State *L, int idx, NSMutableDictionary *details) {
    LuaSkin *skin = [LuaSkin shared] ;
    idx = lua_absindex(L, idx) ;
    if (lua_type(L, idx) == LUA_TTABLE) {
        if (lua_getfield(L, idx, "id") == LUA_TSTRING) {
            details[@"id"] = [skin toNSObjectAtIndex:-1] ;
        } else if ((lua_type(L, -1) == LUA_TBOOLEAN) && !lua_toboolean(L, -1)) {
            details[@"id"] = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected string or false for id key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "cX") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"cX"] = [skin toNSObjectAtIndex:-1] ;
                details[@"x"]  = nil ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for cX key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"cX"] = [skin toNSObjectAtIndex:-1] ;
            details[@"x"]  = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number or string for cX key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "cY") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"cY"] = [skin toNSObjectAtIndex:-1] ;
                details[@"y"]  = nil ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for cY key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"cY"] = [skin toNSObjectAtIndex:-1] ;
            details[@"y"]  = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number or string for cY key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "x") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"x"] = [skin toNSObjectAtIndex:-1] ;
                details[@"cX"]  = nil ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for x key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"x"] = [skin toNSObjectAtIndex:-1] ;
            details[@"cX"]  = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number or string for x key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "y") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"y"] = [skin toNSObjectAtIndex:-1] ;
                details[@"cY"]  = nil ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for y key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"y"] = [skin toNSObjectAtIndex:-1] ;
            details[@"cY"]  = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number or string for y key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "h") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"h"] = [skin toNSObjectAtIndex:-1] ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for h key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"h"] = [skin toNSObjectAtIndex:-1] ;
        } else if ((lua_type(L, -1) == LUA_TBOOLEAN) && !lua_toboolean(L, -1)) {
            details[@"h"] = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number, string, or false for h key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

        if (lua_getfield(L, idx, "w") == LUA_TSTRING) {
            NSString *value = [skin toNSObjectAtIndex:-1] ;
            if (convertPercentageStringToNumber(value)) {
                details[@"w"] = [skin toNSObjectAtIndex:-1] ;
            } else {
                [skin logWarn:[NSString stringWithFormat:@"%s percentage string %@ invalid for w key in element details", USERDATA_TAG, value]] ;
            }
        } else if (lua_type(L, -1) == LUA_TNUMBER) {
            details[@"w"] = [skin toNSObjectAtIndex:-1] ;
        } else if ((lua_type(L, -1) == LUA_TBOOLEAN) && !lua_toboolean(L, -1)) {
            details[@"w"] = nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected number, string, or false for w key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
        }
        lua_pop(L, 1) ;

    } else {
        [skin logWarn:[NSString stringWithFormat:@"%s expected table for element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, idx))]] ;
    }
}

static void adjustElementDetailsTable(lua_State *L, HSASMGUITKManager *manager, NSView *element, NSDictionary *changes) {
    LuaSkin *skin = [LuaSkin shared] ;
    NSMutableDictionary *details = [manager.subviewDetails objectForKey:element] ;
    if (!details) details = [[NSMutableDictionary alloc] init] ;
    [skin pushNSObject:changes] ;
    validateElementDetailsTable(L, -1, details) ;
    [manager.subviewDetails setObject:details forKey:element] ;
    [manager updateFrameFor:element] ;
}

#pragma mark - Module Functions

static int manager_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKManager *manager = [[HSASMGUITKManager alloc] initWithFrame:frameRect] ;
    if (manager) {
        [skin pushNSObject:manager] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

static int manager__debugFrames(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TNIL | LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    if (lua_gettop(L) == 1) {
        if (manager.frameDebugColor) {
            [skin pushNSObject:manager.frameDebugColor] ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TTABLE) {
            manager.frameDebugColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        } else {
            if (lua_toboolean(L, 2)) {
                manager.frameDebugColor = [NSColor keyboardFocusIndicatorColor] ;
            } else {
                manager.frameDebugColor = nil ;
            }
        }
        manager.needsDisplay = YES ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int manager_autoPosition(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    [manager managerFrameChanged:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:manager]] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_elementAutoPosition(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *item = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!item || ![item isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:item]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }
    [manager updateFrameFor:item] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_insertElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TTABLE | LS_TOPTIONAL, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *item = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!item || ![item isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if ([item isDescendantOf:manager]) {
        return luaL_argerror(L, 2, "element already managed by this content manager or one of its subviews") ;
    }

    NSInteger idx = (lua_type(L, -1) == LUA_TNUMBER) ? (lua_tointeger(L, -1) - 1) : (NSInteger)manager.subviews.count ;
    if ((idx < 0) || (idx > (NSInteger)manager.subviews.count)) return luaL_argerror(L, lua_gettop(L), "insert index out of bounds") ;

    NSMutableDictionary *details = [[NSMutableDictionary alloc] init] ;
    if (manager.subviews.count > 0) {
        NSRect lastElementFrame = manager.subviews.lastObject.frame ;
        details[@"x"] = @(lastElementFrame.origin.x) ;
        details[@"y"] = @(lastElementFrame.origin.y + lastElementFrame.size.height) ;
    } else {
        details[@"x"] = @(0) ;
        details[@"y"] = @(0) ;
    }
    if (lua_type(L, 3) == LUA_TTABLE) validateElementDetailsTable(L, 3, details) ;

    NSMutableArray *subviewHolder = [manager.subviews mutableCopy] ;
    [subviewHolder insertObject:item atIndex:(NSUInteger)idx] ;
    manager.subviews = subviewHolder ;
    adjustElementDetailsTable(L, manager, item, details) ;

    // Comparing floats is problematic; but if the item is effectively invisible, warn if not set on purpose
    if ((item.fittingSize.height < 0.1) && !details[@"h"]) {
        [skin logWarn:[NSString stringWithFormat:@"%s:insert - height not specified and default height for element is 0", USERDATA_TAG]] ;
    }
    if ((item.fittingSize.width < 0.1)  && !details[@"w"]) {
        [skin logWarn:[NSString stringWithFormat:@"%s:insert - width not specified and default width for element is 0", USERDATA_TAG]] ;
    }

    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_removeElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSInteger idx = ((lua_type(L, 2) == LUA_TNUMBER) ? lua_tointeger(L, 2) : (NSInteger)manager.subviews.count) - 1 ;
    if ((idx < 0) || (idx >= (NSInteger)manager.subviews.count)) return luaL_argerror(L, lua_gettop(L), "remove index out of bounds") ;

    NSMutableArray *subviewHolder = [manager.subviews mutableCopy] ;
    [subviewHolder removeObjectAtIndex:(NSUInteger)idx] ;
    manager.subviews = subviewHolder ;

    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_moveElementAbove(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TANY, LS_TNUMBER | LS_TSTRING | LS_TOPTIONAL, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *element1 = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!element1 || ![element1 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element1]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }
    NSView *element2 = (lua_type(L, 3) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:3] : nil ;
    if (!element2 || ![element2 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 3, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element2]) {
        return luaL_argerror(L, 3, "element not managed by this content manager") ;
    }
    CGFloat  padding = ((lua_gettop(L) > 3) && (lua_type(L, 4) == LUA_TNUMBER)) ? lua_tonumber(L, 4) : 0.0 ;
    NSString *where  = (lua_type(L, -1) == LUA_TSTRING) ? [skin toNSObjectAtIndex:-1] : @"flushLeft" ;

    NSRect elementFrame = element1.frame ;
    NSRect anchorFrame  = element2.frame ;

    elementFrame.origin.y = anchorFrame.origin.y - (elementFrame.size.height + padding) ;
    if ([where isEqualToString:@"flushLeft"]) {
        elementFrame.origin.x = anchorFrame.origin.x ;
    } else if ([where isEqualToString:@"centered"]) {
        elementFrame.origin.x = anchorFrame.origin.x + (anchorFrame.size.width - elementFrame.size.width) / 2 ;
    } else if ([where isEqualToString:@"flushRight"]) {
        elementFrame.origin.x = anchorFrame.origin.x + anchorFrame.size.width - elementFrame.size.width ;
    } else {
        return luaL_argerror(L, lua_gettop(L), "expected flushLeft, centered, or flushRight") ;
    }
    adjustElementDetailsTable(L, manager, element1, @{ @"x" : @(elementFrame.origin.x), @"y" : @(elementFrame.origin.y) }) ;
    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_moveElementBelow(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TANY, LS_TNUMBER | LS_TSTRING | LS_TOPTIONAL, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *element1 = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!element1 || ![element1 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element1]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }
    NSView *element2 = (lua_type(L, 3) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:3] : nil ;
    if (!element2 || ![element2 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 3, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element2]) {
        return luaL_argerror(L, 3, "element not managed by this content manager") ;
    }
    CGFloat  padding = ((lua_gettop(L) > 3) && (lua_type(L, 4) == LUA_TNUMBER)) ? lua_tonumber(L, 4) : 0.0 ;
    NSString *where  = (lua_type(L, -1) == LUA_TSTRING) ? [skin toNSObjectAtIndex:-1] : @"flushLeft" ;

    NSRect elementFrame = element1.frame ;
    NSRect anchorFrame  = element2.frame ;

    elementFrame.origin.y = anchorFrame.origin.y + anchorFrame.size.height + padding ;
    if ([where isEqualToString:@"flushLeft"]) {
        elementFrame.origin.x = anchorFrame.origin.x ;
    } else if ([where isEqualToString:@"centered"]) {
        elementFrame.origin.x = anchorFrame.origin.x + (anchorFrame.size.width - elementFrame.size.width) / 2 ;
    } else if ([where isEqualToString:@"flushRight"]) {
        elementFrame.origin.x = anchorFrame.origin.x + anchorFrame.size.width - elementFrame.size.width ;
    } else {
        return luaL_argerror(L, lua_gettop(L), "expected flushLeft, centered, or flushRight") ;
    }
    adjustElementDetailsTable(L, manager, element1, @{ @"x" : @(elementFrame.origin.x), @"y" : @(elementFrame.origin.y) }) ;
    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_moveElementLeftOf(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TANY, LS_TNUMBER | LS_TSTRING | LS_TOPTIONAL, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *element1 = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!element1 || ![element1 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element1]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }
    NSView *element2 = (lua_type(L, 3) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:3] : nil ;
    if (!element2 || ![element2 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 3, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element2]) {
        return luaL_argerror(L, 3, "element not managed by this content manager") ;
    }
    CGFloat  padding = ((lua_gettop(L) > 3) && (lua_type(L, 4) == LUA_TNUMBER)) ? lua_tonumber(L, 4) : 0.0 ;
    NSString *where  = (lua_type(L, -1) == LUA_TSTRING) ? [skin toNSObjectAtIndex:-1] : @"flushTop" ;

    NSRect elementFrame = element1.frame ;
    NSRect anchorFrame  = element2.frame ;

    elementFrame.origin.x = anchorFrame.origin.x - (elementFrame.size.width + padding) ;
    if ([where isEqualToString:@"flushTop"]) {
        elementFrame.origin.y = anchorFrame.origin.y ;
    } else if ([where isEqualToString:@"centered"]) {
        elementFrame.origin.y = anchorFrame.origin.y + (anchorFrame.size.height - elementFrame.size.height) / 2 ;
    } else if ([where isEqualToString:@"flushBottom"]) {
        elementFrame.origin.y = anchorFrame.origin.y + anchorFrame.size.height - elementFrame.size.height ;
    } else {
        return luaL_argerror(L, lua_gettop(L), "expected flushTop, centered, or flushBottom") ;
    }
    adjustElementDetailsTable(L, manager, element1, @{ @"x" : @(elementFrame.origin.x), @"y" : @(elementFrame.origin.y) }) ;
    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_moveElementRightOf(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TANY, LS_TNUMBER | LS_TSTRING | LS_TOPTIONAL, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *element1 = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!element1 || ![element1 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element1]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }
    NSView *element2 = (lua_type(L, 3) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:3] : nil ;
    if (!element2 || ![element2 isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 3, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:element2]) {
        return luaL_argerror(L, 3, "element not managed by this content manager") ;
    }
    CGFloat  padding = ((lua_gettop(L) > 3) && (lua_type(L, 4) == LUA_TNUMBER)) ? lua_tonumber(L, 4) : 0.0 ;
    NSString *where  = (lua_type(L, -1) == LUA_TSTRING) ? [skin toNSObjectAtIndex:-1] : @"flushTop" ;

    NSRect elementFrame = element1.frame ;
    NSRect anchorFrame  = element2.frame ;

    elementFrame.origin.x = anchorFrame.origin.x + anchorFrame.size.width + padding ;
    if ([where isEqualToString:@"flushTop"]) {
        elementFrame.origin.y = anchorFrame.origin.y ;
    } else if ([where isEqualToString:@"centered"]) {
        elementFrame.origin.y = anchorFrame.origin.y + (anchorFrame.size.height - elementFrame.size.height) / 2 ;
    } else if ([where isEqualToString:@"flushBottom"]) {
        elementFrame.origin.y = anchorFrame.origin.y + anchorFrame.size.height - elementFrame.size.height ;
    } else {
        return luaL_argerror(L, lua_gettop(L), "expected flushTop, centered, or flushBottom") ;
    }
    adjustElementDetailsTable(L, manager, element1, @{ @"x" : @(elementFrame.origin.x), @"y" : @(elementFrame.origin.y) }) ;
    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_elementFittingSize(lua_State *L) {
// This is a method so it can be inherited by elements, but it doesn't really have to be
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TBREAK] ;
//     HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *item = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!item || ![item isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
//     if (![manager.subviews containsObject:item]) {
//         return luaL_argerror(L, 2, "element not managed by this content manager") ;
//     }
    [skin pushNSSize:item.fittingSize] ;
    return 1 ;
}

static int manager_sizeToFit(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    CGFloat hPadding = (lua_gettop(L) > 1) ? lua_tonumber(L, 2) : 0.0 ;
    CGFloat vPadding = (lua_gettop(L) > 2) ? lua_tonumber(L, 3) : ((lua_gettop(L) > 1) ? hPadding : 0.0) ;

    if (manager.subviews.count > 0) {
        __block NSPoint topLeft     = manager.subviews.firstObject.frame.origin ;
        __block NSPoint bottomRight = NSZeroPoint ;
        [manager.subviews enumerateObjectsUsingBlock:^(NSView *view, __unused NSUInteger idx, __unused BOOL *stop) {
            NSRect frame = view.frame ;
            if (frame.origin.x < topLeft.x) topLeft.x = frame.origin.x ;
            if (frame.origin.y < topLeft.y) topLeft.y = frame.origin.y ;
            NSPoint frameBottomRight = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height) ;
            if (frameBottomRight.x > bottomRight.x) bottomRight.x = frameBottomRight.x ;
            if (frameBottomRight.y > bottomRight.y) bottomRight.y = frameBottomRight.y ;
        }] ;
        [manager.subviews enumerateObjectsUsingBlock:^(NSView *view, __unused NSUInteger idx, __unused BOOL *stop) {
            NSRect frame = view.frame ;
            frame.origin.x = frame.origin.x + hPadding - topLeft.x ;
            frame.origin.y = frame.origin.y + vPadding - topLeft.y ;
            adjustElementDetailsTable(L, manager, view, @{ @"x" : @(frame.origin.x), @"y" : @(frame.origin.y) }) ;
        }] ;

        NSSize oldContentSize = manager.frame.size ;
        NSSize newContentSize = NSMakeSize(2 * hPadding + bottomRight.x - topLeft.x, 2 * vPadding + bottomRight.y - topLeft.y) ;

        if (manager.window && [manager isEqualTo:manager.window.contentView]) {
            NSRect oldFrame = manager.window.frame ;
            NSSize newSize  = NSMakeSize(
                newContentSize.width  + (oldFrame.size.width - oldContentSize.width),
                newContentSize.height + (oldFrame.size.height - oldContentSize.height)
            ) ;
            NSRect newFrame = NSMakeRect
                (oldFrame.origin.x,
                oldFrame.origin.y + oldFrame.size.height - newSize.height,
                newSize.width,
                newSize.height
            ) ;
            [manager.window setFrame:newFrame display:YES animate:NO] ;
        } else {
            [manager setFrameSize:newContentSize] ;
        }
    }
    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

static int manager_elements(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    LS_NSConversionOptions options = (lua_gettop(L) == 1) ? LS_TNONE : (lua_toboolean(L, 2) ? LS_NSDescribeUnknownTypes : LS_TNONE) ;
    [skin pushNSObject:manager.subviews withOptions:options] ;
    return 1 ;
}

static int manager_passthroughCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        manager.passthroughCallbackRef = [skin luaUnref:refTable ref:manager.passthroughCallbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            manager.passthroughCallbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (manager.passthroughCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:manager.passthroughCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int manager__nextResponder(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    if (manager.nextResponder) {
        [skin pushNSObject:manager.nextResponder] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

static int manager_toolTip(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:manager.toolTip] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            manager.toolTip = nil ;
        } else {
            manager.toolTip = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int manager_element(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    if (lua_type(L, 2) == LUA_TSTRING) {
        NSString *identifier = [skin toNSObjectAtIndex:2] ;
        BOOL found = NO ;
        for (NSView *view in manager.subviewDetails) {
            NSMutableDictionary *details = [manager.subviewDetails objectForKey:view] ;
            if ([details[@"id"] isEqualToString:identifier]) {
                [skin pushNSObject:view] ;
                found = YES ;
                break ;
            }
        }
        if (!found) lua_pushnil(L) ;
    } else {
        NSInteger idx = lua_tointeger(L, 2) - 1 ;
        if ((idx < 0) || (idx >= (NSInteger)manager.subviews.count)) {
            lua_pushnil(L) ;
        } else {
            [skin pushNSObject:manager.subviews[(NSUInteger)idx]] ;
        }
    }
    return 1 ;
}

static int manager_elementFrameDetails(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSView *item = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
    if (!item || ![item isKindOfClass:[NSView class]]) {
        return luaL_argerror(L, 2, "expected userdata representing a gui element (NSView subclass)") ;
    }
    if (![manager.subviews containsObject:item]) {
        return luaL_argerror(L, 2, "element not managed by this content manager") ;
    }

    if (lua_gettop(L) == 2) {
        [skin pushNSObject:[manager.subviewDetails objectForKey:item]] ;
        [skin pushNSRect:item.frame] ;
        lua_setfield(L, -2, "_effective") ;
    } else {
        adjustElementDetailsTable(L, manager, item, [skin toNSObjectAtIndex:3]) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKManager(lua_State *L, id obj) {
    HSASMGUITKManager *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKManager *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKManagerFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKManager *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKManager, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKManager *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKManager"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKManager *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKManager"] ;
        HSASMGUITKManager *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKManager"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKManager *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKManager, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.passthroughCallbackRef = [skin luaUnref:refTable ref:obj.passthroughCallbackRef] ;
            [obj.subviews enumerateObjectsUsingBlock:^(NSView *subview, __unused NSUInteger idx, __unused BOOL *stop) {
                [skin luaRelease:refTable forNSObject:subview] ;
            }] ;
            [obj.subviewDetails removeAllObjects] ;
            obj.subviewDetails = nil ;
        }
        obj = nil ;
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
    {"insert",              manager_insertElement},
    {"remove",              manager_removeElement},

    {"elements",            manager_elements},
    {"element",             manager_element},

    {"passthroughCallback", manager_passthroughCallback},
    {"sizeToFit",           manager_sizeToFit},
    {"autoPosition",        manager_autoPosition},
    {"tooltip",             manager_toolTip},

    // recognized by elements as needing (manager, element, ...) in args when passing through
    {"elementFrameDetails", manager_elementFrameDetails},
    {"elementMoveAbove",    manager_moveElementAbove},
    {"elementMoveBelow",    manager_moveElementBelow},
    {"elementMoveLeftOf",   manager_moveElementLeftOf},
    {"elementMoveRightOf",  manager_moveElementRightOf},
    {"elementFittingSize",  manager_elementFittingSize},
    {"elementAutoPosition", manager_elementAutoPosition},

    {"_debugFrames",        manager__debugFrames},
    {"_nextResponder",      manager__nextResponder},

    {"__tostring",          userdata_tostring},
    {"__eq",                userdata_eq},
    {"__gc",                userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", manager_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_manager_internal(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKManager         forClass:"HSASMGUITKManager"];
    [skin registerLuaObjectHelper:toHSASMGUITKManagerFromLua forClass:"HSASMGUITKManager"
                                                  withUserdataMapping:USERDATA_TAG];

    return 1;
}
