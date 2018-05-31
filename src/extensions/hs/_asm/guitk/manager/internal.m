
// for our purposes this is 1/1000 of a screen point; small enough that it can't be seen so effectively 0
#define FLOAT_EQUIVALENT_TO_ZERO 0.001

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

@interface HSASMGUITKManager : NSView <NSDraggingDestination>
@property int            selfRefCount ;
@property BOOL           trackMouseEvents ;
@property BOOL           trackMouseMove ;
@property int            passthroughCallback ;
@property int            mouseCallback ;
@property int            frameChangeCallback ;
@property int            draggingCallbackRef ;
@property NSMapTable     *subviewDetails ;
@property NSColor        *frameDebugColor ;
@property NSTrackingArea *trackingArea ;
@end

@implementation HSASMGUITKManager

- (instancetype)initWithFrame:(NSRect)frameRect {

    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _selfRefCount        = 0 ;
        _trackMouseEvents    = NO ;
        _trackMouseMove      = NO ;
        _passthroughCallback = LUA_NOREF ;
        _mouseCallback       = LUA_NOREF ;
        _frameChangeCallback = LUA_NOREF ;
        _draggingCallbackRef = LUA_NOREF ;
        _subviewDetails      = [NSMapTable strongToStrongObjectsMapTable] ;
        _frameDebugColor     = nil ;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(frameChangedNotification:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:nil] ;

        _trackingArea = [[NSTrackingArea alloc] initWithRect:frameRect
                                                     options:NSTrackingMouseMoved |
                                                             NSTrackingMouseEnteredAndExited |
                                                             NSTrackingActiveAlways |
                                                             NSTrackingInVisibleRect
                                                       owner:self
                                                    userInfo:nil] ;
        [self addTrackingArea:_trackingArea] ;
    }
    return self ;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewFrameDidChangeNotification
                                                  object:nil] ;
    [self removeTrackingArea:_trackingArea] ;
    _trackingArea = nil ;
}

- (void)passCallbackUpWith:(NSArray *)arguments {
    // allow next responder a chance since we don't have a callback set
    id nextInChain = [self nextResponder] ;
    if (nextInChain) {
        SEL passthroughCallback = NSSelectorFromString(@"performPassthroughCallback:") ;
        if ([nextInChain respondsToSelector:passthroughCallback]) {
            [nextInChain performSelectorOnMainThread:passthroughCallback
                                          withObject:arguments
                                       waitUntilDone:YES] ;
        }
    }
}

- (void)doFrameChangeCallbackWith:(NSView *)targetView {
    if (_frameChangeCallback != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        [skin pushLuaRef:refTable ref:_frameChangeCallback] ;
        [skin pushNSObject:self] ;
        [skin pushNSObject:targetView] ;
        if (![skin protectedCallAndTraceback:2 nresults:0]) {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            lua_pop(skin.L, 1) ;
            [skin logError:[NSString stringWithFormat:@"%s:frameChangeCallback error:%@", USERDATA_TAG, errorMessage]] ;
        }
//     } else {
//         [self passCallbackUpWith:@[ self, targetView ]] ;
    }
}

- (void)frameChangedNotification:(NSNotification *)notification {
    NSView *targetView = notification.object ;
    if (targetView) {
        if ([targetView isEqualTo:self]) {
            [self doFrameChangeCallbackWith:targetView] ;
            for (NSView *view in self.subviews) [self updateFrameFor:view] ;
        } else {
            if ([self.subviews containsObject:targetView]) {
                [self doFrameChangeCallbackWith:targetView] ;
                [self updateFrameFor:targetView] ;
            }
        }
    }
}

- (void)resetFrameSizeDetailsFor:(NSView *)view {
    NSMutableDictionary *details = [_subviewDetails objectForKey:view] ;
    if (details) {
        NSSize updatedSize = view.frame.size ;
        details[@"h"] = @(updatedSize.height) ;
        details[@"w"] = @(updatedSize.width) ;
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

    if (details[@"rX"]) {
        NSNumber *value = details[@"rX"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.width * value.doubleValue) ;
        }
        frame.origin.x = value.doubleValue - frame.size.width ;
    }
    if (details[@"bY"]) {
        NSNumber *value = details[@"bY"] ;
        if ([value isKindOfClass:[NSString class]]) {
            value = convertPercentageStringToNumber((NSString *)value) ;
            value = @(self.frame.size.height * value.doubleValue) ;
        }
        frame.origin.y = value.doubleValue - frame.size.height ;
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
// unless we add a "shrinkToFit" (as opposed to sizeToFit) we only care about the subview sizes as currently expressed
//             NSSize viewFittingSize   = view.fittingSize ;
//             if (!CGSizeEqualToSize(viewFittingSize, NSZeroSize)) {
//                 frameBottomRight = NSMakePoint(frame.origin.x + viewFittingSize.width, frame.origin.y + viewFittingSize.height) ;
//             }
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
            // comparing floats is problematic, but for our purposes, if the difference is less than this, it has no visible width
                if (btRight.x - topLeft.x < FLOAT_EQUIVALENT_TO_ZERO) {
                    topLeft.x -= 5 ;
                    btRight.x += 5 ;
                }
            // comparing floats is problematic, but for our purposes, if the difference is less than this, it has no visible height
                if (btRight.y - topLeft.y < FLOAT_EQUIVALENT_TO_ZERO) {
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
- (void)performPassthroughCallback:(NSArray *)arguments {
    if (_passthroughCallback != LUA_NOREF) {
        LuaSkin *skin    = [LuaSkin shared] ;
        int     argCount = 1 ;

        [skin pushLuaRef:refTable ref:_passthroughCallback] ;
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
        [self passCallbackUpWith:@[ self, arguments ]] ;
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

- (void) invokeMouseTrackingCallback:(NSString *)message forEvent:(NSEvent *)theEvent {
    if (_trackMouseEvents) {
        NSPoint point     = [self convertPoint:theEvent.locationInWindow fromView:nil];
        NSValue *location = [NSValue valueWithPoint:point] ;

        if (_mouseCallback != LUA_NOREF) {
            LuaSkin *skin = [LuaSkin shared] ;
            [skin pushLuaRef:refTable ref:_mouseCallback] ;
            [skin pushNSObject:self] ;
            [skin pushNSObject:message] ;
            [skin pushNSObject:location] ;
            if (![skin protectedCallAndTraceback:3 nresults:0]) {
                NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                lua_pop(skin.L, 1) ;
                [skin logError:[NSString stringWithFormat:@"%s:mouseCallback error:%@", USERDATA_TAG, errorMessage]] ;
            }
        } else {
            [self passCallbackUpWith:@[ self, message, location ]] ;
        }
    }
}

- (void) mouseMoved:(NSEvent *)theEvent {
    if (_trackMouseMove) [self invokeMouseTrackingCallback:@"move" forEvent:theEvent] ;
}

- (void) mouseEntered:(NSEvent *)theEvent {
    [self invokeMouseTrackingCallback:@"enter" forEvent:theEvent] ;
}

- (void) mouseExited:(NSEvent *)theEvent {
    [self invokeMouseTrackingCallback:@"exit" forEvent:theEvent] ;
}

#pragma mark - NSDraggingDestination protocol methods

- (BOOL)draggingCallback:(NSString *)message with:(id<NSDraggingInfo>)sender {
    BOOL isAllGood = NO ;
    if (_draggingCallbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        lua_State *L = skin.L ;
        int argCount = 2 ;
        [skin pushLuaRef:refTable ref:_draggingCallbackRef] ;
        [skin pushNSObject:self] ;
        [skin pushNSObject:message] ;
        if (sender) {
            lua_newtable(L) ;
            NSPasteboard *pasteboard = [sender draggingPasteboard] ;
            if (pasteboard) {
                [skin pushNSObject:pasteboard.name] ; lua_setfield(L, -2, "pasteboard") ;
            }
            lua_pushinteger(L, [sender draggingSequenceNumber]) ; lua_setfield(L, -2, "sequence") ;
            [skin pushNSPoint:[sender draggingLocation]] ; lua_setfield(L, -2, "mouse") ;
            NSDragOperation operation = [sender draggingSourceOperationMask] ;
            lua_newtable(L) ;
            if (operation == NSDragOperationNone) {
                lua_pushstring(L, "none") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
            } else {
                if ((operation & NSDragOperationCopy) == NSDragOperationCopy) {
                    lua_pushstring(L, "copy") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
                if ((operation & NSDragOperationLink) == NSDragOperationLink) {
                    lua_pushstring(L, "link") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
                if ((operation & NSDragOperationGeneric) == NSDragOperationGeneric) {
                    lua_pushstring(L, "generic") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
                if ((operation & NSDragOperationPrivate) == NSDragOperationPrivate) {
                    lua_pushstring(L, "private") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
                if ((operation & NSDragOperationMove) == NSDragOperationMove) {
                    lua_pushstring(L, "move") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
                if ((operation & NSDragOperationDelete) == NSDragOperationDelete) {
                    lua_pushstring(L, "delete") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1)  ;
                }
            }
            lua_setfield(L, -2, "operation") ;
            argCount += 1 ;
        }
        if ([skin protectedCallAndTraceback:argCount nresults:1]) {
            isAllGood = lua_isnoneornil(L, -1) ? YES : (BOOL)lua_toboolean(skin.L, -1) ;
        } else {
            [skin logError:[NSString stringWithFormat:@"%s:draggingCallback error: %@", USERDATA_TAG, [skin toNSObjectAtIndex:-1]]] ;
        }
        lua_pop(L, 1) ;
    }
    return isAllGood ;
}

- (BOOL)wantsPeriodicDraggingUpdates {
    return NO ;
}

- (BOOL)prepareForDragOperation:(__unused id<NSDraggingInfo>)sender {
    return YES ;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    return [self draggingCallback:@"enter" with:sender] ? NSDragOperationGeneric : NSDragOperationNone ;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    [self draggingCallback:@"exit" with:sender] ;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    return [self draggingCallback:@"receive" with:sender] ;
}

// - (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender ;
// - (void)concludeDragOperation:(id<NSDraggingInfo>)sender ;
// - (void)draggingEnded:(id<NSDraggingInfo>)sender ;
// - (void)updateDraggingItemsForDrag:(id<NSDraggingInfo>)sender

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

        NSArray *xFields = @[ @"rX", @"cX", @"x" ] ;
        for (NSString *key in xFields) {
            if (lua_getfield(L, idx, key.UTF8String) != LUA_TNIL) {
                id newVal = [skin toNSObjectAtIndex:-1] ;
                if (lua_type(L, -1) == LUA_TSTRING) {
                    if (!convertPercentageStringToNumber(newVal)) {
                        [skin logWarn:[NSString stringWithFormat:@"%s:percentage string %@ invalid for %@ key in element details", USERDATA_TAG, newVal, key]] ;
                        newVal = nil ;
                    }
                } else if (lua_type(L, -1) != LUA_TNUMBER) {
                    [skin logWarn:[NSString stringWithFormat:@"%s:expected number or string for %@ key in element details, found %s", USERDATA_TAG, key, lua_typename(L, lua_type(L, -1))]] ;
                    newVal = nil ;
                }
                if (newVal) {
                    for (NSString *clearKey in xFields) details[clearKey] = nil ;
                    details[key] = newVal ;
                }
            }
            lua_pop(L, 1) ;
        }

        NSArray *yFields = @[ @"bY", @"cY", @"y" ] ;
        for (NSString *key in yFields) {
            if (lua_getfield(L, idx, key.UTF8String) != LUA_TNIL) {
                id newVal = [skin toNSObjectAtIndex:-1] ;
                if (lua_type(L, -1) == LUA_TSTRING) {
                    if (!convertPercentageStringToNumber(newVal)) {
                        [skin logWarn:[NSString stringWithFormat:@"%s:percentage string %@ invalid for %@ key in element details", USERDATA_TAG, newVal, key]] ;
                        newVal = nil ;
                    }
                } else if (lua_type(L, -1) != LUA_TNUMBER) {
                    [skin logWarn:[NSString stringWithFormat:@"%s:expected number or string for %@ key in element details, found %s", USERDATA_TAG, key, lua_typename(L, lua_type(L, -1))]] ;
                    newVal = nil ;
                }
                if (newVal) {
                    for (NSString *clearKey in yFields) details[clearKey] = nil ;
                    details[key] = newVal ;
                }
            }
            lua_pop(L, 1) ;
        }

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

        if (lua_getfield(L, idx, "honorCanvasMove") == LUA_TBOOLEAN) {
            details[@"honorCanvasMove"] = lua_toboolean(L, -1) ? @(YES) : nil ;
        } else if (lua_type(L, -1) != LUA_TNIL) {
            [skin logWarn:[NSString stringWithFormat:@"%s expected boolean or nil for honorCanvasMove key in element details, found %s", USERDATA_TAG, lua_typename(L, lua_type(L, -1))]] ;
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

/// hs._asm.guitk.manager.new([frame]) -> managerObject | nil
/// Constructor
/// Create a new manager object for use with a `hs._asm.guitk` window or another manager.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the initial position and size of the manager.
///
/// Returns:
///  * the manager object or nil if there was an error creating the manager.
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the manager is assigned to a `hs._asm.guitk` window or another manager. It may be useful, however, when assigning elements to an unattached manager so that proper positioning can be worked out before final assignment of the new manager to it's parent object.
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

/// hs._asm.guitk.manager:_debugFrames([color]) -> managerObject | table | nil
/// Method
/// Enable or disable visual rectangles around element frames in the content manager which can aid in identifying frame or positioning bugs.
///
/// Parameters:
///  * `color` - a color table (as defined in `hs.drawing.color`, boolean, or nil, specifying whether debugging frames should be displayed and if so in what color.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * Specifying `true` will enable the debugging frames with the current system color that represents the keyboard focus ring around controls.
///  * Specifying `false` or `nil` will disable the debugging frames (default).
///  * Specifying a color as defined by `hs.drawing.color` will display the debugging frames in the specified color.
///
///  * Element frames which contain a height or width which is less than .5 points (effectively invisible) will draw an X at the center of the elements position instead of a rectangle.
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
            if (lua_toboolean(L, 2) && lua_toboolean(L, 2)) {
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

/// hs._asm.guitk.manager:autoPosition() -> managerObject
/// Method
/// Recalculate the position of all elements in the manager and update them if necessary.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method recalculates the position of elements whose position in `frameDetails` is specified by the element center or whose position or size are specified by percentages. See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for more information.
///  * This method is invoked automatically anytime the managers parent (usually a `hs._asm.guitk` window) is resized and you shouldn't need to invoke it manually very often. If you find that you are needing to invoke it manually on a regular basis, try to determine what the specific circumstances are and submit an issue so that it can be evaluated to determine if the situation can be detected and trigger an update automatically.
///
/// * See also [hs._asm.guitk.manager:elementAutoPosition](#elementAutoPosition).
static int manager_autoPosition(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    [manager frameChangedNotification:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:manager]] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.manager:elementAutoPosition(element) -> managerObject
/// Method
/// Recalculate the position of the specified element in the manager and update it if necessary.
///
/// Parameters:
///  * `element` - the element userdata to recalculate the size and position for.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method recalculates the position of the element if it is defined in `framedDetails` as a percentage or by the elements center and it's size if the element size is specified as a percentage or inherits its size from the element's fitting size (see [hs._asm.guitk.manager:elementFittingSize](#elementFittingSize).
///
///  * See also [hs._asm.guitk.manager:autoPosition](#autoPosition).
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:autoPosition()`
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
    [manager frameChangedNotification:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:item]] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.manager:insert(element, [frameDetails], [pos]) -> managerObject
/// Method
/// Inserts a new element for the manager to manage.
///
/// Parameters:
///  * `element`      - the element userdata to insert into the manager
///  * `frameDetails` - an optional table containing frame details for the element as described for the [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) method.
///  * `pos`          - the index position in the list of elements specifying where to insert the element.  Defaults to `#hs._asm.guitk.manager:elements() + 1`, which will insert the element at the end.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * If the frameDetails table is not provided, the elements position will default to the lower left corner of the last element added to the manager, and its size will default to the elements fitting size as returned by [hs._asm.guitk.manager:elementFittingSize](#elementFittingSize).
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
    if ((idx < 0) || (idx > (NSInteger)manager.subviews.count)) return luaL_argerror(L, lua_gettop(L), "index out of bounds") ;

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
    if ((item.fittingSize.height < FLOAT_EQUIVALENT_TO_ZERO) && !details[@"h"]) {
        [skin logWarn:[NSString stringWithFormat:@"%s:insert - height not specified and default height for element is 0", USERDATA_TAG]] ;
    }
    if ((item.fittingSize.width < FLOAT_EQUIVALENT_TO_ZERO) && !details[@"w"]) {
        [skin logWarn:[NSString stringWithFormat:@"%s:insert - width not specified and default width for element is 0", USERDATA_TAG]] ;
    }

    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.manager:remove([pos]) -> managerObject
/// Method
/// Remove an element from the manager as specified by its index position.
///
/// Parameters:
///  * `pos`     - the index position in the list of elements specifying the element to remove.  Defaults to `#hs._asm.guitk.manager:elements()` (the last element)
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * See also [hs._asm.guitk.manager:elementRemoveFromManager](#elementRemoveFromManager)
static int manager_removeElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    NSInteger idx = ((lua_type(L, 2) == LUA_TNUMBER) ? lua_tointeger(L, 2) : (NSInteger)manager.subviews.count) - 1 ;
    if ((idx < 0) || (idx >= (NSInteger)manager.subviews.count)) return luaL_argerror(L, lua_gettop(L), "index out of bounds") ;

    NSMutableArray *subviewHolder = [manager.subviews mutableCopy] ;
    [subviewHolder removeObjectAtIndex:(NSUInteger)idx] ;
    manager.subviews = subviewHolder ;

    manager.needsDisplay = YES ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.manager:elementMoveAbove(element1, element2, [offset], [relationship]) -> managerObject
/// Method
/// Moves element1 above element2 in the manager.
///
/// Parameters:
///  * `element1`     - the element userdata to adjust the `x` and `y` coordinates of
///  * `element2`     - the element userdata to anchor element1 to
///  * `offset`       - a number, default 0.0, specifying the space between element1 and element2 in their new relationship
///  * `relationship` - a string, default "flushLeft", specifying the horizontal relationship between `element1` and `element2`.  May be one of the following:
///    * "flushLeft"  - element1 will be positioned above element2 with its left side at the same `x` position of the left side of element2.
///    * "centered"   - element1 will be centered horizontally above element2.
///    * "flushRight" - element1 will be positioned above element2 with its right side at the same `x` position of the right side of element2.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method will set the `x` and `y` fields of `frameDetails` for the element.  See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for the effect of this on other frame details.
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:moveAbove(element2, [offset], [relationship])`
///
///  * this method moves element1 in relation to element2's current position -- moving element2 at a later point will not cause element1 to follow
///  * this method will not adjust the postion of any other element which may already be at the new position for element1
///  * an extension to `hs._asm.guitk.manager` which may support these limitations is under consideration but is currently not in the works.
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

/// hs._asm.guitk.manager:elementMoveBelow(element1, element2, [offset], [relationship]) -> managerObject
/// Method
/// Moves element1 below element2 in the manager.
///
/// Parameters:
///  * `element1`     - the element userdata to adjust the `x` and `y` coordinates of
///  * `element2`     - the element userdata to anchor element1 to
///  * `offset`       - a number, default 0.0, specifying the space between element1 and element2 in their new relationship
///  * `relationship` - a string, default "flushLeft", specifying the horizontal relationship between `element1` and `element2`.  May be one of the following:
///    * "flushLeft"  - element1 will be positioned below element2 with its left side at the same `x` position of the left side of element2.
///    * "centered"   - element1 will be centered horizontally below element2.
///    * "flushRight" - element1 will be positioned below element2 with its right side at the same `x` position of the right side of element2.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method will set the `x` and `y` fields of `frameDetails` for the element.  See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for the effect of this on other frame details.
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:moveBelow(element2, [offset], [relationship])`
///
///  * this method moves element1 in relation to element2's current position -- moving element2 at a later point will not cause element1 to follow
///  * this method will not adjust the postion of any other element which may already be at the new position for element1
///  * an extension to `hs._asm.guitk.manager` which may support these limitations is under consideration but is currently not in the works.
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

/// hs._asm.guitk.manager:elementMoveLeftOf(element1, element2, [offset], [relationship]) -> managerObject
/// Method
/// Moves element1 to the left of element2 in the manager.
///
/// Parameters:
///  * `element1`     - the element userdata to adjust the `x` and `y` coordinates of
///  * `element2`     - the element userdata to anchor element1 to
///  * `offset`       - a number, default 0.0, specifying the space between element1 and element2 in their new relationship
///  * `relationship` - a string, default "flushTop", specifying the vertical relationship between `element1` and `element2`.  May be one of the following:
///    * "flushBottom" - element1 will be positioned to the left of element2 with its top at the same `y` position of the top of element2.
///    * "centered"    - element1 will be centered vertically to the left of element2.
///    * "flushTop"    - element1 will be positioned to the left of element2 with its bottom at the same `y` position of the bottom of element2.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method will set the `x` and `y` fields of `frameDetails` for the element.  See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for the effect of this on other frame details.
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:moveLeftOf(element2, [offset], [relationship])`
///
///  * this method moves element1 in relation to element2's current position -- moving element2 at a later point will not cause element1 to follow
///  * this method will not adjust the postion of any other element which may already be at the new position for element1
///  * an extension to `hs._asm.guitk.manager` which may support these limitations is under consideration but is currently not in the works.
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

/// hs._asm.guitk.manager:elementMoveRightOf(element1, element2, [offset], [relationship]) -> managerObject
/// Method
/// Moves element1 to the right of element2 in the manager.
///
/// Parameters:
///  * `element1`     - the element userdata to adjust the `x` and `y` coordinates of
///  * `element2`     - the element userdata to anchor element1 to
///  * `offset`       - a number, default 0.0, specifying the space between element1 and element2 in their new relationship
///  * `relationship` - a string, default "flushTop", specifying the vertical relationship between `element1` and `element2`.  May be one of the following:
///    * "flushBottom" - element1 will be positioned to the right of element2 with its top at the same `y` position of the top of element2.
///    * "centered"    - element1 will be centered vertically to the right of element2.
///    * "flushTop"    - element1 will be positioned to the right of element2 with its bottom at the same `y` position of the bottom of element2.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * This method will set the `x` and `y` fields of `frameDetails` for the element.  See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for the effect of this on other frame details.
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:moveRightOf(element2, [offset], [relationship])`
///
///  * this method moves element1 in relation to element2's current position -- moving element2 at a later point will not cause element1 to follow
///  * this method will not adjust the postion of any other element which may already be at the new position for element1
///  * an extension to `hs._asm.guitk.manager` which may support these limitations is under consideration but is currently not in the works.
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

/// hs._asm.guitk.manager:elementFittingSize(element) -> size-table
/// Method
/// Returns a table with `h` and `w` keys specifying the element's fitting size as defined by macOS and the element's current properties.
///
/// Parameters:
///  * `element` - the element userdata to get the fitting size for.
///
/// Returns:
///  * a table with `h` and `w` keys specifying the elements fitting size
///
/// Notes:
///  * The dimensions provided can be used to determine a minimum size for the element to display fully based on its current properties and may change as these change.
///  * Not all elements provide one or both of these fields; in such a case, the value for the missing or unspecified field will be 0.
///  * If you do not specify an elements height or width with [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails), the value returned by this method will be used instead; in cases where a specific dimension is not defined by this method, you should make sure to specify it or the element may not be visible.
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

/// hs._asm.guitk.manager:sizeToFit([hPad], [vPad]) -> managerObject
/// Method
/// Adjusts the size of the manager so that it is the minimum size necessary to contain all of its elements.
///
/// Parameters:
///  * `hPad` - an optional number specifying the horizontal padding to include between the elements and the left and right of the manager's new borders. Defaults to 0.0.
///  * `vPad` - an optional number specifying the vertical padding to include between the elements and the top and bottom of the manager's new borders.  Defaults to the value of `hPad`.
///
/// Returns:
///  * the manager object
///
/// Notes:
///  * If the manager is the member of another manager, this manager's size (but not top-left corner) is adjusted within its parent.
///  * If the manager is assigned to a `hs._asm.guitk` window, the window's size (but not top-left corner) will be adjusted to the calculated size.
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

/// hs._asm.guitk.manager:elements() -> table
/// Method
/// Returns an array containing the elements in index order currently managed by this manager.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table containing the elements in index order currently managed by this manager
static int manager_elements(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;
    LS_NSConversionOptions options = (lua_gettop(L) == 1) ? LS_TNONE : (lua_toboolean(L, 2) ? LS_NSDescribeUnknownTypes : LS_TNONE) ;
    [skin pushNSObject:manager.subviews withOptions:options] ;
    return 1 ;
}

/// hs._asm.guitk.manager:passthroughCallback([fn | nil]) -> managerObject | fn | nil
/// Method
/// Get or set the pass through callback for the manager.
///
/// Parameters:
///  * `fn` - a function, or an explicit nil to remove, specifying the callback to invoke for elements which do not have their own callbacks assigned.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * The pass through callback should expect one or two arguments and return none.
///
///  * The pass through callback is designed so that elements which trigger a callback based on user interaction which do not have a specifically assigned callback can still report user interaction through a common fallback.
///  * The arguments received by the pass through callback will be organized as follows:
///    * the manager userdata object
///    * a table containing the arguments provided by the elements callback itself, usually the element userdata followed by any additional arguments as defined for the element's callback function.
///
///  * Note that elements which have a callback that returns a response cannot use this common pass through callback method; in such cases a specific callback must be assigned to the element directly as described in the element's documentation.
static int manager_passthroughCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        manager.passthroughCallback = [skin luaUnref:refTable ref:manager.passthroughCallback] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            manager.passthroughCallback = [skin luaRef:refTable] ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        if (manager.passthroughCallback != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:manager.passthroughCallback] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.manager:frameChangeCallback([fn | nil]) -> managerObject | fn | nil
/// Method
/// Get or set the frame change callback for the manager.
///
/// Parameters:
///  * `fn` - a function, or an explicit nil to remove, specifying the callback to invoke when the frame changes for the manager or one of its subviews. A frame change can be a change in location or a change in size or both.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * The frame change callback should expect 2 arguments and return none.
///  * The arguments are as follows:
///    * the manager object userdata
///    * the userdata object of the element whose frame has changed -- this may be equal to the manager object itself, if it is the managers frame that changed.
///
///  * Frame change callbacks are not passed to the parent passthrough callback; they must be handled by the manager in which the change occurs.
static int manager_frameChangeCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        manager.frameChangeCallback = [skin luaUnref:refTable ref:manager.frameChangeCallback] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            manager.frameChangeCallback = [skin luaRef:refTable] ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        if (manager.frameChangeCallback != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:manager.frameChangeCallback] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.manager:draggingCallback(fn | nil) -> managerObject | fn | nil
/// Method
/// Get or set the callback for accepting dragging and dropping items onto the manager.
///
/// Parameters:
///  * `fn` - a function, or an explicit nil to remove, specifying the callback to invoke when an item is dragged onto the manager.  An explicit nil, the default, disables drag-and-drop for this element.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * The callback function should expect 3 arguments and optionally return 1: the manager object itself, a message specifying the type of dragging event, and a table containing details about the item(s) being dragged.  The key-value pairs of the details table will be the following:
///    * `pasteboard` - the name of the pasteboard that contains the items being dragged
///    * `sequence`   - an integer that uniquely identifies the dragging session.
///    * `mouse`      - a point table containing the location of the mouse pointer within the manager corresponding to when the callback occurred.
///    * `operation`  - a table containing string descriptions of the type of dragging the source application supports. Potentially useful for determining if your callback function should accept the dragged item or not.
///
/// * The possible messages the callback function may receive are as follows:
///    * "enter"   - the user has dragged an item into the manager.  When your callback receives this message, you can optionally return false to indicate that you do not wish to accept the item being dragged.
///    * "exit"    - the user has moved the item out of the manager; if the previous "enter" callback returned false, this message will also occur when the user finally releases the items being dragged.
///    * "receive" - indicates that the user has released the dragged object while it is still within the element frame.  When your callback receives this message, you can optionally return false to indicate to the sending application that you do not want to accept the dragged item -- this may affect the animations provided by the sending application.
///
///  * You can use the sequence number in the details table to match up an "enter" with an "exit" or "receive" message.
///
///  * You should capture the details you require from the drag-and-drop operation during the callback for "receive" by using the pasteboard field of the details table and the `hs.pasteboard` module.  Because of the nature of "promised items", it is not guaranteed that the items will still be on the pasteboard after your callback completes handling this message.
///
///  * A manager object can only accept drag-and-drop items when the `hs._asm.guitk` window the manager ultimately belongs to is at a level of `hs._asm.guitk.levels.dragging` or lower. Note that the manager receiving the drag-and-drop item does not have to be the content manager of the `hs._asm.guitk` window -- it can be an element of another manager acting as the window content manager.
///  * a manager object can only accept drag-and-drop items if it's `hs._asm.guitk` window object accepts mouse events, i.e. `hs._asm.guitk:ignoresMouseEvents` is set to false.
static int manager_draggingCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        // We're either removing callback(s), or setting new one(s). Either way, remove existing.
        manager.draggingCallbackRef = [skin luaUnref:refTable ref:manager.draggingCallbackRef];
        [manager unregisterDraggedTypes] ;
        if ([skin luaTypeAtIndex:2] != LUA_TNIL) {
            lua_pushvalue(L, 2);
            manager.draggingCallbackRef = [skin luaRef:refTable] ;
            [manager registerForDraggedTypes:@[ (__bridge NSString *)kUTTypeItem ]] ;
        }
        lua_pushvalue(L, 1);
    } else {
        if (manager.draggingCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:manager.draggingCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }

    return 1;
}

/// hs._asm.guitk.manager:mouseCallback([fn | true | nil]) -> managerObject | fn | boolean
/// Method
/// Get or set the mouse tracking callback for the manager.
///
/// Parameters:
///  * `fn` - a function, or an explicit nil to remove, specifying the callback to invoke when the mouse enters, exits, or moves within the manager. Specify an explicit true if you wish for mouse tracking information to be passed to the parent object passthrough callback, if defined, instead.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * The mouse tracking callback should expect 3 arguments and return none.
///  * The arguments are as follows:
///    * the manager object userdata
///    * a string specifying the type of the callback. Possible values are "enter", "exit", or "move"
///    * a point-table containing the coordinates within the manager of the mouse event. A point table is a table with `x` and `y` keys specifying the mouse coordinates.
///
///  * By default, only mouse enter and mouse exit events will invoke the callback to reduce overhead; if you need to track mouse movement within the manager as well, see [hs._asm.guitk.manager:trackMouseMove](#trackMouseMove).
static int manager_mouseCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        manager.mouseCallback    = [skin luaUnref:refTable ref:manager.mouseCallback] ;
        manager.trackMouseEvents = NO ;
        if (lua_type(L, 2) == LUA_TBOOLEAN) {
            manager.trackMouseEvents = (BOOL)lua_toboolean(L, 2) ;
        } else if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            manager.mouseCallback    = [skin luaRef:refTable] ;
            manager.trackMouseEvents = YES ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        if (manager.mouseCallback != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:manager.mouseCallback] ;
        } else {
            lua_pushboolean(L, manager.trackMouseEvents) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.manager:trackMouseMove([state]) -> managerObject | boolean
/// Method
/// Get or set whether mouse tracking callbacks should include movement within the managers visible area.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether mouse movement within the manager also triggers a callback.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * [hs._asm.guitk.manager:mouseCallback](#mouseCallback) must bet set to a callback function or true for this attribute to have any effect.
static int manager_trackMouseMove(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKManager *manager = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, manager.trackMouseMove) ;
    } else {
        manager.trackMouseMove = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}


/// hs._asm.guitk.manager:_nextResponder() -> userdata
/// Method
/// Returns the parent object of the manager as a userdata object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the userdata object representing the managers parent, usually a `hs._asm.guitk` window, or nil if the manager has no parent or its parent is not controllable through Hammerspoon.
///
/// Notes:
///  * This method can be used to access the parent object of the manager. Usually this will be a `hs._asm.guitk` window object, but since a manager may also be an element of another manager, this method may return a `hs._asm.guitk.manager` object in these cases.
///  * The metamethods for this module are designed so that you usually shouldn't need to access this method directly very often.
///  * The name "nextResponder" comes from the macOS user interface internal organization and refers to the object which is further up the responder chain when determining the target for user activity.
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

/// hs._asm.guitk.manager:tooltip([tooltip]) -> managerObject | string
/// Method
/// Get or set the tooltip for the manager
///
/// Parameters:
///  * `tooltip` - a string, or nil to remove, specifying the tooltip to display when the mouse pointer hovers over the content manager
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * Tooltips are displayed when the window is active and the mouse pointer hovers over the content manager and no other element at the current mouse position has a defined tooltip.
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

/// hs._asm.guitk.manager:element([id]) -> elementUserdata | nil
/// Method
/// Returns the element userdata for the element specified.
///
/// Parameters:
///  * `id` - a string or integer specifying which element to return.  If `id` is an integer, returns the element at the specified index position; if `id` is a string, returns the element with the specified identifier string.
///
/// Returns:
///  * the element userdata, or nil if no element exists in the manager at the specified index position or with the specified identifier.
///
/// Notes:
///  * See [hs._asm.guitk.manager:elementFrameDetails](#elementFrameDetails) for more information on setting an element's identifier string.
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

/// hs._asm.guitk.manager:elementFrameDetails(element, [details]) -> managerObject | table
/// Method
/// Get or set the frame details in the manager for the specified element.
///
/// Parameters:
///  * `element` - the element to get or set the frame details for
///  * `details` - an optional table specifying the details to change or set for this element. The valid key-value pairs for the table are as follows:
///    * `x`  - The horizontal position of the elements left side. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
///    * `rX`  - The horizontal position of the elements right side. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
///    * `cX` - The horizontal position of the elements center point. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
///    * `y`  - The vertical position of the elements top. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
///    * `bY`  - The vertical position of the elements bottom. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
///    * `cY` - The vertical position of the elements center point. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
///    * `h`  - The element's height. If this is set, it will be used instead of the default height as returned by [hs._asm.guitk.manager:elementFittingSize](#elementFittingSize). If the default height is 0, then this *must* be set or the element will be effectively invisible. Set to false to clear a defined height and return the the default behavior.
///    * `w`  - The element's width. If this is set, it will be used instead of the default width as returned by [hs._asm.guitk.manager:elementFittingSize](#elementFittingSize). If the default width is 0, then this *must* be set or the element will be effectively invisible. Set to false to clear a defined width and return the the default behavior.
///    * `id` - A string specifying an identifier which can be used to reference this element with [hs._asm.guitk.manager:element](#element) without requiring knowledge of the element's index position. Specify the value as false to clear the identifier and set it to nil.
///
///    * `honorCanvasMove` - A boolean, default nil (false), indicating whether or not the frame wrapper functions for `hs.canvas` objects should honor location changes when made with `hs.canvas:topLeft` or `hs.canvas:frame`. This is a (hopefully temporary) fix because canvas objects are not aware of the `hs._asm.guitk` frameDetails model for element placement.
///
/// Returns:
///  * If an argument is provided, the manager object; otherwise the current value.
///
/// Notes:
///  * When setting the frame details, only those fields provided will be adjusted; other fields will remain unaffected (except as noted above).
///  * The values for keys `x`, `rX`, `cX`, `y`, `bY`, `cY`, `h`, and `w` may be specified as numbers or as strings representing percentages of the element's parent width (for `x`, `rX`, `cX`, and `w`) or height (for `y`, `bY`, `cY`, and `h`). Percentages should specified in the string as defined for your locale or in the `en_US` locale (as a fallback) which is either a number followed by a % sign or a decimal number.
///
///  * When returning the current frame details table, an additional key-value pair is included: `_effective` will be a table specifying the elements actual frame-table (a table specifying the elements position as key-value pairs specifying the top-left position with `x` and `y`, and the element size with `h` and `w`).  This is provided for reference only: if this key-value pair is included when setting the frame details with this method, it will be ignored.
///
///  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:frameDetails([details])`
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

// TODO: Move to hs.canvas once we decide how it's going to change to work with guitk
//  * Prevents canvas wrappers for size and topLeft from spewing LuaSkin log entries because the _nextResponder
//    isn't a known type... here we make it "known" and it's known Hammerspoon equivalent is nil.
//  * Long term, this will probably be moot because the canvas view is all we really need if guitk is used as
//    it's window rather than HSCanvasWindow, but this requires guitk to be in core first.
static int pushHSCanvasWindow(lua_State *L, __unused id obj) {
    lua_pushnil(L) ;
    return 1;
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
            obj.mouseCallback       = [skin luaUnref:refTable ref:obj.mouseCallback] ;
            obj.passthroughCallback = [skin luaUnref:refTable ref:obj.passthroughCallback] ;
            obj.frameChangeCallback = [skin luaUnref:refTable ref:obj.frameChangeCallback] ;
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
    {"frameChangeCallback", manager_frameChangeCallback},
    {"mouseCallback",       manager_mouseCallback},
    {"draggingCallback",    manager_draggingCallback},
    {"trackMouseMove",      manager_trackMouseMove},
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

int luaopen_hs__asm_guitk_manager_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKManager         forClass:"HSASMGUITKManager"];
    [skin registerLuaObjectHelper:toHSASMGUITKManagerFromLua forClass:"HSASMGUITKManager"
                                                  withUserdataMapping:USERDATA_TAG];

    // stop-gap until guitk goes into core and replaces the "window" portion of the canvas module
    [skin registerPushNSHelper:pushHSCanvasWindow forClass:"HSCanvasWindow"];

    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"tooltip",
        @"elements",
        @"passthroughCallback",
        @"mouseCallback",
        @"draggingCallback",
        @"frameChangeCallback",
        @"trackMouseMove",
    ]] ;
    lua_setfield(L, -2, "_propertyList") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
