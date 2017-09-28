// TODO:
//    test proper __gc/close behavior with deleteOnClose = YES and delete with fade time
// *  passthroughCallback for guitk object

@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk" ;
static int refTable = LUA_NOREF;

static NSArray *guitkNotifications ;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#pragma mark - Support Functions and Classes

static int userdata_gc(lua_State* L) ;

static inline NSRect RectWithFlippedYCoordinate(NSRect theRect) {
    return NSMakeRect(theRect.origin.x,
                      [[NSScreen screens][0] frame].size.height - theRect.origin.y - theRect.size.height,
                      theRect.size.width,
                      theRect.size.height) ;
}

@interface HSASMGuiWindow : NSPanel <NSWindowDelegate>
@property int          selfRef ;
@property int          contentManagerRef ;
@property int          notificationCallback ;
@property int          passthroughCallbackRef ;
@property BOOL         allowKeyboardEntry ;
@property BOOL         deleteOnClose ;
@property BOOL         closeOnEscape ;
@property NSNumber     *animationTime ;
@property NSMutableSet *notifyFor ;
@property NSString     *subroleOverride ;
@end

@implementation HSASMGuiWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)windowStyle
                                                          backing:(NSBackingStoreType)bufferingType
                                                            defer:(BOOL)deferCreation {

    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation] ;

    if (self) {
        contentRect = RectWithFlippedYCoordinate(contentRect) ;
        [self setFrameOrigin:contentRect.origin] ;

        self.autorecalculatesKeyViewLoop = YES ;
        self.releasedWhenClosed = NO ;
        self.ignoresMouseEvents = NO ;
        self.restorable         = NO ;
        self.hidesOnDeactivate  = NO ;
        self.animationBehavior  = NSWindowAnimationBehaviorNone ;
        self.level              = NSNormalWindowLevel ;

        _selfRef                = LUA_NOREF ;
        _contentManagerRef      = LUA_NOREF ;
        _notificationCallback   = LUA_NOREF ;
        _passthroughCallbackRef = LUA_NOREF ;
        _deleteOnClose          = NO ;
        _closeOnEscape          = NO ;
        _allowKeyboardEntry     = YES ;
        _animationTime          = nil ;
        _subroleOverride        = nil ;
        _notifyFor              = [[NSMutableSet alloc] initWithArray:@[
                                                                          @"willClose",
                                                                          @"didBecomeKey",
                                                                          @"didResignKey",
                                                                          @"didResize",
                                                                          @"didMove",
                                                                      ]] ;
        self.delegate           = self ;
    }
    return self ;
}

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
    if (_animationTime) {
        return [_animationTime doubleValue] ;
    } else {
        return [super animationResizeTime:newWindowFrame] ;
    }
}

- (NSString *)accessibilitySubrole {
    if (_subroleOverride) {
        if ([_subroleOverride isEqualToString:@""]) {
            return [super accessibilitySubrole] ;
        } else {
            return _subroleOverride ;
        }
    } else {
        return [[super accessibilitySubrole] stringByAppendingString:@".Hammerspoon"] ;
    }
}

- (BOOL)canBecomeKeyWindow {
    return _allowKeyboardEntry ;
}

- (BOOL)windowShouldClose:(id __unused)sender {
    if ((self.styleMask & NSClosableWindowMask) != 0) {
        return YES ;
    } else {
        return NO ;
    }
}

- (void)cancelOperation:(id)sender {
    if (_closeOnEscape)
        [super cancelOperation:sender] ;
}

- (void)fadeIn:(NSTimeInterval)fadeTime {
    [self setAlphaValue:0.0];
    [self makeKeyAndOrderFront:nil];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:fadeTime];
    [[self animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];
}

- (void)fadeOut:(NSTimeInterval)fadeTime andDelete:(BOOL)deleteWindow {
    [NSAnimationContext beginGrouping];
#if __has_feature(objc_arc)
      __weak HSASMGuiWindow *bself = self; // in ARC, __block would increase retain count
#else
      __block HSASMGuiWindow *bself = self;
#endif
      [[NSAnimationContext currentContext] setDuration:fadeTime];
      [[NSAnimationContext currentContext] setCompletionHandler:^{
          // unlikely that bself will go to nil after this starts, but this keeps the warnings down from [-Warc-repeated-use-of-weak]
          HSASMGuiWindow *mySelf = bself ;
          if (mySelf) {
              if (deleteWindow) {
                  [mySelf close] ; // trigger callback, if set, then cleanup
              } else {
                  [mySelf orderOut:nil];
                  [mySelf setAlphaValue:1.0];
              }
          }
      }];
      [[self animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
}

// perform callback for subviews which don't have a callback defined; see manager/internal.m for how to allow this chaining
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
    }
}

#pragma mark * NSWindowDelegate Notifications

- (void)performNotificationCallbackFor:(NSString *)message with:(NSNotification *)notification {
    if (_notificationCallback != LUA_NOREF && [_notifyFor containsObject:message]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LuaSkin *skin = [LuaSkin shared] ;
            [skin pushLuaRef:refTable ref:self->_notificationCallback] ;
            [skin pushNSObject:notification.object] ;
            [skin pushNSObject:message] ;
            if (![skin protectedCallAndTraceback:2 nresults:0]) {
                NSString *errorMsg = [skin toNSObjectAtIndex:-1] ;
                lua_pop([skin L], 1) ;
                [skin logError:[NSString stringWithFormat:@"%s:%@ notification callback error:%@", USERDATA_TAG, message, errorMsg]] ;
            }
        }) ;
    }
}

// - (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)state {}
// - (void)window:(NSWindow *)window startCustomAnimationToEnterFullScreenOnScreen:(NSScreen *)screen withDuration:(NSTimeInterval)duration {}
// - (void)window:(NSWindow *)window startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration {}
// - (void)window:(NSWindow *)window startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration {}
// - (void)window:(NSWindow *)window willEncodeRestorableState:(NSCoder *)state {}
- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didBecomeKey" with:notification] ;
}
- (void)windowDidBecomeMain:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didBecomeMain" with:notification] ;
}
- (void)windowDidChangeBackingProperties:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didChangeBackingProperties" with:notification] ;
}
- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didChangeOcclusionState" with:notification] ;
}
- (void)windowDidChangeScreen:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didChangeScreen" with:notification] ;
}
- (void)windowDidChangeScreenProfile:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didChangeScreenProfile" with:notification] ;
}
- (void)windowDidDeminiaturize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didDeminiaturize" with:notification] ;
}
- (void)windowDidEndLiveResize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didEndLiveResize" with:notification] ;
}
- (void)windowDidEndSheet:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didEndSheet" with:notification] ;
}
- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didEnterFullScreen" with:notification] ;
}
- (void)windowDidEnterVersionBrowser:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didEnterVersionBrowser" with:notification] ;
}
- (void)windowDidExitFullScreen:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didExitFullScreen" with:notification] ;
}
- (void)windowDidExitVersionBrowser:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didExitVersionBrowser" with:notification] ;
}
- (void)windowDidExpose:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didExpose" with:notification] ;
}
- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    [self performNotificationCallbackFor:@"didFailToEnterFullScreen"
                                    with:[NSNotification notificationWithName:@"didFailToEnterFullScreen"
                                                                       object:window]] ;
}
- (void)windowDidFailToExitFullScreen:(NSWindow *)window {
    [self performNotificationCallbackFor:@"didFailToExitFullScreen"
                                    with:[NSNotification notificationWithName:@"didFailToExitFullScreen"
                                                                       object:window]] ;
}
- (void)windowDidMiniaturize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didMiniaturize" with:notification] ;
}
- (void)windowDidMove:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didMove" with:notification] ;
}
- (void)windowDidResignKey:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didResignKey" with:notification] ;
}
- (void)windowDidResignMain:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didResignMain" with:notification] ;
}
- (void)windowDidResize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didResize" with:notification] ;
}
- (void)windowDidUpdate:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"didUpdate" with:notification] ;
}
- (void)windowWillBeginSheet:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willBeginSheet" with:notification] ;
}
- (void)windowWillClose:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willClose" with:notification] ;
    LuaSkin *skin = [LuaSkin shared] ;
    lua_State *L = [skin L] ;
    if (_deleteOnClose) {
        lua_pushcfunction(L, userdata_gc) ;
        [skin pushNSObject:self] ;
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
            [skin logError:[NSString stringWithFormat:@"%s:error invoking _gc for deleteOnClose:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
            lua_pop(L, 1) ;
        }
    }
}
- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willEnterFullScreen" with:notification] ;
}
- (void)windowWillEnterVersionBrowser:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willEnterVersionBrowser" with:notification] ;
}
- (void)windowWillExitFullScreen:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willExitFullScreen" with:notification] ;
}
- (void)windowWillExitVersionBrowser:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willExitVersionBrowser" with:notification] ;
}
- (void)windowWillMiniaturize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willMiniaturize" with:notification] ;
}
- (void)windowWillMove:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willMove" with:notification] ;
}
- (void)windowWillStartLiveResize:(NSNotification *)notification {
    [self performNotificationCallbackFor:@"willStartLiveResize" with:notification] ;
}

@end

static int window_orderHelper(lua_State *L, NSWindowOrderingMode mode) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;
    NSInteger relativeTo = 0 ;

    if (lua_gettop(L) > 1) {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
        HSASMGuiWindow *otherWindow = [skin toNSObjectAtIndex:2] ;
        if (otherWindow) relativeTo = [otherWindow windowNumber] ;
    }
    if (window) [window orderWindow:mode relativeTo:relativeTo] ;
    return 1 ;
}

#pragma mark - Module Functions

static int window_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;

    NSUInteger windowStyle = (lua_gettop(L) == 2) ? (NSUInteger)lua_tointeger(L, 2)
                                                  : (
                                                        NSWindowStyleMaskTitled         |
                                                        NSWindowStyleMaskClosable       |
                                                        NSWindowStyleMaskResizable      |
                                                        NSWindowStyleMaskMiniaturizable
                                                    ) ;

    HSASMGuiWindow *window = [[HSASMGuiWindow alloc] initWithContentRect:[skin tableToRectAtIndex:1]
                                                               styleMask:windowStyle
                                                                 backing:NSBackingStoreBuffered
                                                                   defer:YES] ;
    if (window) {
        [skin pushNSObject:window] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk:allowTextEntry([value]) -> guitkObject | current value
/// Method
/// Get or set whether or not the guitk object can accept keyboard entry. Defaults to true.
///
/// Parameters:
///  * `value` - an optional boolean value which sets whether or not the guitk will accept keyboard input.
///
/// Returns:
///  * If a value is provided, then this method returns the guitk object; otherwise the current value
static int guitk_allowTextEntry(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.allowKeyboardEntry) ;
    } else {
        window.allowKeyboardEntry = (BOOL) lua_toboolean(L, 2) ;
        lua_settop(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk:deleteOnClose([value]) -> guitkObject | current value
/// Method
/// Get or set whether or not the guitk should delete itself when its window is closed.
///
/// Parameters:
///  * `value` - an optional boolean value which sets whether or not the guitk will delete itself when its window is closed by any method.  Defaults to false.
///
/// Returns:
///  * If a value is provided, then this method returns the guitk object; otherwise the current value
static int guitk_deleteOnClose(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.deleteOnClose) ;
    } else {
        window.deleteOnClose = (BOOL) lua_toboolean(L, 2) ;
        lua_settop(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk:alpha([alpha]) -> guitkObject | currentValue
/// Method
/// Get or set the alpha level of the window representing the guitk object.
///
/// Parameters:
///  * `alpha` - an optional number specifying the new alpha level (0.0 - 1.0, inclusive) for the window.
///
/// Returns:
///  * If an argument is provided, the guitk object; otherwise the current value.
static int window_alphaValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, window.alphaValue) ;
    } else {
        CGFloat newAlpha = luaL_checknumber(L, 2);
        window.alphaValue = ((newAlpha < 0.0) ? 0.0 : ((newAlpha > 1.0) ? 1.0 : newAlpha)) ;
        lua_pushvalue(L, 1);
    }
    return 1 ;
}

static int window_backgroundColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:window.backgroundColor] ;
    } else {
        window.backgroundColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_hasShadow(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.hasShadow) ;
    } else {
        window.hasShadow = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_opaque(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.opaque) ;
    } else {
        window.opaque = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_styleMask(lua_State *L) {
// NOTE:  This method is wrapped in init.lua
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSUInteger oldStyle = window.styleMask ;
    if (lua_type(L, 2) == LUA_TNONE) {
        lua_pushinteger(L, (lua_Integer)oldStyle) ;
    } else {
            @try {
            // Because we're using NSPanel, the title is reset when the style is changed
                NSString *theTitle = window.title ;
            // Also, some styles don't get properly set unless we start from a clean slate
                window.styleMask = 0 ;
                window.styleMask = (NSUInteger)luaL_checkinteger(L, 2) ;
                if (theTitle) window.title = theTitle ;
            }
            @catch ( NSException *theException ) {
                window.styleMask = oldStyle ;
                return luaL_error(L, "invalid style mask: %s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
            }
        lua_settop(L, 1) ;
    }
    return 1 ;
}

static int window_title(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
      [skin pushNSObject:window.title] ;
    } else {
        window.title = [skin toNSObjectAtIndex:2] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_titlebarAppearsTransparent(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.titlebarAppearsTransparent) ;
    } else {
        window.titlebarAppearsTransparent = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk:titleVisibility([state]) -> guitkObject | currentValue
/// Function
/// Get or set whether or not the title is displayed in the guitk window titlebar.
///
/// Parameters:
///  * state - an optional string containing the text "visible" or "hidden", specifying whether or not the guitk window's title text appears.
///
/// Returns:
///  * a string of "visible" or "hidden" specifying the current (possibly changed) state of the window title's visibility.
///
/// Notes:
///  * NOT IMPLEMENTED YET - When a toolbar is attached to the guitk window (see the `hs.webview.toolbar` module documentation), this function can be used to specify whether the Toolbar appears underneath the window's title ("visible") or in the window's title bar itself, as seen in applications like Safari ("hidden").
static int window_titleVisibility(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSDictionary *mapping = @{
        @"visible" : @(NSWindowTitleVisible),
        @"hidden"  : @(NSWindowTitleHidden),
    } ;
    if (lua_gettop(L) == 1) {
        NSNumber *titleVisibility = @(window.titleVisibility) ;
        NSString *value = [[mapping allKeysForObject:titleVisibility] firstObject] ;
        if (value) {
            [skin pushNSObject:value] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized titleVisibility %@ -- notify developers", USERDATA_TAG, titleVisibility]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSNumber *value = mapping[[skin toNSObjectAtIndex:2]] ;
        if (value) {
            window.titleVisibility = [value intValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"must be one of '%@'", [[mapping allKeys] componentsJoinedByString:@"', '"]] UTF8String]) ;
        }
    }
    return 1 ;
}

static int appearanceCustomization_appearance(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:window.effectiveAppearance.name] ;
    } else {
        NSString     *type = [skin toNSObjectAtIndex:2] ;
        NSAppearance *appearance ;
        if ([type isEqualToString:@"aqua"]) {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua] ;
        } else if ([type isEqualToString:@"light"]) {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight] ;
        } else if ([type isEqualToString:@"dark"]) {
            appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark] ;
        }
        if (appearance) {
            window.appearance = appearance ;
        } else {
            return luaL_argerror(L, 2, "must be one of 'aqua', 'light', or 'dark'") ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int guitk_closeOnEscape(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, window.closeOnEscape) ;
    } else {
        window.closeOnEscape = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_frame(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSRect oldFrame = RectWithFlippedYCoordinate(window.frame);
    if (lua_gettop(L) == 1) {
        [skin pushNSRect:oldFrame] ;
    } else {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
        NSRect newFrame = RectWithFlippedYCoordinate([skin tableToRectAtIndex:2]) ;
        BOOL animate = (lua_gettop(L) == 3) ? (BOOL)lua_toboolean(L, 3) : NO ;
        [window setFrame:newFrame display:YES animate:animate];
        lua_pushvalue(L, 1);
    }
    return 1;
}

static int window_topLeft(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSRect oldFrame = RectWithFlippedYCoordinate(window.frame);
    if (lua_gettop(L) == 1) {
        [skin pushNSPoint:oldFrame.origin] ;
    } else {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
        NSPoint newCoord = [skin tableToPointAtIndex:2] ;
        BOOL animate = (lua_gettop(L) == 3) ? (BOOL)lua_toboolean(L, 3) : NO ;
        NSRect  newFrame = RectWithFlippedYCoordinate(NSMakeRect(newCoord.x, newCoord.y, oldFrame.size.width, oldFrame.size.height)) ;
        [window setFrame:newFrame display:YES animate:animate];
        lua_pushvalue(L, 1);
    }
    return 1;
}

static int window_size(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK | LS_TVARARG] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSRect oldFrame = window.frame;
    if (lua_gettop(L) == 1) {
        [skin pushNSSize:oldFrame.size] ;
    } else {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
        NSSize newSize  = [skin tableToSizeAtIndex:2] ;
        BOOL animate = (lua_gettop(L) == 3) ? (BOOL)lua_toboolean(L, 3) : NO ;
        NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y + oldFrame.size.height - newSize.height, newSize.width, newSize.height) ;
        [window setFrame:newFrame display:YES animate:animate] ;
        lua_pushvalue(L, 1) ;
    }
    return 1;
}

static int window_animationBehavior(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSDictionary *mapping = @{
        @"default"        : @(NSWindowAnimationBehaviorDefault),
        @"none"           : @(NSWindowAnimationBehaviorNone),
        @"documentWindow" : @(NSWindowAnimationBehaviorDocumentWindow),
        @"utilityWindow"  : @(NSWindowAnimationBehaviorUtilityWindow),
        @"alertPanel"     : @(NSWindowAnimationBehaviorAlertPanel),
    } ;

    if (lua_gettop(L) == 1) {
        NSNumber *animationBehavior = @(window.animationBehavior) ;
        NSString *value = [[mapping allKeysForObject:animationBehavior] firstObject] ;
        if (value) {
            [skin pushNSObject:value] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized animationBehavior %@ -- notify developers", USERDATA_TAG, animationBehavior]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSNumber *value = mapping[[skin toNSObjectAtIndex:2]] ;
        if (value) {
            window.animationBehavior = [value integerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"must be one of '%@'", [[mapping allKeys] componentsJoinedByString:@"', '"]] UTF8String]) ;
        }
    }
    return 1 ;
}

static int guitk_animationDuration(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:window.animationTime] ;
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            window.animationTime = nil ;
        } else {
            window.animationTime = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_collectionBehavior(lua_State *L) {
// NOTE:  This method is wrapped in init.lua
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    NSWindowCollectionBehavior oldBehavior = window.collectionBehavior ;
    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, oldBehavior) ;
    } else {
        @try {
            window.collectionBehavior = (NSUInteger)lua_tointeger(L, 2) ;
        }
        @catch ( NSException *theException ) {
            window.collectionBehavior = oldBehavior ;
            return luaL_error(L, "invalid collection behavior: %s, %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
        }
        lua_pushvalue(L, 1);
    }
    return 1 ;
}

/// hs._asm.guitk:delete([fadeOutTime]) -> none
/// Method
/// Destroys the guitk object, optionally fading it out first (if currently visible).
///
/// Parameters:
///  * `fadeOutTime` - An optional number of seconds over which to fade out the guitk object. Defaults to zero (i.e. immediate).
///
/// Returns:
///  * None
///
/// Notes:
///  * This method is automatically called during garbage collection, notably during a Hammerspoon termination or reload, with a fade time of 0.
static int guitk_delete(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushcfunction(L, userdata_gc) ;
        lua_pushvalue(L, 1) ;
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
            [skin logError:[NSString stringWithFormat:@"%s:error invoking _gc for delete method:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
            lua_pop(L, 1) ;
            [window orderOut:nil] ; // the least we can do is hide the guitk if an error occurs with __gc
        }
    } else {
        [window fadeOut:lua_tonumber(L, 2) andDelete:YES] ;
    }
    lua_pushnil(L);
    return 1;
}

/// hs._asm.guitk:hide([fadeOutTime]) -> guitkObject
/// Method
/// Hides the guitk object
///
/// Parameters:
///  * `fadeOutTime` - An optional number of seconds over which to fade out the guitk object. Defaults to zero (i.e. immediate).
///
/// Returns:
///  * The guitk object
static int guitk_hide(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [window orderOut:nil];
    } else {
        [window fadeOut:lua_tonumber(L, 2) andDelete:NO];
    }

    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.guitk:show([fadeInTime]) -> guitkObject
/// Method
/// Displays the guitk object
///
/// Parameters:
///  * `fadeInTime` - An optional number of seconds over which to fade in the guitk object. Defaults to zero (i.e. immediate).
///
/// Returns:
///  * The guitk object
static int guitk_show(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [window makeKeyAndOrderFront:nil];
    } else {
        [window fadeIn:lua_tonumber(L, 2)];
    }
    lua_pushvalue(L, 1);
    return 1;
}

static int guitk_accessibilitySubrole(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
      [skin pushNSObject:window.subroleOverride] ;
    } else {
        window.subroleOverride = lua_isstring(L, 2) ? [skin toNSObjectAtIndex:2] : nil ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int guitk_notificationCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if (window.notificationCallback == LUA_NOREF) {
            lua_pushnil(L) ;
        } else {
            [skin pushLuaRef:refTable ref:window.notificationCallback] ;
        }
    } else {
        // either way, lets release any function which may already be stored in the registry
        window.notificationCallback = [skin luaUnref:refTable ref:window.notificationCallback] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            window.notificationCallback = [skin luaRef:refTable] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int guitk_notificationWatchFor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TSTRING | LS_TOPTIONAL, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:window.notifyFor] ;
    } else {
        NSArray *watchingFor ;
        if (lua_type(L, 2) == LUA_TSTRING) {
            watchingFor = @[ [skin toNSObjectAtIndex:2] ] ;
        } else {
            watchingFor = [skin toNSObjectAtIndex:2] ;
            BOOL isGood = YES ;
            if ([watchingFor isKindOfClass:[NSArray class]]) {
                for (NSString *item in watchingFor) {
                    if (![item isKindOfClass:[NSString class]]) {
                        isGood = NO ;
                        break ;
                    }
                }
            } else {
                isGood = NO ;
            }
            if (!isGood) {
                return luaL_argerror(L, 2, "expected a string or an array of strings") ;
            }
        }
        BOOL willAdd = (lua_gettop(L) == 2) ? YES : (BOOL)lua_toboolean(L, 3) ;
        for (NSString *item in watchingFor) {
            if (![guitkNotifications containsObject:item]) {
                return luaL_argerror(L, 2, [[NSString stringWithFormat:@"must be one or more of the following:%@", [guitkNotifications componentsJoinedByString:@", "]] UTF8String]) ;
            }
        }
        if (willAdd) {
            for (NSString *item in watchingFor) {
                [window.notifyFor addObject:item] ;
            }
        } else {
            window.notifyFor = [[NSMutableSet alloc] initWithArray:watchingFor] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_orderAbove(lua_State *L) {
    return window_orderHelper(L, NSWindowAbove) ;
}

static int window_orderBelow(lua_State *L) {
    return window_orderHelper(L, NSWindowBelow) ;
}

static int window_level(lua_State *L) {
// NOTE:  This method is wrapped in init.lua
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, window.level) ;
    } else {
        lua_Integer targetLevel = lua_tointeger(L, 2) ;
        window.level = (targetLevel < CGWindowLevelForKey(kCGMinimumWindowLevelKey)) ? CGWindowLevelForKey(kCGMinimumWindowLevelKey) : ((targetLevel > CGWindowLevelForKey(kCGMaximumWindowLevelKey)) ? CGWindowLevelForKey(kCGMaximumWindowLevelKey) : targetLevel) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_isShowing(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, [window isVisible]) ;
    return 1 ;
}

static int window_isOccluded(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    lua_pushboolean(L, ([window occlusionState] & NSWindowOcclusionStateVisible) != NSWindowOcclusionStateVisible) ;
    return 1 ;
}

static int window_contentView(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if (window.contentManagerRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:window.contentManagerRef] ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            window.contentManagerRef = [skin luaUnref:refTable ref:window.contentManagerRef] ;
            // placeholder, since a window/panel always has one after init, let's follow that pattern
            window.contentView = [[NSView alloc] initWithFrame:window.contentView.bounds] ;
        } else {
            NSView *manager = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
            if (!manager || ![manager isKindOfClass:[NSView class]]) {
                return luaL_argerror(L, 2, "expected userdata representing a gui content manager (NSView subclass)") ;
            }
            window.contentManagerRef = [skin luaUnref:refTable ref:window.contentManagerRef] ;
            lua_pushvalue(L, 2) ;
            // maintain our own reference to the the userdata for the manager in case the user doesn't.
            window.contentManagerRef = [skin luaRef:refTable] ;
            window.contentView = manager ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

static int window_passthroughCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        window.passthroughCallbackRef = [skin luaUnref:refTable ref:window.passthroughCallbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            window.passthroughCallbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (window.passthroughCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:window.passthroughCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

static int window_firstResponder(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGuiWindow *window = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
//     // some views use internally created subviews that we don't care about or don't have a userdata type for, so this hack until I can come up
//     // with something cleaner...
        NSResponder *trying = window.firstResponder ;
//         [skin pushNSObject:trying withOptions:LS_NSDescribeUnknownTypes] ;
//         while (trying && (lua_type(L, -1) == LUA_TSTRING)) {
//             lua_pop(L, 1) ;
//             trying = trying.nextResponder ;
//             [skin pushNSObject:trying withOptions:LS_NSDescribeUnknownTypes] ;
//         }
//         if (!trying) {
//             lua_pop(L, 1) ;
//             lua_pushnil(L) ;
//         }
        while (trying && ![skin canPushNSObject:trying]) trying = trying.nextResponder ;
        [skin pushNSObject:trying] ; // will either be a responder we can work with or nil
    } else {
        if (lua_type(L, 2) == LUA_TNIL) {
            lua_pushboolean(L, [window makeFirstResponder:nil]) ;
        } else {
            NSView *view = (lua_type(L, 2) == LUA_TUSERDATA) ? [skin toNSObjectAtIndex:2] : nil ;
            if (!view || ![view isKindOfClass:[NSView class]]) {
                return luaL_argerror(L, 2, "expected userdata representing a gui content manager or gui element (NSView subclass)") ;
            }
            lua_pushboolean(L, [window makeFirstResponder:view]) ;
        }
    }
    return 1 ;
}

#pragma mark - Module Constants

/// hs._asm.guitk.windowBehaviors[]
/// Constant
/// Array of window behavior labels for determining how an guitk is handled in Spaces and Exposé
///
/// * `default`                   - The window can be associated to one space at a time.
/// * `canJoinAllSpaces`          - The window appears in all spaces. The menu bar behaves this way.
/// * `moveToActiveSpace`         - Making the window active does not cause a space switch; the window switches to the active space.
///
/// Only one of these may be active at a time:
///
/// * `managed`                   - The window participates in Spaces and Exposé. This is the default behavior if windowLevel is equal to NSNormalWindowLevel.
/// * `transient`                 - The window floats in Spaces and is hidden by Exposé. This is the default behavior if windowLevel is not equal to NSNormalWindowLevel.
/// * `stationary`                - The window is unaffected by Exposé; it stays visible and stationary, like the desktop window.
///
/// Only one of these may be active at a time:
///
/// * `participatesInCycle`       - The window participates in the window cycle for use with the Cycle Through Windows Window menu item.
/// * `ignoresCycle`              - The window is not part of the window cycle for use with the Cycle Through Windows Window menu item.
///
/// Only one of these may be active at a time:
///
/// * `fullScreenPrimary`         - A window with this collection behavior has a fullscreen button in the upper right of its titlebar.
/// * `fullScreenAuxiliary`       - Windows with this collection behavior can be shown on the same space as the fullscreen window.
///
/// Only one of these may be active at a time (Available in OS X 10.11 and later):
///
/// * `fullScreenAllowsTiling`    - A window with this collection behavior be a full screen tile window and does not have to have `fullScreenPrimary` set.
/// * `fullScreenDisallowsTiling` - A window with this collection behavior cannot be made a fullscreen tile window, but it can have `fullScreenPrimary` set.  You can use this setting to prevent other windows from being placed in the window’s fullscreen tile.
static int window_collectionTypeTable(lua_State *L) {
    lua_newtable(L) ;
    lua_pushinteger(L, NSWindowCollectionBehaviorDefault) ;                   lua_setfield(L, -2, "default") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorCanJoinAllSpaces) ;          lua_setfield(L, -2, "canJoinAllSpaces") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorMoveToActiveSpace) ;         lua_setfield(L, -2, "moveToActiveSpace") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorManaged) ;                   lua_setfield(L, -2, "managed") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorTransient) ;                 lua_setfield(L, -2, "transient") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorStationary) ;                lua_setfield(L, -2, "stationary") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorParticipatesInCycle) ;       lua_setfield(L, -2, "participatesInCycle") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorIgnoresCycle) ;              lua_setfield(L, -2, "ignoresCycle") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorFullScreenPrimary) ;         lua_setfield(L, -2, "fullScreenPrimary") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorFullScreenAuxiliary) ;       lua_setfield(L, -2, "fullScreenAuxiliary") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorFullScreenNone) ;            lua_setfield(L, -2, "fullScreenNone") ;
// these are 10.11+ but are constants so will be compiled in and exception handler in window_collectionBehavior will catch if
// used in 10.10, so just shut up the compiler warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    lua_pushinteger(L, NSWindowCollectionBehaviorFullScreenAllowsTiling) ;    lua_setfield(L, -2, "fullScreenAllowsTiling") ;
    lua_pushinteger(L, NSWindowCollectionBehaviorFullScreenDisallowsTiling) ; lua_setfield(L, -2, "fullScreenDisallowsTiling") ;
#pragma clang diagnostic pop
    return 1 ;
}


/// hs._asm.guitk.levels
/// Constant
/// A table of predefined window levels usable with [hs._asm.guitk:level](#level)
///
/// Predefined levels are:
///  * _MinimumWindowLevelKey - lowest allowed window level
///  * desktop
///  * desktopIcon            - [hs._asm.guitk:sendToBack](#sendToBack) is equivalent to this level - 1
///  * normal                 - normal application windows
///  * tornOffMenu
///  * floating               - equivalent to [hs._asm.guitk:bringToFront(false)](#bringToFront); where "Always Keep On Top" windows are usually set
///  * modalPanel             - modal alert dialog
///  * utility
///  * dock                   - level of the Dock
///  * mainMenu               - level of the Menubar
///  * status
///  * popUpMenu              - level of a menu when displayed (open)
///  * overlay
///  * help
///  * dragging
///  * screenSaver            - equivalent to [hs._asm.guitk:bringToFront(true)](#bringToFront)
///  * assistiveTechHigh
///  * cursor
///  * _MaximumWindowLevelKey - highest allowed window level
///
/// Notes:
///  * These key names map to the constants used in CoreGraphics to specify window levels and may not actually be used for what the name might suggest. For example, tests suggest that an active screen saver actually runs at a level of 2002, rather than at 1000, which is the window level corresponding to kCGScreenSaverWindowLevelKey.
///
///  * Each window level is sorted separately and [hs._asm.guitk:orderAbove](#orderAbove) and [hs._asm.guitk:orderBelow](#orderBelow) only arrange windows within the same level.
///
///  * If you use Dock hiding (or in 10.11+, Menubar hiding) please note that when the Dock (or Menubar) is popped up, it is done so with an implicit orderAbove, which will place it above any items you may also draw at the Dock (or MainMenu) level.
///
///  * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.
static int window_windowLevels(lua_State *L) {
    lua_newtable(L) ;
//       lua_pushinteger(L, CGWindowLevelForKey(kCGBaseWindowLevelKey)) ;              lua_setfield(L, -2, "kCGBaseWindowLevelKey") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGMinimumWindowLevelKey)) ;           lua_setfield(L, -2, "_MinimumWindowLevelKey") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGDesktopWindowLevelKey)) ;           lua_setfield(L, -2, "desktop") ;
//       lua_pushinteger(L, CGWindowLevelForKey(kCGBackstopMenuLevelKey)) ;            lua_setfield(L, -2, "kCGBackstopMenuLevelKey") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGNormalWindowLevelKey)) ;            lua_setfield(L, -2, "normal") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGFloatingWindowLevelKey)) ;          lua_setfield(L, -2, "floating") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGTornOffMenuWindowLevelKey)) ;       lua_setfield(L, -2, "tornOffMenu") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGDockWindowLevelKey)) ;              lua_setfield(L, -2, "dock") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGMainMenuWindowLevelKey)) ;          lua_setfield(L, -2, "mainMenu") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGStatusWindowLevelKey)) ;            lua_setfield(L, -2, "status") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGModalPanelWindowLevelKey)) ;        lua_setfield(L, -2, "modalPanel") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGPopUpMenuWindowLevelKey)) ;         lua_setfield(L, -2, "popUpMenu") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGDraggingWindowLevelKey)) ;          lua_setfield(L, -2, "dragging") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGScreenSaverWindowLevelKey)) ;       lua_setfield(L, -2, "screenSaver") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGMaximumWindowLevelKey)) ;           lua_setfield(L, -2, "_MaximumWindowLevelKey") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGOverlayWindowLevelKey)) ;           lua_setfield(L, -2, "overlay") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGHelpWindowLevelKey)) ;              lua_setfield(L, -2, "help") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGUtilityWindowLevelKey)) ;           lua_setfield(L, -2, "utility") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGDesktopIconWindowLevelKey)) ;       lua_setfield(L, -2, "desktopIcon") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGCursorWindowLevelKey)) ;            lua_setfield(L, -2, "cursor") ;
      lua_pushinteger(L, CGWindowLevelForKey(kCGAssistiveTechHighWindowLevelKey)) ; lua_setfield(L, -2, "assistiveTechHigh") ;
//       lua_pushinteger(L, CGWindowLevelForKey(kCGNumberOfWindowLevelKeys)) ;         lua_setfield(L, -2, "kCGNumberOfWindowLevelKeys") ;
    return 1 ;
}
/// hs._asm.guitk.masks[]
/// Constant
/// A table containing valid masks for the guitk window.
///
/// Table Keys:
///  * `borderless`             - The window has no border decorations
///  * `titled`                 - The window title bar is displayed
///  * `closable`               - The window has a close button
///  * `miniaturizable`         - The window has a minimize button
///  * `resizable`              - The window is resizable
///  * `texturedBackground`     - The window has a texturized background
///  * `fullSizeContentView`    - If titled, the titlebar is within the frame size specified at creation, not above it.  Shrinks actual content area by the size of the titlebar, if present.
///  * `utility`                - If titled, the window shows a utility panel titlebar (thinner than normal)
///  * `nonactivating`          - If the window is activated, it won't bring other Hammerspoon windows forward as well
///  * `HUD`                    - Requires utility; the window titlebar is shown dark and can only show the close button and title (if they are set)
///
/// The following are still being evaluated and may require additional support or specific methods to be in effect before use. Use with caution.
///  * `unifiedTitleAndToolbar` -
///  * `fullScreen`             -
///  * `docModal`               -
///
/// Notes:
///  * The Maximize button in the window title is enabled when Resizable is set.
///  * The Close, Minimize, and Maximize buttons are only visible when the Window is also Titled.
///
///  * Not all combinations of masks are valid and will through an error if set with [hs._asm.guitk:mask](#mask).
static int window_windowMasksTable(lua_State *L) {
    lua_newtable(L) ;
    lua_pushinteger(L, NSWindowStyleMaskBorderless) ;             lua_setfield(L, -2, "borderless") ;
    lua_pushinteger(L, NSWindowStyleMaskTitled) ;                 lua_setfield(L, -2, "titled") ;
    lua_pushinteger(L, NSWindowStyleMaskClosable) ;               lua_setfield(L, -2, "closable") ;
    lua_pushinteger(L, NSWindowStyleMaskMiniaturizable) ;         lua_setfield(L, -2, "miniaturizable") ;
    lua_pushinteger(L, NSWindowStyleMaskResizable) ;              lua_setfield(L, -2, "resizable") ;
    lua_pushinteger(L, NSWindowStyleMaskTexturedBackground) ;     lua_setfield(L, -2, "texturedBackground") ;
    lua_pushinteger(L, NSWindowStyleMaskUnifiedTitleAndToolbar) ; lua_setfield(L, -2, "unifiedTitleAndToolbar") ;
    lua_pushinteger(L, NSWindowStyleMaskFullScreen) ;             lua_setfield(L, -2, "fullScreen") ;
    lua_pushinteger(L, NSWindowStyleMaskFullSizeContentView) ;    lua_setfield(L, -2, "fullSizeContentView") ;
    lua_pushinteger(L, NSWindowStyleMaskUtilityWindow) ;          lua_setfield(L, -2, "utility") ;
    lua_pushinteger(L, NSWindowStyleMaskDocModalWindow) ;         lua_setfield(L, -2, "docModal") ;
    lua_pushinteger(L, NSWindowStyleMaskNonactivatingPanel) ;     lua_setfield(L, -2, "nonactivating") ;
    lua_pushinteger(L, NSWindowStyleMaskHUDWindow) ;              lua_setfield(L, -2, "HUD") ;
    return 1 ;
}

/// hs._asm.guitk.notifications[]
/// Constant
/// An array containing all of the notifications which can be enabled with [hs._asm.guitk:notificationMessages](#notificationMessages).
///
/// Array values:
///  * `didBecomeKey`               -
///  * `didBecomeMain`              -
///  * `didChangeBackingProperties` -
///  * `didChangeOcclusionState`    -
///  * `didChangeScreen`            -
///  * `didChangeScreenProfile`     -
///  * `didDeminiaturize`           -
///  * `didEndLiveResize`           -
///  * `didEndSheet`                -
///  * `didEnterFullScreen`         -
///  * `didEnterVersionBrowser`     -
///  * `didExitFullScreen`          -
///  * `didExitVersionBrowser`      -
///  * `didExpose`                  -
///  * `didFailToEnterFullScreen`   -
///  * `didFailToExitFullScreen`    -
///  * `didMiniaturize`             -
///  * `didMove`                    -
///  * `didResignKey`               -
///  * `didResignMain`              -
///  * `didResize`                  -
///  * `didUpdate`                  -
///  * `willBeginSheet`             -
///  * `willClose`                  -
///  * `willEnterFullScreen`        -
///  * `willEnterVersionBrowser`    -
///  * `willExitFullScreen`         -
///  * `willExitVersionBrowser`     -
///  * `willMiniaturize`            -
///  * `willMove`                   -
///  * `willStartLiveResize`        -
//
// Notes:
static int window_notifications(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    guitkNotifications = @[
        @"didBecomeKey",
        @"didBecomeMain",
        @"didChangeBackingProperties",
        @"didChangeOcclusionState",
        @"didChangeScreen",
        @"didChangeScreenProfile",
        @"didDeminiaturize",
        @"didEndLiveResize",
        @"didEndSheet",
        @"didEnterFullScreen",
        @"didEnterVersionBrowser",
        @"didExitFullScreen",
        @"didExitVersionBrowser",
        @"didExpose",
        @"didFailToEnterFullScreen",
        @"didFailToExitFullScreen",
        @"didMiniaturize",
        @"didMove",
        @"didResignKey",
        @"didResignMain",
        @"didResize",
        @"didUpdate",
        @"willBeginSheet",
        @"willClose",
        @"willEnterFullScreen",
        @"willEnterVersionBrowser",
        @"willExitFullScreen",
        @"willExitVersionBrowser",
        @"willMiniaturize",
        @"willMove",
        @"willStartLiveResize",
    ] ;
    [skin pushNSObject:guitkNotifications] ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGuiWindow(lua_State *L, id obj) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGuiWindow *value = obj;
    if (value.selfRef == LUA_NOREF) {
        void** valuePtr = lua_newuserdata(L, sizeof(HSASMGuiWindow *));
        *valuePtr = (__bridge_retained void *)value;
        luaL_getmetatable(L, USERDATA_TAG);
        lua_setmetatable(L, -2);
        value.selfRef = [skin luaRef:refTable] ;
    }
    [skin pushLuaRef:refTable ref:value.selfRef] ;
    return 1;
}

id toHSASMGuiWindowFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGuiWindow *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGuiWindow, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGuiWindow *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGuiWindow"] ;
    NSString *title = obj.title ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGuiWindow *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGuiWindow"] ;
        HSASMGuiWindow *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGuiWindow"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGuiWindow *obj = get_objectFromUserdata(__bridge_transfer HSASMGuiWindow, L, 1, USERDATA_TAG) ;
    if (obj) {
        LuaSkin *skin = [LuaSkin shared];
        obj.selfRef                = [skin luaUnref:refTable ref:obj.selfRef] ;
        obj.notificationCallback   = [skin luaUnref:refTable ref:obj.notificationCallback] ;
        obj.contentManagerRef      = [skin luaUnref:refTable ref:obj.contentManagerRef] ;
        obj.passthroughCallbackRef = [skin luaUnref:refTable ref:obj.passthroughCallbackRef] ;
        obj.delegate               = nil ;
        obj.deleteOnClose          = NO ; // shouldn't matter since delegate already nil, but just in case we don't want a loop
        obj.contentView            = nil ;
        [obj close] ;
        obj                        = nil ;
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
    {"delete",                     guitk_delete},
    {"hide",                       guitk_hide},
    {"show",                       guitk_show},
    {"animationDuration",          guitk_animationDuration},
    {"closeOnEscape",              guitk_closeOnEscape},
    {"notificationCallback",       guitk_notificationCallback},
    {"notificationMessages",       guitk_notificationWatchFor},
    {"accessibilitySubrole",       guitk_accessibilitySubrole},
    {"deleteOnClose",              guitk_deleteOnClose},
    {"allowTextEntry",             guitk_allowTextEntry},

    {"alphaValue",                 window_alphaValue},
    {"animationBehavior",          window_animationBehavior},
    {"collectionBehavior",         window_collectionBehavior},
    {"isOccluded",                 window_isOccluded},
    {"isShowing",                  window_isShowing},
    {"level",                      window_level},
    {"orderAbove",                 window_orderAbove},
    {"orderBelow",                 window_orderBelow},
    {"frame",                      window_frame},
    {"size",                       window_size},
    {"topLeft",                    window_topLeft},
    {"backgroundColor",            window_backgroundColor},
    {"hasShadow",                  window_hasShadow},
    {"opaque",                     window_opaque},
    {"styleMask",                  window_styleMask},
    {"title",                      window_title},
    {"titlebarAppearsTransparent", window_titlebarAppearsTransparent},
    {"titleVisibility",            window_titleVisibility},
    {"contentManager",             window_contentView},
    {"passthroughCallback",        window_passthroughCallback},
    {"activeElement",              window_firstResponder},

    {"appearance",                 appearanceCustomization_appearance},

    {"__tostring",                 userdata_tostring},
    {"__eq",                       userdata_eq},
    {"__gc",                       userdata_gc},
    {NULL,                         NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", window_new},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_internal(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGuiWindow         forClass:"HSASMGuiWindow"];
    [skin registerLuaObjectHelper:toHSASMGuiWindowFromLua forClass:"HSASMGuiWindow"
                                               withUserdataMapping:USERDATA_TAG];

    window_collectionTypeTable(L) ; lua_setfield(L, -2, "behaviors") ;
    window_windowLevels(L) ;        lua_setfield(L, -2, "levels") ;
    window_windowMasksTable(L) ;    lua_setfield(L, -2, "masks") ;
    window_notifications(L) ;       lua_setfield(L, -2, "notifications") ;

    return 1;
}
