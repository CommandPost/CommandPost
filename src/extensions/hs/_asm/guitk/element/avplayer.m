// TODO:
//  * test
//    PauseWhenHidden not working

/// === hs._asm.guitk.element.avplayer ===
///
/// Provides an AudioVisual player element for `hs._asm.guitk`.
///
/// If you wish to include other elements within the window containing the avplayer object, you will need to use an `hs._asm.guitk.manager` object.  However, since this element is fully self contained and provides its own controls for video playback, it may be easier to attach this element directly to a `hs._asm.guitk` window object when you don't require other elements in the visual display.
///
/// Playback of remote or streaming content has been tested against http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8, which is a sample URL provided in the Apple documentation at https://developer.apple.com/library/prerelease/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html#//apple_ref/doc/uid/TP40010188-CH3-SW4
///
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import LuaSkin ;
@import AVKit ;
@import AVFoundation ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.avplayer" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

static const int32_t PREFERRED_TIMESCALE = 60000 ; // see https://warrenmoore.net/understanding-cmtime
static void *myKVOContext = &myKVOContext ; // See http://nshipster.com/key-value-observing/

static NSDictionary *CONTROLS_STYLES ;

#pragma mark - Support Functions and Classes

static void defineInternalDictionaryies() {
    CONTROLS_STYLES = @{
        @"none"     : @(AVPlayerViewControlsStyleNone),
        @"inline"   : @(AVPlayerViewControlsStyleInline),
        @"floating" : @(AVPlayerViewControlsStyleFloating),
        @"minimal"  : @(AVPlayerViewControlsStyleMinimal),
        @"default"  : @(AVPlayerViewControlsStyleDefault),
    } ;
}

@interface HSASMGUITKElementAVPlayer : AVPlayerView
@property BOOL       pauseWhenHidden ;
@property BOOL       trackCompleted ;
@property BOOL       trackRate ;
@property BOOL       trackStatus ;
@property int        callbackRef ;
@property int        selfRefCount ;
@property id         periodicObserver ;
@property lua_Number periodicPeriod ;
@end

@implementation HSASMGUITKElementAVPlayer {
    float rateWhenHidden ;
}

- (instancetype)initWithFrame:(NSRect)frameRect {

    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _callbackRef                     = LUA_NOREF ;
        _selfRefCount                    = 0 ;
        _pauseWhenHidden                 = YES ;
        _trackCompleted                  = NO ;
        _trackRate                       = NO ;
        _trackStatus                     = NO ;
        _periodicObserver                = nil ;
        _periodicPeriod                  = 0.0 ;

        rateWhenHidden                   = 0.0f ;

        self.player                        = [[AVPlayer alloc] init] ;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        if ([self.player respondsToSelector:@selector(allowsExternalPlayback)]) {
            self.player.allowsExternalPlayback = NO ; // 10.11+
        }
#pragma clang diagnostic pop

        self.controlsStyle               = AVPlayerViewControlsStyleDefault ;
        self.showsFrameSteppingButtons   = NO ;
        self.showsSharingServiceButton   = NO ;
        self.showsFullScreenToggleButton = NO ;
        self.actionPopUpButtonMenu       = nil ;
    }
    return self;
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

- (void)didFinishPlaying:(__unused NSNotification *)notification {
    if (_trackCompleted) {
        if (_callbackRef != LUA_NOREF) {
            LuaSkin *skin = [LuaSkin shared] ;
            lua_State *L = [skin L] ;
            [skin pushLuaRef:refTable ref:self->_callbackRef] ;
            [skin pushNSObject:self] ;
            [skin pushNSObject:@"finished"] ;
            if (![skin protectedCallAndTraceback:2 nresults:0]) {
                NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                lua_pop(L, 1) ;
                [skin logError:[NSString stringWithFormat:@"%s:trackCompleted callback error:%@", USERDATA_TAG, errorMessage]] ;
            }
        } else {
            [self passCallbackUpWith:@[ self, @"finished" ]] ;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (_trackRate && context == myKVOContext && [keyPath isEqualToString:@"rate"]) {
        NSString *message = (self.player.rate == 0.0f) ? @"pause" : @"play" ;
        if (_callbackRef != LUA_NOREF) {
            LuaSkin *skin = [LuaSkin shared] ;
            lua_State *L  = [skin L] ;
            [skin pushLuaRef:refTable ref:_callbackRef] ;
            [skin pushNSObject:self] ;
            [skin pushNSObject:message] ;
            lua_pushnumber(L, (lua_Number)self.player.rate) ;
            if (![skin protectedCallAndTraceback:3 nresults:0]) {
                NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                lua_pop(L, 1) ;
                [skin logError:[NSString stringWithFormat:@"%s:trackRate callback error:%@", USERDATA_TAG, errorMessage]] ;
            }
        } else {
            [self passCallbackUpWith:@[ self, message, @(self.player.rate) ]] ;
        }
    } else if (_trackStatus && context == myKVOContext && [keyPath isEqualToString:@"status"]) {
        NSMutableArray *args = [[NSMutableArray alloc] init] ;
        [args addObjectsFromArray:@[ self, @"status" ]] ;
        switch(self.player.currentItem.status) {
            case AVPlayerStatusUnknown:
                [args addObject:@"unknown"] ;
                break ;
            case AVPlayerStatusReadyToPlay:
                [args addObject:@"readyToPlay"] ;
                break ;
            case AVPlayerStatusFailed: {
                NSString *message = self.player.currentItem.error.localizedDescription ;
                if (!message) message = @"no reason given" ;
                [args addObjectsFromArray:@[ @"failed", message ]] ;
                } break ;
            default:
                [args addObjectsFromArray:@[ @"unrecognized status", @(self.player.currentItem.status) ]] ;
                break ;
        }

        if (_callbackRef != LUA_NOREF) {
            LuaSkin *skin = [LuaSkin shared] ;
            lua_State *L  = [skin L] ;
            [skin pushLuaRef:refTable ref:_callbackRef] ;
            for (id item in args) [skin pushNSObject:item] ;
            if (![skin protectedCallAndTraceback:(int)args.count nresults:0]) {
                NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                lua_pop(L, 1) ;
                [skin logError:[NSString stringWithFormat:@"%s:trackStatus callback error:%@", USERDATA_TAG, errorMessage]] ;
            }
        } else {
            [self passCallbackUpWith:args] ;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context] ;
    }
}

- (void) menuSelectionCallback:(NSMenuItem *)sender {
    NSString *title = sender.title ;
    NSEventModifierFlags theFlags = [NSEvent modifierFlags] ;
    NSDictionary *flags = @{
        @"cmd"   : @((theFlags & NSEventModifierFlagCommand) != 0),
        @"shift" : @((theFlags & NSEventModifierFlagShift) != 0),
        @"alt"   : @((theFlags & NSEventModifierFlagOption) != 0),
        @"ctrl"  : @((theFlags & NSEventModifierFlagControl) != 0),
        @"fn"    : @((theFlags & NSEventModifierFlagFunction) != 0),
        @"_raw"  : @(theFlags),
    } ;

    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        lua_State *L  = [skin L] ;
        [skin pushLuaRef:refTable ref:self->_callbackRef] ;
        [skin pushNSObject:self] ;
        [skin pushNSObject:@"actionMenu"] ;
        [skin pushNSObject:title] ;
        [skin pushNSObject:flags] ;
        if (![skin protectedCallAndTraceback:4 nresults:0]) {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            lua_pop(L, 1) ;
            [skin logError:[NSString stringWithFormat:@"%s:actionMenu callback error:%@", USERDATA_TAG, errorMessage]] ;
        }
    } else {
        [self passCallbackUpWith:@[ self, @"actionMenu", title, flags ]] ;
    }
}

- (void)viewDidHide {
    if (_pauseWhenHidden) {
        rateWhenHidden = self.player.rate ;
        [self.player pause] ;
    }
}

- (void)viewDidUnhide {
    if (rateWhenHidden != 0.0f) {
        self.player.rate = rateWhenHidden ;
        rateWhenHidden = 0.0f ;
    }
}

@end

#pragma mark - Module Functions

/// hs._asm.guitk.element.avplayer.new([frame]) -> avplayerObject
/// Constructor
/// Creates a new AVPlayer element for `hs._asm.guitk` which can display audiovisual media.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for the avplayer object.
///
/// Returns:
///  * the avplayerObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
static int avplayer_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementAVPlayer *avplayer = [[HSASMGUITKElementAVPlayer alloc] initWithFrame:frameRect] ;
    if (avplayer) {
        if (lua_gettop(L) != 1) [avplayer setFrameSize:[avplayer fittingSize]] ;
        [skin pushNSObject:avplayer] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

#pragma mark - Module Methods - ASMAVPlayerView methods

/// hs._asm.guitk.element.avplayer:controlsStyle([style]) -> avplayerObject | string
/// Method
/// Get or set the style of controls displayed in the avplayerObject for controlling media playback.
///
/// Parameters:
///  * `style` - an optional string, default "default", specifying the stye of the controls displayed for controlling media playback.  The string may be one of the following:
///    * `none`     - no controls are provided -- playback must be managed programmatically through Hammerspoon Lua code.
///    * `inline`   - media controls are displayed in an autohiding status bar at the bottom of the media display.
///    * `floating` - media controls are displayed in an autohiding panel which floats over the media display.
///    * `minimal`  - media controls are displayed as a round circle in the center of the media display.
///    * `none`     - no media controls are displayed in the media display.
///    * `default`  - use the OS X default control style; under OS X 10.11, this is the "inline".
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
static int avplayer_controlsStyle(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *controlsStyle = @(playerView.controlsStyle) ;
        NSArray *temp = [CONTROLS_STYLES allKeysForObject:controlsStyle];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized controls style %@ for AVPlayerView -- notify developers", USERDATA_TAG, controlsStyle]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *controlsStyle = CONTROLS_STYLES[key] ;
        if (controlsStyle) {
            playerView.controlsStyle = [controlsStyle integerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"must be one of %@", [[CONTROLS_STYLES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:frameSteppingButtons([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether frame stepping or scrubbing controls are included in the media controls.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether frame stepping (true) or scrubbing (false) controls are included in the media controls.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
static int avplayer_showsFrameSteppingButtons(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.showsFrameSteppingButtons) ;
    } else {
        playerView.showsFrameSteppingButtons = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:flashChapterAndTitle(number, [string]) -> avplayerObject
/// Method
/// Flashes the number and optional string over the media playback display momentarily.
///
/// Parameters:
///  * `number` - an integer specifying the chapter number to display.
///  * `string` - an optional string specifying the chapter name to display.
///
/// Returns:
///  * the avplayerObject
///
/// Notes:
///  * If only a number is provided, the text "Chapter #" is displayed.  If a string is also provided, "#. string" is displayed.
static int avplayer_flashChapterAndTitle(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TINTEGER,
                    LS_TSTRING | LS_TOPTIONAL,
                    LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    NSUInteger       chapterNumber = (lua_Unsigned)lua_tointeger(L, 2) ;
    NSString         *chapterTitle = (lua_gettop(L) == 3) ? [skin toNSObjectAtIndex:3] : nil ;

    [playerView flashChapterNumber:chapterNumber chapterTitle:chapterTitle] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:pauseWhenHidden([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not playback of media should be paused when the avplayer object is hidden.
///
/// Parameters:
///  * `state` - an optional boolean, default true, specifying whether or not media playback should be paused when the avplayer object is hidden.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Note:
///  * this method currently does not work; fixing this is in the TODO list.
static int avplayer_pauseWhenHidden(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.pauseWhenHidden) ;
    } else {
        playerView.pauseWhenHidden = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:callback(fn) -> avplayerObject | fn | nil
/// Method
/// Get or Set the callback function for the avplayerObject.
///
/// Parameters:
///  * `fn` - a function, or explicit `nil`, specifying the callback function which is used by this avplayerObject.  If `nil` is specified, the currently active callback function is removed.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * The callback function should expect 2 or more arguments.  The first two arguments will always be:
///    * `avplayObject` - the avplayerObject userdata
///    * `message`      - a string specifying the reason for the callback.
///    * Additional arguments depend upon the message.  See the following methods for details concerning the arguments for each message:
///      * `finished`   - [hs._asm.guitk.element.avplayer:trackCompleted](#trackCompleted)
///      * `pause`      - [hs._asm.guitk.element.avplayer:trackRate](#trackRate)
///      * `play`       - [hs._asm.guitk.element.avplayer:trackRate](#trackRate)
///      * `progress`   - [hs._asm.guitk.element.avplayer:trackProgress](#trackProgress)
///      * `seek`       - [hs._asm.guitk.element.avplayer:seek](#seek)
///      * `status`     - [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus)

// currently not enabled, waiting for hs.menubar rewrite
// ///    * `actionMenu` - [hs._asm.guitk.element.avplayer:actionMenu](#actionMenu)

static int avplayer_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        playerView.callbackRef = [skin luaUnref:refTable ref:playerView.callbackRef];
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2);
            playerView.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (playerView.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:playerView.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

// /// hs._asm.guitk.element.avplayer:actionMenu(menutable | nil) -> avplayerObject
// /// Method
// /// Set or remove the additional actions menu from the media controls for the avplayer.
// ///
// /// Parameters:
// ///  * `menutable` - a table containing a menu definition as described in the documentation for `hs.menubar:setMenu`.  If `nil` is specified, any existing menu is removed.
// ///
// /// Parameters:
// ///  * the avplayerObject
// ///
// /// Notes:
// ///  * All menu keys supported by `hs.menubar:setMenu`, except for the `fn` key, are supported by this method.
// ///  * When a menu item is selected, the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) is invoked with the following 4 arguments:
// ///    * the avplayerObject
// ///    * "actionMenu"
// ///    * the `title` field of the menu item selected
// ///    * a table containing the following keys set to true or false indicating which key modifiers were down when the menu item was selected: "cmd", "shift", "alt", "ctrl", and "fn".
// static int avplayer_actionMenu(lua_State *L) {
//     LuaSkin *skin = [LuaSkin shared];
//     [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TNIL, LS_TBREAK] ;
//     HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
//
// // TODO: I *really* want hs.menubar to be re-written so menus can be used in other modules... maybe someday
//
//     if (lua_type(L, 2) == LUA_TNIL) {
//         playerView.actionPopUpButtonMenu = nil ;
//     } else {
//         NSArray *menuItems = [skin toNSObjectAtIndex:2] ;
//         if (![menuItems isKindOfClass:[NSArray class]]) {
//             return luaL_argerror(L, 2, "must be an array of key-value tables") ;
//         }
//         for (NSString *item in menuItems) {
//             if (![item isKindOfClass:[NSDictionary class]]) {
//                 return luaL_argerror(L, 2, "must be an array of key-value tables") ;
//             }
//         }
//         playerView.actionPopUpButtonMenu = menuMaker(menuItems, playerView) ;
//     }
//     lua_pushvalue(L, 1) ;
//     return 1 ;
// }

#pragma mark - Module Methods - AVPlayer methods

/// hs._asm.guitk.element.avplayer:load(path) -> avplayerObject
/// Method
/// Load the specified resource for playback.
///
/// Parameters:
///  * `path` - a string specifying the file path or URL to the audiovisual resource.
///
/// Returns:
///  * the avplayerObject
///
/// Notes:
///  * Content will not start autoplaying when loaded - you must use the controls provided in the audiovisual player or one of [hs._asm.guitk.element.avplayer:play](#play) or [hs._asm.guitk.element.avplayer:rate](#rate) to begin playback.
///
///  * If the path or URL are malformed, unreachable, or otherwise unavailable, [hs._asm.guitk.element.avplayer:status](#status) will return "failed".
///  * Because a remote URL may not respond immediately, you can also setup a callback with [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus) to be notified when the item has loaded or if it has failed.
static int avplayer_load(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TNIL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (player.currentItem) {
        if (playerView.trackCompleted) {
            [[NSNotificationCenter defaultCenter] removeObserver:playerView
                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:player.currentItem] ;
        }
        if (playerView.trackStatus) {
            [player.currentItem removeObserver:playerView forKeyPath:@"status" context:myKVOContext] ;
        }
    }

    player.rate = 0.0f ; // any load should start in a paused state
    [player replaceCurrentItemWithPlayerItem:nil] ;

    if (lua_type(L, 2) != LUA_TNIL) {
        NSString *path   = [skin toNSObjectAtIndex:2] ;
        NSURL    *theURL = [NSURL URLWithString:path] ;

        if (!theURL) {
//             [LuaSkin logInfo:@"trying as fileURL"] ;
            theURL = [NSURL fileURLWithPath:[path stringByExpandingTildeInPath]] ;
        }

        [player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:theURL]] ;
    }

    if (player.currentItem) {
        if (playerView.trackCompleted) {
            [[NSNotificationCenter defaultCenter] addObserver:playerView
                                                     selector:@selector(didFinishPlaying:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:player.currentItem] ;
        }
        if (playerView.trackStatus) {
            [player.currentItem addObserver:playerView
                                 forKeyPath:@"status"
                                    options:NSKeyValueObservingOptionNew
                                    context:myKVOContext] ;
        }
    }

    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:play([fromBeginning]) -> avplayerObject
/// Method
/// Play the audiovisual media currently loaded in the avplayer object.
///
/// Parameters:
///  * `fromBeginning` - an optional boolean, default false, specifying whether or not the media playback should start from the beginning or from the current location.
///
/// Returns:
///  * the avplayerObject
///
/// Notes:
///  * this is equivalent to setting the rate to 1.0 (see [hs._asm.guitk.element.avplayer:rate](#rate)`)
static int avplayer_play(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 2 && lua_toboolean(L, 2)) {
        [player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero] ;
    }
    [player play] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:pause() -> avplayerObject
/// Method
/// Pause the audiovisual media currently loaded in the avplayer object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the avplayerObject
///
/// Notes:
///  * this is equivalent to setting the rate to 0.0 (see [hs._asm.guitk.element.avplayer:rate](#rate)`)
static int avplayer_pause(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    [player pause] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:rate([rate]) -> avplayerObject | number
/// Method
/// Get or set the rate of playback for the audiovisual content of the avplayer object.
///
/// Parameters:
///  * `rate` - an optional number specifying the rate you wish for the audiovisual content to be played.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * This method affects the playback rate of both video and audio -- if you wish to mute audio during a "fast forward" or "rewind", see [hs._asm.guitk.element.avplayer:mute](#mute).
///  * A value of 0.0 is equivalent to [hs._asm.guitk.element.avplayer:pause](#pause).
///  * A value of 1.0 is equivalent to [hs._asm.guitk.element.avplayer:play](#play).
///
///  * Other rates may not be available for all media and will be ignored if specified and the media does not support playback at the specified rate:
///    * Rates between 0.0 and 1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlaySlowForward` field
///    * Rates greater than 1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayFastForward` field
///    * The item can be played in reverse (a rate of -1.0) if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayReverse` field
///    * Rates between 0.0 and -1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlaySlowReverse` field
///    * Rates less than -1.0 are allowed if [hs._asm.guitk.element.avplayer:playbackInformation](#playbackInformation) returns true for the `canPlayFastReverse` field
static int avplayer_rate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, (lua_Number)player.rate) ;
    } else {
        player.rate = (float)lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:mute([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not audio output is muted for the audovisual media item.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not audio output has been muted for the avplayer object.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
static int avplayer_mute(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, player.muted) ;
    } else {
        player.muted = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:volume([volume]) -> avplayerObject | number
/// Method
/// Get or set the avplayer object's volume on a linear scale from 0.0 (silent) to 1.0 (full volume, relative to the current OS volume).
///
/// Parameters:
///  * `volume` - an optional number, default as specified by the media or 1.0 if no designation is specified by the media, specifying the player's volume relative to the system volume level.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
static int avplayer_volume(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, (lua_Number)player.volume) ;
    } else {
        float newLevel = (float)lua_tonumber(L, 2) ;
        player.volume = ((newLevel < 0.0f) ? 0.0f : ((newLevel > 1.0f) ? 1.0f : newLevel)) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:ccEnabled([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not the player can use close captioning, if it is included in the audiovisual content.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the player should display closed captioning information, if it is available.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
static int avplayer_closedCaptionDisplayEnabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, player.closedCaptionDisplayEnabled) ;
    } else {
        player.closedCaptionDisplayEnabled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:trackProgress([number | nil]) -> avplayerObject | number | nil
/// Method
/// Enable or disable a periodic callback at the interval specified.
///
/// Parameters:
///  * `number` - an optional number specifying how often, in seconds, the callback function should be invoked to report progress.  If an explicit nil is specified, then the progress callback is disabled. Defaults to nil.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.  A return value of `nil` indicates that no progress callback is in effect.
///
/// Notes:
///  * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 arguments:
///    * the avplayerObject
///    * "progress"
///    * the time in seconds specifying the current location in the media playback.
///
///  * From Apple Documentation: The block is invoked periodically at the interval specified, interpreted according to the timeline of the current item. The block is also invoked whenever time jumps and whenever playback starts or stops. If the interval corresponds to a very short interval in real time, the player may invoke the block less frequently than requested. Even so, the player will invoke the block sufficiently often for the client to update indications of the current time appropriately in its end-user interface.
static int avplayer_trackProgress(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player     = playerView.player ;

    if (lua_gettop(L) == 1) {
        if (playerView.periodicObserver) {
            lua_pushnumber(L, playerView.periodicPeriod) ;
        } else {
            lua_pushnil(L) ;
        }
    } else {
        if (playerView.periodicObserver) {
            [player removeTimeObserver:playerView.periodicObserver] ;
            playerView.periodicObserver = nil ;
            playerView.periodicPeriod = 0.0 ;
        }
        if (lua_type(L, 2) == LUA_TNUMBER) {
            playerView.periodicPeriod = lua_tonumber(L, 2) ;
            CMTime period = CMTimeMakeWithSeconds(playerView.periodicPeriod, PREFERRED_TIMESCALE) ;
            playerView.periodicObserver = [player addPeriodicTimeObserverForInterval:period
                                                                               queue:NULL
                                                                          usingBlock:^(CMTime time) {
                if (playerView.callbackRef != LUA_NOREF) {
                    [skin pushLuaRef:refTable ref:playerView.callbackRef] ;
                    [skin pushNSObject:playerView] ;
                    lua_pushstring(L, "progress") ;
                    lua_pushnumber(L, CMTimeGetSeconds(time)) ;
                    if (![skin protectedCallAndTraceback:3 nresults:0]) {
                        NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                        lua_pop(L, 1) ;
                        [skin logError:[NSString stringWithFormat:@"%s:trackProgress callback error:%@", USERDATA_TAG, errorMessage]] ;
                    }
                } else {
                    [playerView passCallbackUpWith:@[ playerView, @"progress", @(CMTimeGetSeconds(time)) ]] ;
                }
            }] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:trackRate([state]) -> avplayerObject | boolean
/// Method
/// Enable or disable a callback whenever the rate of playback changes.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not playback rate changes should invoke a callback.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 arguments:
///    * the avplayerObject
///    * "pause", if the rate changes to 0.0, or "play" if the rate changes to any other value
///    * the rate that the playback was changed to.
///
///  * Not all media content can have its playback rate changed; attempts to do so will invoke the callback twice -- once signifying that the change was made, and a second time indicating that the rate of play was reset back to the limits of the media content.  See [hs._asm:rate](#rate) for more information.
static int avplayer_trackRate(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player     = playerView.player ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.trackRate) ;
    } else {
        if (playerView.trackRate) {
            [player removeObserver:playerView forKeyPath:@"rate" context:myKVOContext] ;
        }

        playerView.trackRate = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;

        if (playerView.trackRate) {
            [player addObserver:playerView
                     forKeyPath:@"rate"
                        options:NSKeyValueObservingOptionNew
                        context:myKVOContext] ;
        }
    }
    return 1 ;
}

#pragma mark - Module Methods - AVPlayerItem methods

/// hs._asm.guitk.element.avplayer:playbackInformation() -> table | nil
/// Method
/// Returns a table containing information about the media playback characteristics of the audiovisual media currently loaded in the avplayerObject.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table containing the following media characteristics, or `nil` if no media content is currently loaded:
///    * "playbackLikelyToKeepUp" - Indicates whether the item will likely play through without stalling.  Note that this is only a prediction.
///    * "playbackBufferEmpty"    - Indicates whether playback has consumed all buffered media and that playback may stall or end.
///    * "playbackBufferFull"     - Indicates whether the internal media buffer is full and that further I/O is suspended.
///    * "canPlayReverse"         - A Boolean value indicating whether the item can be played with a rate of -1.0.
///    * "canPlayFastForward"     - A Boolean value indicating whether the item can be played at rates greater than 1.0.
///    * "canPlayFastReverse"     - A Boolean value indicating whether the item can be played at rates less than –1.0.
///    * "canPlaySlowForward"     - A Boolean value indicating whether the item can be played at a rate between 0.0 and 1.0.
///    * "canPlaySlowReverse"     - A Boolean value indicating whether the item can be played at a rate between -1.0 and 0.0.
static int avplayer_playbackInformation(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;

    if (playerItem) {
        lua_newtable(L) ;
        lua_pushboolean(L, playerItem.playbackLikelyToKeepUp) ; lua_setfield(L, -2, "playbackLikelyToKeepUp") ;
        lua_pushboolean(L, playerItem.playbackBufferEmpty) ;    lua_setfield(L, -2, "playbackBufferEmpty") ;
        lua_pushboolean(L, playerItem.playbackBufferFull) ;     lua_setfield(L, -2, "playbackBufferFull") ;
        lua_pushboolean(L, playerItem.canPlayReverse) ;         lua_setfield(L, -2, "canPlayReverse") ;
        lua_pushboolean(L, playerItem.canPlayFastForward) ;     lua_setfield(L, -2, "canPlayFastForward") ;
        lua_pushboolean(L, playerItem.canPlayFastReverse) ;     lua_setfield(L, -2, "canPlayFastReverse") ;
        lua_pushboolean(L, playerItem.canPlaySlowForward) ;     lua_setfield(L, -2, "canPlaySlowForward") ;
        lua_pushboolean(L, playerItem.canPlaySlowReverse) ;     lua_setfield(L, -2, "canPlaySlowReverse") ;

// Not currently supported by the module since it involves tracks
//         lua_pushboolean(L, playerItem.canStepBackward) ;        lua_setfield(L, -2, "canStepBackward") ;
//         lua_pushboolean(L, playerItem.canStepForward) ;         lua_setfield(L, -2, "canStepForward") ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:status() -> status[, error] | nil
/// Method
/// Returns the current status of the media content loaded for playback.
///
/// Parameters:
///  * None
///
/// Returns:
///  * One of the following status strings, or `nil` if no media content is currently loaded:
///    * "unknown"     - The content's status is unknown; often this is returned when remote content is still loading or being evaluated for playback.
///    * "readyToPlay" - The content has been loaded or sufficiently buffered so that playback may begin
///    * "failed"      - There was an error loading the content; a second return value will contain a string which may contain more information about the error.
static int avplayer_status(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;
    int              returnCount = 1 ;

    if (playerItem) {
        switch(playerItem.status) {
            case AVPlayerStatusUnknown:
                lua_pushstring(L, "unknown") ;
                break ;
            case AVPlayerStatusReadyToPlay:
                lua_pushstring(L, "readyToPlay") ;
                break ;
            case AVPlayerStatusFailed:
                lua_pushstring(L, "failed") ;
                [skin pushNSObject:[playerItem.error localizedDescription]] ;
                returnCount++ ;
                break ;
            default:
                lua_pushstring(L, [[NSString stringWithFormat:@"unrecognized status:%ld", playerItem.status] UTF8String]) ;
                break ;
        }
    } else {
        lua_pushnil(L) ;
    }
    return returnCount ;
}


/// hs._asm.guitk.element.avplayer:trackCompleted([state]) -> avplayerObject | boolean
/// Method
/// Enable or disable a callback whenever playback of the current media content is completed (reaches the end).
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not completing the playback of media should invoke a callback.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 2 arguments:
///    * the avplayerObject
///    * "finished"
static int avplayer_trackCompleted(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.trackCompleted) ;
    } else {
        if (playerItem && playerView.trackCompleted) {
            [[NSNotificationCenter defaultCenter] removeObserver:playerView
                                                            name:AVPlayerItemDidPlayToEndTimeNotification
                                                          object:playerItem] ;
        }

        playerView.trackCompleted = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;

        if (playerItem && playerView.trackCompleted) {
            [[NSNotificationCenter defaultCenter] addObserver:playerView
                                                     selector:@selector(didFinishPlaying:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:playerItem] ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:trackStatus([state]) -> avplayerObject | boolean
/// Method
/// Enable or disable a callback whenever the status of loading a media item changes.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not changes to the status of audiovisual media's loading status should generate a callback..
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 or 4 arguments:
///    * the avplayerObject
///    * "status"
///    * a string matching one of the states described in [hs._asm.guitk.element.avplayer:status](#status)
///    * if the state reported is failed, an error message describing the error that occurred.
static int avplayer_trackStatus(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.trackStatus) ;
    } else {
        if (playerItem && playerView.trackStatus) {
            [playerItem removeObserver:playerView forKeyPath:@"status" context:myKVOContext] ;
        }

        playerView.trackStatus = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;

        if (playerItem && playerView.trackStatus) {
            [playerItem addObserver:playerView
                         forKeyPath:@"status"
                            options:NSKeyValueObservingOptionNew
                            context:myKVOContext] ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:currentTime() -> number | nil
/// Method
/// Returns the current position in seconds within the audiovisual media content.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the current position, in seconds, within the audiovisual media content, or `nil` if no media content is currently loaded.
static int avplayer_currentTime(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;

    if (playerItem) {
        lua_pushnumber(L, CMTimeGetSeconds(playerItem.currentTime)) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:duration() -> number | nil
/// Method
/// Returns the duration, in seconds, of the audiovisual media content currently loaded.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the duration, in seconds, of the audiovisual media content currently loaded, if it can be determined, or `nan` (not-a-number) if it cannot.  If no item has been loaded, this method will return nil.
///
/// Notes:
///  * the duration of an item which is still loading cannot be determined; you may want to use [hs._asm.guitk.element.avplayer:trackStatus](#trackStatus) and wait until it receives a "readyToPlay" state before querying this method.
///
///  * a live stream may not provide duration information and also return `nan` for this method.
///
///  * Lua defines `nan` as a number which is not equal to itself.  To test if the value of this method is `nan` requires code like the following:
///  ~~~lua
///  duration = avplayer:duration()
///  if type(duration) == "number" and duration ~= duration then
///      -- the duration is equal to `nan`
///  end
/// ~~~
static int avplayer_duration(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;

    if (playerItem) {
        lua_pushnumber(L, CMTimeGetSeconds(playerItem.duration)) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:seek(time, [callback]) -> avplayerObject | nil
/// Method
/// Jumps to the specified location in the audiovisual content currently loaded into the player.
///
/// Parameters:
///  * `time`     - the location, in seconds, within the audiovisual content to seek to.
///  * `callback` - an optional boolean, default false, specifying whether or not a callback should be invoked when the seek operation has completed.
///
/// Returns:
///  * the avplayerObject, or nil if no media content is currently loaded
///
/// Notes:
///  * If you specify `callback` as true, the callback function (see [hs._asm.guitk.element.avplayer:setCallback](#setCallback)) will be invoked with the following 3 or 4 arguments:
///    * the avplayerObject
///    * "seek"
///    * the current time, in seconds, specifying the current playback position in the media content
///    * `true` if the seek operation was allowed to complete, or `false` if it was interrupted (for example by another seek request).
static int avplayer_seekToTime(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayerItem     *playerItem = playerView.player.currentItem ;
    lua_Number       desiredPosition = lua_tonumber(L, 2) ;

    if (playerItem) {
        CMTime positionAsCMTime = CMTimeMakeWithSeconds(desiredPosition, PREFERRED_TIMESCALE) ;
        if (lua_gettop(L) == 3 && lua_toboolean(L, 3)) {
            [playerItem seekToTime:positionAsCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                if (playerView.callbackRef != LUA_NOREF) {
                    [skin pushLuaRef:refTable ref:playerView.callbackRef] ;
                    [skin pushNSObject:playerView] ;
                    lua_pushstring(L, "seek") ;
                    lua_pushnumber(L, CMTimeGetSeconds(playerItem.currentTime)) ;
                    lua_pushboolean(L, finished) ;
                    if (![skin protectedCallAndTraceback:4 nresults:0]) {
                        NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
                        lua_pop(L, 1) ;
                        [skin logError:[NSString stringWithFormat:@"%s:seek callback error:%@", USERDATA_TAG, errorMessage]] ;
                    }
                }
            }] ;
        } else {
            [playerItem seekToTime:positionAsCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero] ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods - experimental

/// hs._asm.guitk.element.avplayer:sharingServiceButton([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not the sharing services button is included in the media controls.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the sharing services button is included in the media controls.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.
static int avplayer_showsSharingServiceButton(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.showsSharingServiceButton) ;
    } else {
        playerView.showsSharingServiceButton = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:fullScreenButton([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not the full screen toggle button should be included in the media controls.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the full screen toggle button should be included in the media controls.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.
static int avplayer_showsFullScreenToggleButton(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, playerView.showsFullScreenToggleButton) ;
    } else {
        playerView.showsFullScreenToggleButton = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:allowExternalPlayback([state]) -> avplayerObject | boolean
/// Method
/// Get or set whether or not external playback via AirPlay is allowed for this item.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether external playback via AirPlay is allowed for this item.
///
/// Returns:
///  * if an argument is provided, the avplayerObject; otherwise the current value.
///
/// Notes:
///  * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.
///
///  * External playback via AirPlay is only available in macOS 10.11 and newer.
static int avplayer_allowsExternalPlayback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if (lua_gettop(L) == 1) {
        if ([player respondsToSelector:@selector(allowsExternalPlayback)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            lua_pushboolean(L, player.allowsExternalPlayback) ;
#pragma clang diagnostic pop
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        if ([player respondsToSelector:@selector(setAllowsExternalPlayback:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            player.allowsExternalPlayback = (BOOL)lua_toboolean(L, 2) ;
#pragma clang diagnostic pop
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:external playback only available in 10.11 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.avplayer:externalPlayback() -> Boolean
/// Method
/// Returns whether or not external playback via AirPlay is currently active for the avplayer object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * true, if AirPlay is currently being used to play the audiovisual content, or false if it is not.
///
///
/// Notes:
///  * This method is considered experimental and may or may not function as intended; use with caution and please report any reproducible errors or crashes that you encounter.
///
///  * External playback via AirPlay is only available in macOS 10.11 and newer.
static int avplayer_externalPlaybackActive(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementAVPlayer *playerView = [skin toNSObjectAtIndex:1] ;
    AVPlayer         *player = playerView.player ;

    if ([player respondsToSelector:@selector(isExternalPlaybackActive)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        lua_pushboolean(L, player.externalPlaybackActive) ;
#pragma clang diagnostic pop
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementAVPlayer(lua_State *L, id obj) {
    HSASMGUITKElementAVPlayer *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementAVPlayer *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementAVPlayerFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementAVPlayer *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementAVPlayer, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementAVPlayer *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementAVPlayer"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementAVPlayer *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementAVPlayer"] ;
        HSASMGUITKElementAVPlayer *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementAVPlayer"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementAVPlayer *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementAVPlayer, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef = [skin luaUnref:refTable ref:obj.callbackRef] ;
            if (obj.periodicObserver) {
                [obj.player removeTimeObserver:obj.periodicObserver] ;
                obj.periodicObserver = nil ;
                obj.periodicPeriod = 0.0 ;
            }

            if (obj.player.currentItem) {
                if (obj.trackCompleted) {
                    [[NSNotificationCenter defaultCenter] removeObserver:obj
                                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                                  object:obj.player.currentItem] ;
                }
                if (obj.trackStatus) {
                    [obj.player.currentItem removeObserver:obj forKeyPath:@"status" context:myKVOContext] ;
                }
            }
            if (obj.trackRate) {
                [obj.player removeObserver:obj forKeyPath:@"rate" context:myKVOContext] ;
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
    {"controlsStyle",          avplayer_controlsStyle},
    {"frameSteppingButtons",   avplayer_showsFrameSteppingButtons},
    {"sharingServiceButton",   avplayer_showsSharingServiceButton},
    {"flashChapterAndTitle",   avplayer_flashChapterAndTitle},
    {"pauseWhenHidden",        avplayer_pauseWhenHidden},
    {"callback",               avplayer_callback},
//     {"actionMenu",             avplayer_actionMenu},
    {"load",                   avplayer_load},
    {"play",                   avplayer_play},
    {"pause",                  avplayer_pause},
    {"rate",                   avplayer_rate},
    {"mute",                   avplayer_mute},
    {"volume",                 avplayer_volume},
    {"ccEnabled",              avplayer_closedCaptionDisplayEnabled},
    {"trackProgress",          avplayer_trackProgress},
    {"trackRate",              avplayer_trackRate},
    {"playbackInformation",    avplayer_playbackInformation},
    {"status",                 avplayer_status},
    {"trackCompleted",         avplayer_trackCompleted},
    {"trackStatus",            avplayer_trackStatus},
    {"currentTime",            avplayer_currentTime},
    {"duration",               avplayer_duration},
    {"seekToTime",             avplayer_seekToTime},

// experimental
    {"fullScreenButton",       avplayer_showsFullScreenToggleButton},
    {"allowsExternalPlayback", avplayer_allowsExternalPlayback},
    {"externalPlaybackActive", avplayer_externalPlaybackActive},

    {"__tostring",             userdata_tostring},
    {"__eq",                   userdata_eq},
    {"__gc",                   userdata_gc},
    {NULL,                     NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", avplayer_new},
    {NULL, NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_element_avplayer(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementAVPlayer         forClass:"HSASMGUITKElementAVPlayer"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementAVPlayerFromLua forClass:"HSASMGUITKElementAVPlayer"
                                                          withUserdataMapping:USERDATA_TAG];

    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"controlsStyle",
        @"frameSteppingButtons",
        @"pauseWhenHidden",
        @"rate",
        @"mute",
        @"volume",
        @"ccEnabled",
        @"trackProgress",
        @"trackRate",
        @"trackCompleted",
        @"trackStatus",
        @"callback",
    ]] ;
    if ([AVPlayer instancesRespondToSelector:NSSelectorFromString(@"allowExternalPlayback")]) {
        lua_pushstring(L, "allowExternalPlayback") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    lua_setfield(L, -2, "_propertyList") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
