// TODO:
//   document
//   figure out appropriate callbacks
//   figure out specifics of 10.12 constructors so we can wrap them for < 10.12 (like in button)
//   ?

// #define TEST_FALLBACKS

/// === hs._asm.guitk.element.textfield ===
///
/// Provides text label and input field elements for use with `hs._asm.guitk`.
///
/// * This submodule inherits methods from `hs._asm.guitk.element._control` and you should consult its documentation for additional methods which may be used.
/// * This submodule inherits methods from `hs._asm.guitk.element._view` and you should consult its documentation for additional methods which may be used.

@import Cocoa ;
@import Carbon ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.textfield" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

static NSDictionary *BEZEL_STYLES ;

#pragma mark - Support Functions and Classes

static void defineInternalDictionaryies() {
    BEZEL_STYLES  = @{
        @"square"  : @(NSTextFieldSquareBezel),
        @"rounded" : @(NSTextFieldRoundedBezel),
    } ;
}

@interface HSASMGUITKElementTextField : NSTextField <NSTextFieldDelegate>
@property int callbackRef ;
@property int editingCallbackRef ;
@property int selfRefCount ;
@end

@implementation HSASMGUITKElementTextField

- (instancetype)initWithFrame:(NSRect)frameRect {
    @try {
        self = [super initWithFrame:frameRect] ;
    }
    @catch (NSException *exception) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:new - %@", USERDATA_TAG, exception.reason]] ;
        self = nil ;
    }

    if (self) {
        _selfRefCount       = 0 ;
        _callbackRef        = LUA_NOREF ;
        _editingCallbackRef = LUA_NOREF ;
        self.delegate       = self ;
//         self.target         = self ;
//         self.action         = @selector(targetAction:) ;
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

// - (BOOL)becomeFirstResponder {
//     [self callbackHamster:@[ self, @"didBeginEditing" ]] ;
//     return [super becomeFirstResponder] ;
// }
//
// - (BOOL)resignFirstResponder {
//     [self callbackHamster:@[ self, @"didEndEditing", self.stringValue ]] ;
//     return [super resignFirstResponder] ;
// }

- (BOOL)performEditingCallback:(id)message withDefault:(BOOL)defaultResult {
    BOOL result = defaultResult ;

    if (_editingCallbackRef != LUA_NOREF) {
        NSArray *arguments = @[] ;
        if (message) {
            if ([message isKindOfClass:[NSArray class]]) {
                arguments = message ;
            } else {
                arguments = @[ message ] ;
            }
        }
        LuaSkin   *skin = [LuaSkin shared] ;
        lua_State *L    = skin.L ;
        [skin pushLuaRef:refTable ref:_editingCallbackRef] ;
        [skin pushNSObject:self] ;
        int argumentCount = 2 ; // self + the boolean that will follow the other arguments
        for (id object in arguments) [skin pushNSObject:object] ;
        argumentCount += arguments.count ;
        lua_pushboolean(L, defaultResult) ;
        if ([skin protectedCallAndTraceback:argumentCount nresults:1]) {
            if (lua_type(L, -1) != LUA_TNIL) result = (BOOL)lua_toboolean(L, -1) ;
        } else {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            [skin logError:[NSString stringWithFormat:@"%s:editingCallback(%@) error:%@", USERDATA_TAG, message, errorMessage]] ;
        }
        lua_pop(L, 1) ;
    }
    return result ;

}

- (BOOL)textShouldBeginEditing:(NSText *)textObject {
    return [self performEditingCallback:@"shouldBeginEditing" withDefault:[super textShouldBeginEditing:textObject]] ;
}

- (BOOL)textShouldEndEditing:(NSText *)textObject {
    return [self performEditingCallback:@"shouldEndEditing" withDefault:[super textShouldEndEditing:textObject]] ;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    unsigned short       keyCode       = event.keyCode ;
//     NSEventModifierFlags modifierFlags = event.modifierFlags & NSDeviceIndependentModifierFlagsMask ;
//     [LuaSkin logWarn:[NSString stringWithFormat:@"%s:performKeyEquivalent - key:%3d, mods:0x%08lx %@", USERDATA_TAG, keyCode, (unsigned long)modifierFlags, event]] ;

    if ((keyCode == kVK_Return)     && [self performEditingCallback:@[ @"keyPress", @"return" ] withDefault:NO]) return YES ;
    if ((keyCode == kVK_LeftArrow)  && [self performEditingCallback:@[ @"keyPress", @"left"   ] withDefault:NO]) return YES ;
    if ((keyCode == kVK_RightArrow) && [self performEditingCallback:@[ @"keyPress", @"right"  ] withDefault:NO]) return YES ;
    if ((keyCode == kVK_DownArrow)  && [self performEditingCallback:@[ @"keyPress", @"down"   ] withDefault:NO]) return YES ;
    if ((keyCode == kVK_UpArrow)    && [self performEditingCallback:@[ @"keyPress", @"up"     ] withDefault:NO]) return YES ;

    return [super performKeyEquivalent:event] ;
}

- (void)cancelOperation:(__unused id)sender {
    // calling super with this crashes, so return value doesn't really matter unless we decide to implement something here...
    // I considered allowing escape to "undo" the types input, but realized this can just as easily be done by the lua callback
    // so not sure what else we might add here.
    [self performEditingCallback:@[ @"keyPress", @"escape" ] withDefault:NO] ;
}

- (void)controlTextDidBeginEditing:(__unused NSNotification *)aNotification {
//     [LuaSkin logWarn:[NSString stringWithFormat:@"%s:controlTextDidBeginEditing - %@", USERDATA_TAG, aNotification]] ;
    [self callbackHamster:@[ self, @"didBeginEditing"]] ;
}

- (void)controlTextDidChange:(__unused NSNotification *)aNotification {
//     [LuaSkin logWarn:[NSString stringWithFormat:@"%s:controlTextDidChange - %@", USERDATA_TAG, aNotification]] ;
    if (self.continuous) [self callbackHamster:@[ self, @"textDidChange", self.stringValue]] ;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
//     [LuaSkin logWarn:[NSString stringWithFormat:@"%s:controlTextDidEndEditing - %@", USERDATA_TAG, aNotification]] ;
    NSNumber   *reasonCodeNumber = aNotification.userInfo[@"NSTextMovement"] ;
    NSUInteger reasonCode        = reasonCodeNumber ? reasonCodeNumber.unsignedIntValue : NSOtherTextMovement ;
    NSString   *reason           = [NSString stringWithFormat:@"unknown reasonCode:%lu", reasonCode] ;
    if (reasonCode == NSOtherTextMovement)   reason = @"other" ; // also NSIllegalTextMovement which is marked as currently unused
    if (reasonCode == NSTabTextMovement)     reason = @"tab" ;
    if (reasonCode == NSBacktabTextMovement) reason = @"shiftTab" ;
// not sure if these are valid movement codes for textfield; haven't found a way to make them do anything yet
    if (reasonCode == NSReturnTextMovement)  reason = @"return" ;
    if (reasonCode == NSCancelTextMovement)  reason = @"cancel" ;
    if (reasonCode == NSLeftTextMovement)    reason = @"left" ;
    if (reasonCode == NSRightTextMovement)   reason = @"right" ;
    if (reasonCode == NSUpTextMovement)      reason = @"up" ;
    if (reasonCode == NSDownTextMovement)    reason = @"down" ;
    [self callbackHamster:@[ self, @"didEndEditing", self.stringValue, reason]] ;
}

@end

#pragma mark - Module Functions

/// hs._asm.guitk.element.textfield.new([frame]) -> textfieldObject
/// Constructor
/// Creates a new textfield element for `hs._asm.guitk`.
///
/// Parameters:
///  * `frame` - an optional frame table specifying the position and size of the frame for the element.
///
/// Returns:
///  * the textfieldObject
///
/// Notes:
///  * In most cases, setting the frame is not necessary and will be overridden when the element is assigned to a manager or to a `hs._asm.guitk` window.
///
///  * The textfield element does not have a default width unless you assign a value to it with [hs._asm.guitk.element.textfield:value](#value); if you are assigning an empty textfield element to an `hs._asm.guitk.manager`, be sure to specify a width in the frame details or the element may not be visible.
static int textfield_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSRect frameRect = (lua_gettop(L) == 1) ? [skin tableToRectAtIndex:1] : NSZeroRect ;
    HSASMGUITKElementTextField *textfield = [[HSASMGUITKElementTextField alloc] initWithFrame:frameRect] ;
    if (textfield) {
        if (lua_gettop(L) != 1) [textfield setFrameSize:[textfield fittingSize]] ;
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield.newLabel(text) -> textfieldObject
/// Constructor
/// Creates a new textfield element usable as a label for `hs._asm.guitk`.
///
/// Parameters:
///  * `text` - a string or `hs.styledtext` object specifying the text to assign to the label.
///
/// Returns:
///  * the textfieldObject
///
/// Notes:
///  * This constructor creates a non-editable, non-selectable text field, often used as a label for another element.
///    * If you specify `text` as a string, the label is non-wrapping and appears in the default system font.
///    * If you specify `text` as an `hs.styledtext` object, the line break mode and font are determined by the style attributes of the object.
static int textfield_newLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield ;
    if (lua_type(L, 1) == LUA_TUSERDATA) {
        [skin checkArgs:LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
        NSAttributedString *labelValue = [skin toNSObjectAtIndex:1] ;
#ifndef TEST_FALLBACKS
        if ([NSTextField respondsToSelector:NSSelectorFromString(@"labelWithAttributedString:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            textfield = [HSASMGUITKElementTextField labelWithAttributedString:labelValue] ;
#pragma clang diagnostic pop
        } else {
#endif
            NSDictionary     *attributes = [labelValue attributesAtIndex:0 effectiveRange:NULL] ;
            NSParagraphStyle *style      = attributes[NSParagraphStyleAttributeName] ;
            if (!style) style = [NSParagraphStyle defaultParagraphStyle] ;

            textfield = [[HSASMGUITKElementTextField alloc] initWithFrame:NSZeroRect] ;
            textfield.attributedStringValue = labelValue ;
            textfield.bezeled               = NO ;
            textfield.drawsBackground       = NO ;
            textfield.editable              = NO ;
            textfield.lineBreakMode         = style.lineBreakMode ;
            textfield.selectable            = NO ;
            textfield.alignment             = NSTextAlignmentNatural ;
            textfield.font                  = [NSFont systemFontOfSize:0] ;
            textfield.textColor             = [NSColor labelColor] ;
#ifndef TEST_FALLBACKS
    }
#endif
    } else {
        [skin checkArgs:LS_TSTRING, LS_TBREAK] ;
        NSString *labelValue = [skin toNSObjectAtIndex:1] ;
#ifndef TEST_FALLBACKS
        if ([NSTextField respondsToSelector:NSSelectorFromString(@"labelWithString:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            textfield = [HSASMGUITKElementTextField labelWithString:labelValue] ;
#pragma clang diagnostic pop
        } else {
#endif
            textfield = [[HSASMGUITKElementTextField alloc] initWithFrame:NSZeroRect] ;
            textfield.stringValue     = labelValue ;
            textfield.bezeled         = NO ;
            textfield.drawsBackground = NO ;
            textfield.editable        = NO ;
            textfield.lineBreakMode   = NSLineBreakByClipping ;
            textfield.selectable      = NO ;
            textfield.alignment       = NSTextAlignmentNatural ;
            textfield.font            = [NSFont systemFontOfSize:0] ;
            textfield.textColor       = [NSColor labelColor] ;
        }
#ifndef TEST_FALLBACKS
    }
#endif
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield.newTextField([text]) -> textfieldObject
/// Constructor
/// Creates a new editable textfield element for `hs._asm.guitk`.
///
/// Parameters:
///  * `text` - an optional string specifying the text to assign to the text field.
///
/// Returns:
///  * the textfieldObject
///
/// Notes:
///  * This constructor creates a non-wrapping, editable text field, suitable for accepting user input.
static int textfield_newTextField(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield ;
    NSString *fieldValue = (lua_gettop(L) == 1) ? [skin toNSObjectAtIndex:1] : nil ;
#ifndef TEST_FALLBACKS
    if ([NSTextField respondsToSelector:NSSelectorFromString(@"textFieldWithString:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        textfield = [HSASMGUITKElementTextField textFieldWithString:fieldValue] ;
#pragma clang diagnostic pop
    } else {
#endif
        textfield = [[HSASMGUITKElementTextField alloc] initWithFrame:NSZeroRect] ;
        textfield.stringValue     = fieldValue ;
        textfield.bezeled         = YES ;
        textfield.drawsBackground = YES ;
        textfield.editable        = YES ;
        textfield.lineBreakMode   = NSLineBreakByClipping ;
        textfield.selectable      = YES ;
        textfield.alignment       = NSTextAlignmentNatural ;
        textfield.font            = [NSFont systemFontOfSize:0] ;
        textfield.textColor       = [NSColor textColor] ;
#ifndef TEST_FALLBACKS
    }
#endif
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield.newWrappingLabel(text) -> textfieldObject
/// Constructor
/// Creates a new textfield element usable as a label for `hs._asm.guitk`.
///
/// Parameters:
///  * `text` - a string specifying the text to assign to the label.
///
/// Returns:
///  * the textfieldObject
///
/// Notes:
///  * This constructor creates a wrapping, selectable, non-editable text field, that is suitable for use as a label or informative text. The text defaults to the system font.
static int textfield_newWrappingLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield ;
    NSString *labelValue = [skin toNSObjectAtIndex:1] ;
#ifndef TEST_FALLBACKS
    if ([NSTextField respondsToSelector:NSSelectorFromString(@"wrappingLabelWithString:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        textfield = [HSASMGUITKElementTextField wrappingLabelWithString:labelValue] ;
#pragma clang diagnostic pop
    } else {
#endif
        textfield = [[HSASMGUITKElementTextField alloc] initWithFrame:NSZeroRect] ;
        textfield.stringValue     = labelValue ;
        textfield.bezeled         = NO ;
        textfield.drawsBackground = NO ;
        textfield.editable        = NO ;
        textfield.lineBreakMode   = NSLineBreakByWordWrapping ;
        textfield.selectable      = YES ;
        textfield.alignment       = NSTextAlignmentNatural ;
        textfield.font            = [NSFont systemFontOfSize:0] ;
        textfield.textColor       = [NSColor labelColor] ;
#ifndef TEST_FALLBACKS
    }
#endif
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.guitk.element.textfield:callback([fn | nil]) -> textfieldObject | fn | nil
/// Method
/// Get or set the callback function which will be invoked whenever the user interacts with the textfield element.
///
/// Parameters:
///  * `fn` - a lua function, or explicit nil to remove, which will be invoked when the user interacts with the textfield
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * The callback function should expect arguments as described below and return none:
///    * When the user starts typing in the text field, the callback will receive the following arguments:
///      * the textfield userdata object
///      * the message string "didBeginEditing" indicating that the user has started editing the textfield element
///    * When the focus leaves the text field element, the callback will receive the following arguments (note that it is possible to receive this callback without a corresponding "didBeginEditing" callback if the user makes no changes to the textfield):
///      * the textfield userdata object
///      * the message string "didEndEditing" indicating that the textfield element is no longer active
///      * the current string value of the textfield -- see [hs._asm.guitk.element.textfield:value](#value)
///      * a string specifying why editing terminated:
///        * "other"    - another element has taken focus or the user has clicked outside of the text field
///        * "return"   - the user has hit the enter or return key. Note that this does not take focus away from the textfield by default so if the user types again, another "didBeginEditing" callback for the textfield will be generated.
///        * "tab"      - the user used the tab key to move to the next textfield element
///        * "shiftTab" - the user user the tab key with the shift modifier to move to the previous textfield element
///        * the specification allows for other possible reasons for ending the editing of a textfield, but so far it is not known how to enable these and they may apply to other text based elements which have not yet been implemented.  These are "cancel", "left", "right", "up", and "down". If you do see one of these reasons in your use of the textfield element, please submit an issue with sample code so it can be determined how to properly document this.
///    * If the `hs._asm.guitk.element._control:continuous` is set to true for the textfield element, a callback with the following arguments will occur each time the user presses a key:
///      * the textfield userdata object
///      * the string "textDidChange" indicating that the user has typed or deleted something in the textfield
///      * the current string value of the textfield -- see [hs._asm.guitk.element.textfield:value](#value)
static int textfield_callback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        textfield.callbackRef = [skin luaUnref:refTable ref:textfield.callbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            textfield.callbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (textfield.callbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:textfield.callbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:editingCallback([fn | nil]) -> textfieldObject | fn | nil
/// Method
/// Get or set the callback function which will is invoked to make editing decisions about the textfield
///
/// Parameters:
///  * `fn` - a lua function, or explicit nil to remove, which will be invoked to make editing decisions about the textfield
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * The callback function should expect multiple arguments and return a boolean as described below (a return value of none or nil will use the default as specified for each callback below):
///    * When the user attempts to edit the textfield, the callback will be invoked with the following arguments and the boolean return value should indicate whether editing is to be allowed:
///      * the textfield userdata object
///      * the string "shouldBeginEditing" indicating that the callback is asking permission to allow editing of the textfield at this time
///      * the default return value as determined by the current state of the the textfield and its location in the window/view hierarchy (usually this will be true)
///    * When the user attempts to finish editing the textfield, the callback will be invoked with the following arguments and the boolean return value should indicate whether focus is allowed to leave the textfield:
///      * the textfield userdata object
///      * the string "shouldEndEditing" indicating that the callback is asking permission to complete editing of the textfield at this time
///      * the default return value as determined by the current state of the the textfield and its location in the window/view hierarchy (usually this will be true)
///    * When the return (or enter) key or escape key are pressed, the callback will be invoked with the following arguments and the return value should indicate whether or not the keypress was handled by the callback or should be passed further up the window/view hierarchy:
///      * the textfield userdata object
///      * the string "keyPress"
///      * the string "return" or "escape"
///      * the default return value of false indicating that the callback is not interested in this keypress.
///    * Note that the return value is currently ignored when the key pressed is "escape".
///    * Note that the specification allows for the additional keys "left", "right", "up", and "down" to trigger this callback, but at present it is not known how to enable this for a textfield element. It is surmised that they may be applicable to text based elements that are not currently supported by `hs._asm.guitk`. If you do manage to receive a callback for one of these keys, please submit an issue with sample code so we can determine how to properly document them.
static int textfield_editingCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TFUNCTION | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        textfield.editingCallbackRef = [skin luaUnref:refTable ref:textfield.editingCallbackRef] ;
        if (lua_type(L, 2) != LUA_TNIL) {
            lua_pushvalue(L, 2) ;
            textfield.editingCallbackRef = [skin luaRef:refTable] ;
            lua_pushvalue(L, 1) ;
        }
    } else {
        if (textfield.editingCallbackRef != LUA_NOREF) {
            [skin pushLuaRef:refTable ref:textfield.editingCallbackRef] ;
        } else {
            lua_pushnil(L) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:selectAll() -> textfieldObject
/// Method
/// Selects the text of a selectable or editable textfield and makes it the active element in the window.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the textfieldObject
///
/// Notes:
///  * This method has no effect if the textfield is not editable or selectable.  Use `hs._asm.guitk:activeElement` if you wish to remove the focus from any textfield that is currently selected.
static int textfield_selectText(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    [textfield selectText:nil] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.guitk.element.textfield:styleEditable([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the style (font, color, etc.) of the text in an editable textfield can be changed by the user
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether or not the style of the text can be edited in the textfield
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * If the style of a textfield element can be edited, the user will be able to access the font and color panels by right-clicking in the text field and selecting the Font submenu from the menu that is shown.
static int textfield_allowsEditingTextAttributes(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.allowsEditingTextAttributes) ;
    } else {
        textfield.allowsEditingTextAttributes = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:drawsBackground([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the background of the textfield is shown
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the background of the textfield is shown (true) or transparent (false). Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
static int textfield_drawsBackground(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.drawsBackground) ;
    } else {
        textfield.drawsBackground = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:importsGraphics([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether an editable textfield whose style is editable allows image files to be dragged into it
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether the textfield allows image files to be dragged into it
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * [hs._asm.guitk.element.textfield:styleEditable](#styleEditable) must also be true for this method to have any effect.
static int textfield_importsGraphics(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.importsGraphics) ;
    } else {
        textfield.importsGraphics = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:preferredMaxWidth([width]) -> textfieldObject | number
/// Method
/// Get or set the preferred layout width for the textfield
///
/// Parameters:
///  * `width` - an optional number, default 0.0, specifying the preferred width of the textfield
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
static int textfield_preferredMaxLayoutWidth(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, textfield.preferredMaxLayoutWidth) ;
    } else {
        textfield.preferredMaxLayoutWidth = lua_tonumber(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:bezelStyle([style]) -> textfieldObject | string
/// Method
/// Get or set whether the corners of a bezeled textfield are rounded or square
///
/// Parameters:
///  * `style` - an optional string, default "square", specifying whether the corners of a bezeled textfield are rounded or square. Must be one of "square" or "round".
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * only has an effect if [hs._asm.guitk.element.textfield:bezeled](#bezeled) is true.
static int textfield_bezelStyle(lua_State *L) {    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSNumber *bezelStyle = @(textfield.bezelStyle) ;
        NSArray *temp = [BEZEL_STYLES allKeysForObject:bezelStyle];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized bezel style %@ -- notify developers", USERDATA_TAG, bezelStyle]] ;
            lua_pushnil(L) ;
        }
    } else {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *bezelStyle = BEZEL_STYLES[key] ;
        if (bezelStyle) {
            textfield.bezelStyle = [bezelStyle unsignedIntegerValue] ;
            lua_pushvalue(L, 1) ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[BEZEL_STYLES allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:backgroundColor([color]) -> textfieldObject | color table
/// Method
/// Get or set the color for the background of the textfield element.
///
/// Parameters:
/// * `color` - an optional table containing color keys as described in `hs.drawing.color`
///
/// Returns:
///  * If an argument is provided, the textfieldObject; otherwise the current value.
///
/// Notes:
///  * The background color will only be drawn when [hs._asm.guitk.element.textfield:drawsBackground](#drawsBackground) is true.
static int textfield_backgroundColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:textfield.backgroundColor] ;
    } else {
        textfield.backgroundColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:textColor([color]) -> textfieldObject | color table
/// Method
/// Get or set the color for the the text in a textfield element.
///
/// Parameters:
/// * `color` - an optional table containing color keys as described in `hs.drawing.color`
///
/// Returns:
///  * If an argument is provided, the textfieldObject; otherwise the current value.
///
/// Notes:
///  * Has no effect on portions of an `hs.styledtext` value that specifies the text color for the object
static int textfield_textColor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:textfield.textColor] ;
    } else {
        textfield.textColor = [skin luaObjectAtIndex:2 toClass:"NSColor"] ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}


/// hs._asm.guitk.element.textfield:placeholderString([placeholder]) -> textfieldObject | string
/// Method
/// Get or set the placeholder string for the textfield.
///
/// Parameters:
/// * `placeholder` - an optional string or `hs.styledtext` object, or an explicit nil to remove, specifying the placeholder string for a textfield. The place holder string is displayed in a light color when the contents of the textfield is empty (i.e. is set to nil or the empty string "")
///
/// Returns:
///  * If an argument is provided, the textfieldObject; otherwise the current value.
static int textfield_placeholderString(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSString *placeholderString = ((NSTextFieldCell *)textfield.cell).placeholderString ;
        [skin pushNSObject:(placeholderString ? placeholderString : ((NSTextFieldCell *)textfield.cell).placeholderAttributedString)] ;
    } else {
        if (lua_type(L, 2) == LUA_TUSERDATA) {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
            ((NSTextFieldCell *)textfield.cell).placeholderAttributedString = [skin toNSObjectAtIndex:2] ;
        } else if (lua_type(L, 2) == LUA_TNIL) {
            ((NSTextFieldCell *)textfield.cell).placeholderAttributedString = nil ;
            ((NSTextFieldCell *)textfield.cell).placeholderString = nil ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
            ((NSTextFieldCell *)textfield.cell).placeholderString = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:bezeled([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the textfield draws a bezeled border around its contents.
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the textfield draws a bezeled border around its contents. Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * If you set this to true, [hs._asm.guitk.element.textfield:bordered](#bordered) is set to false.
static int textfield_bezeled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.bezeled) ;
    } else {
        textfield.bezeled = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:bordered([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the textfield draws a black border around its contents.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether the textfield draws a black border around its contents.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * If you set this to true, [hs._asm.guitk.element.textfield:bezeled](#bezeled) is set to false.
static int textfield_bordered(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.bordered) ;
    } else {
        textfield.bordered = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:expandIntoTooltip([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the textfield contents will be expanded into a tooltip if the contents are longer than the textfield is wide and the mouse pointer hovers over the textfield.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether the textfield contents will be expanded into a tooltip if the contents are longer than the textfield is wide.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * If a tooltip is set with `hs._asm.guitk.element._control:tooltip` then this method has no effect.
static int textfield_allowsExpansionToolTips(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.allowsExpansionToolTips) ;
    } else {
        textfield.allowsExpansionToolTips = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:editable([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the textfield is editable.
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the textfield contents are editable. Defaults to `true` for editable textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField), otherwise false.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * Setting this to true automatically sets [hs._asm.guitk.element.textfield:selectable](#selectable) to true.
static int textfield_editable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.editable) ;
    } else {
        textfield.editable = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:selectable([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the contents of the textfield is selectable.
///
/// Parameters:
///  * `state` - an optional boolean specifying whether the textfield contents are selectable. Defaults to `true` for textfields created with [hs._asm.guitk.element.textfield.newTextField](#newTextField) or [hs._asm.guitk.element.textfield.newWrappingLabel](#newWrappingLabel), otherwise false.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * Setting this to false automatically sets [hs._asm.guitk.element.textfield:editable](#editable) to false.
static int textfield_selectable(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.selectable) ;
    } else {
        textfield.selectable = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:value([value] | [type]) -> textfieldObject | string | styledtextObject
/// Method
/// Get or set the contents of the textfield.
///
/// Parameters:
///  * to set the textfield content:
///    * `value` - an optional string or `hs.styledtext` object specifying the contents to display in the textfield
///  * to get the current content of the textfield:
///    * `type`  - an optional boolean specifying if the value retrieved should be as an `hs.styledtext` object (true) or a string (false). If no argument is provided, the value returned will be whatever type was last assigned to the textfield with this method or its constructor.
///
/// Returns:
///  * If a string or `hs.styledtext` object is assigned with this method, returns the textfieldObject; otherwise returns the value in the type requested or most recently assigned.
///
/// Notes:
///  * If no argument is provided and [hs._asm.guitk.element.textfield:styleEditable](#styleEditable) is true, if the style has been modified by the user an `hs.styledtext` object will be returned even if the most recent assignment was with a string value.
static int textfield_stringValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    BOOL getAttributed = NO ;
    BOOL booleanPresent = NO ;
    if (lua_type(L, -1) == LUA_TBOOLEAN) {
        getAttributed = (BOOL)lua_toboolean(L, -1) ;
        booleanPresent = YES ;
        lua_pop(L, 1) ;
    }
    if (lua_gettop(L) == 1) {
        if (booleanPresent) {
            [skin pushNSObject:getAttributed ? textfield.attributedStringValue : textfield.stringValue] ;
        } else {
            [skin pushNSObject:textfield.objectValue] ;
        }
    } else {
        if (lua_type(L, 2) == LUA_TUSERDATA) {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
            textfield.attributedStringValue = [skin toNSObjectAtIndex:2] ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
            textfield.stringValue = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:allowsCharacterPicker([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the textfield allows the use of the touchbar character picker when the textfield is editable and is being edited.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether the textfield allows the use of the touchbar character picker when the textfield is editable and is being edited.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * This method is only available in macOS 10.12.1 and newer
static int textfield_allowsCharacterPickerTouchBarItem(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if ([textfield respondsToSelector:NSSelectorFromString(@"allowsCharacterPickerTouchBarItem")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            lua_pushboolean(L, textfield.allowsCharacterPickerTouchBarItem) ;
#pragma clang diagnostic pop
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        if ([textfield respondsToSelector:NSSelectorFromString(@"setAllowsCharacterPickerTouchBarItem:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            textfield.allowsCharacterPickerTouchBarItem = (BOOL)lua_toboolean(L, 2) ;
#pragma clang diagnostic pop
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:allowsCharacterPicker only available in 10.12.2 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:tighteningForTruncation([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether the system may tighten inter-character spacing in the text field before truncating text.
///
/// Parameters:
///  * `state` - an optional boolean, default false, specifying whether the system may tighten inter-character spacing in the text field before truncating text. Has no effect when the textfield is assigned an `hs.styledtext` object.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * This method is only available in macOS 10.11 and newer
static int textfield_allowsDefaultTighteningForTruncation(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if ([textfield respondsToSelector:NSSelectorFromString(@"allowsDefaultTighteningForTruncation")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            lua_pushboolean(L, textfield.allowsDefaultTighteningForTruncation) ;
#pragma clang diagnostic pop
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        if ([textfield respondsToSelector:NSSelectorFromString(@"setAllowsDefaultTighteningForTruncation:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        textfield.allowsDefaultTighteningForTruncation = (BOOL)lua_toboolean(L, 2) ;
#pragma clang diagnostic pop
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:tighteningForTruncation only available in 10.11 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:maximumNumberOfLines([lines]) -> textfieldObject | integer
/// Method
/// Get or set the maximum number of lines that can be displayed in the textfield.
///
/// Parameters:
///  * `lines` - an optional integer, default 0, specifying the maximum number of lines that can be displayed in the textfield. A value of 0 indicates that there is no limit.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * This method is only available in macOS 10.11 and newer
///  * If the text reaches the number of lines allowed, or the height of the container cannot accommodate the number of lines needed, the text will be clipped or truncated.
///    * Affects the default fitting size when the textfield is assigned to an `hs._asm.guitk.manager` object if the textfield element's height and width are not specified when assigned.
static int textfield_maximumNumberOfLines(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if ([textfield respondsToSelector:NSSelectorFromString(@"maximumNumberOfLines")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            lua_pushinteger(L, textfield.maximumNumberOfLines) ;
#pragma clang diagnostic pop
        } else {
            lua_pushinteger(L, -1) ;
        }
    } else {
        if ([textfield respondsToSelector:NSSelectorFromString(@"setMaximumNumberOfLines:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            textfield.maximumNumberOfLines = lua_tointeger(L, 2) ;
#pragma clang diagnostic pop
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:maximumNumberOfLines only available in 10.11 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.guitk.element.textfield:automaticTextCompletion([state]) -> textfieldObject | boolean
/// Method
/// Get or set whether automatic text completion is enabled when the textfield is being edited.
///
/// Parameters:
///  * `state` - an optional boolean, default true, specifying whether automatic text completion is enabled when the textfield is being edited.
///
/// Returns:
///  * if a value is provided, returns the textfieldObject ; otherwise returns the current value.
///
/// Notes:
///  * This method is only available in macOS 10.12.2 and newer
static int textfield_automaticTextCompletionEnabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if ([textfield respondsToSelector:NSSelectorFromString(@"isAutomaticTextCompletionEnabled")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            lua_pushboolean(L, textfield.automaticTextCompletionEnabled) ;
#pragma clang diagnostic pop
        } else {
            lua_pushboolean(L, NO) ;
        }
    } else {
        if ([textfield respondsToSelector:NSSelectorFromString(@"setAutomaticTextCompletionEnabled:")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
            textfield.automaticTextCompletionEnabled = (BOOL)lua_toboolean(L, 2) ;
#pragma clang diagnostic pop
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:automaticTextCompletion only available in 10.12.2 and newer", USERDATA_TAG]] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

#pragma mark - Module Constants

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushHSASMGUITKElementTextField(lua_State *L, id obj) {
    HSASMGUITKElementTextField *value = obj;
    value.selfRefCount++ ;
    void** valuePtr = lua_newuserdata(L, sizeof(HSASMGUITKElementTextField *));
    *valuePtr = (__bridge_retained void *)value;
    luaL_getmetatable(L, USERDATA_TAG);
    lua_setmetatable(L, -2);
    return 1;
}

id toHSASMGUITKElementTextFieldFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementTextField *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge HSASMGUITKElementTextField, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    HSASMGUITKElementTextField *obj = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementTextField"] ;
    NSString *title = NSStringFromRect(obj.frame) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        HSASMGUITKElementTextField *obj1 = [skin luaObjectAtIndex:1 toClass:"HSASMGUITKElementTextField"] ;
        HSASMGUITKElementTextField *obj2 = [skin luaObjectAtIndex:2 toClass:"HSASMGUITKElementTextField"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    HSASMGUITKElementTextField *obj = get_objectFromUserdata(__bridge_transfer HSASMGUITKElementTextField, L, 1, USERDATA_TAG) ;
    if (obj) {
        obj.selfRefCount-- ;
        if (obj.selfRefCount == 0) {
            LuaSkin *skin = [LuaSkin shared] ;
            obj.callbackRef        = [skin luaUnref:refTable ref:obj.callbackRef] ;
            obj.editingCallbackRef = [skin luaUnref:refTable ref:obj.editingCallbackRef] ;

            obj.delegate = nil ;
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
    {"styleEditable",           textfield_allowsEditingTextAttributes},
    {"drawsBackground",         textfield_drawsBackground},
    {"importsGraphics",         textfield_importsGraphics},
    {"preferredMaxWidth",       textfield_preferredMaxLayoutWidth},
    {"bezelStyle",              textfield_bezelStyle},
    {"backgroundColor",         textfield_backgroundColor},
    {"textColor",               textfield_textColor},
    {"placeholderString",       textfield_placeholderString},
    {"bezeled",                 textfield_bezeled},
    {"bordered",                textfield_bordered},
    {"editable",                textfield_editable},
    {"selectable",              textfield_selectable},
    {"value",                   textfield_stringValue},
    {"selectAll",               textfield_selectText},
    {"callback",                textfield_callback},
    {"editingCallback",         textfield_editingCallback},
    {"expandIntoTooltip",       textfield_allowsExpansionToolTips},

    {"allowsCharacterPicker",   textfield_allowsCharacterPickerTouchBarItem},
    {"tighteningForTruncation", textfield_allowsDefaultTighteningForTruncation},
    {"maximumNumberOfLines",    textfield_maximumNumberOfLines},
    {"automaticTextCompletion", textfield_automaticTextCompletionEnabled},

    {"__tostring",              userdata_tostring},
    {"__eq",                    userdata_eq},
    {"__gc",                    userdata_gc},
    {NULL,                      NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",              textfield_new},
    {"newLabel",         textfield_newLabel},
    {"newTextField",     textfield_newTextField},
    {"newWrappingLabel", textfield_newWrappingLabel},
    {NULL,               NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_guitk_element_textfield(lua_State* L) {
    defineInternalDictionaryies() ;

    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    [skin registerPushNSHelper:pushHSASMGUITKElementTextField         forClass:"HSASMGUITKElementTextField"];
    [skin registerLuaObjectHelper:toHSASMGUITKElementTextFieldFromLua forClass:"HSASMGUITKElementTextField"
                                             withUserdataMapping:USERDATA_TAG];

    // allow hs._asm.guitk.manager:elementProperties to get/set these
    luaL_getmetatable(L, USERDATA_TAG) ;
    [skin pushNSObject:@[
        @"styleEditable",
        @"drawsBackground",
        @"importsGraphics",
        @"preferredMaxWidth",
        @"bezelStyle",
        @"backgroundColor",
        @"textColor",
        @"placeholderString",
        @"bezeled",
        @"bordered",
        @"editable",
        @"selectable",
        @"value",
        @"callback",
        @"editingCallback",
        @"expandIntoTooltip",
    ]] ;
    if ([NSTextField instancesRespondToSelector:NSSelectorFromString(@"allowsCharacterPickerTouchBarItem")]) {
        lua_pushstring(L, "allowsCharacterPicker") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    if ([NSTextField instancesRespondToSelector:NSSelectorFromString(@"allowsDefaultTighteningForTruncation")]) {
        lua_pushstring(L, "tighteningForTruncation") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    if ([NSTextField instancesRespondToSelector:NSSelectorFromString(@"maximumNumberOfLines")]) {
        lua_pushstring(L, "maximumNumberOfLines") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    if ([NSTextField instancesRespondToSelector:NSSelectorFromString(@"isAutomaticTextCompletionEnabled")]) {
        lua_pushstring(L, "automaticTextCompletion") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritControl") ;
//     lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
