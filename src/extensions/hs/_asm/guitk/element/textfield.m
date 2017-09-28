// TODO:
//   document
//   figure out appropriate callbacks
//   figure out specifics of 10.12 constructors so we can wrap them for < 10.12 (like in button)
//   ?

@import Cocoa ;
@import Carbon ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.guitk.element.textfield" ;
static int refTable = LUA_NOREF;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

#define BEZEL_STYLES @{ \
    @"square"  : @(NSTextFieldSquareBezel), \
    @"rounded" : @(NSTextFieldRoundedBezel), \
}


#define TEXT_LINEBREAK @{                                 \
    @"wordWrap"       : @(NSLineBreakByWordWrapping),     \
    @"charWrap"       : @(NSLineBreakByCharWrapping),     \
    @"clip"           : @(NSLineBreakByClipping),         \
    @"truncateHead"   : @(NSLineBreakByTruncatingHead),   \
    @"truncateTail"   : @(NSLineBreakByTruncatingTail),   \
    @"truncateMiddle" : @(NSLineBreakByTruncatingMiddle), \
}

#pragma mark - Support Functions and Classes

@interface HSASMGUITKElementTextField : NSTextField <NSTextFieldDelegate>
@property int callbackRef ;
@property int editingCallbackRef ;
@property int selfRefCount ;
@end

@implementation HSASMGUITKElementTextField

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect] ;
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

- (void)performCallback:(id)message {
    NSArray *arguments = @[] ;
    if (message) {
        if ([message isKindOfClass:[NSArray class]]) {
            arguments = message ;
        } else {
            arguments = @[ message ] ;
        }
    }

    if (_callbackRef != LUA_NOREF) {
        LuaSkin *skin = [LuaSkin shared] ;
        [skin pushLuaRef:refTable ref:_callbackRef] ;
        [skin pushNSObject:self] ;
        int argumentCount = 1 ;
        for (id object in arguments) [skin pushNSObject:object] ;
        argumentCount += arguments.count ;
        if (![skin protectedCallAndTraceback:argumentCount nresults:0]) {
            NSString *errorMessage = [skin toNSObjectAtIndex:-1] ;
            lua_pop(skin.L, 1) ;
            [skin logError:[NSString stringWithFormat:@"%s:callback(%@) error:%@", USERDATA_TAG, message, errorMessage]] ;
        }
    } else {
        // allow next responder a chance since we don't have a callback set
        id nextInChain = [self nextResponder] ;
        if (nextInChain) {
            SEL passthroughCallback = NSSelectorFromString(@"preformPassthroughCallback:") ;
            if ([nextInChain respondsToSelector:passthroughCallback]) {
                NSMutableArray *passThroughArguments = [arguments mutableCopy] ;
                [passThroughArguments insertObject:self atIndex:0] ;
                [nextInChain performSelectorOnMainThread:passthroughCallback
                                              withObject:passThroughArguments
                                           waitUntilDone:YES] ;
            }
        }
    }
}

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
    [self performCallback:@"didBeginEditing"] ;
}

- (void)controlTextDidChange:(__unused NSNotification *)aNotification {
//     [LuaSkin logWarn:[NSString stringWithFormat:@"%s:controlTextDidChange - %@", USERDATA_TAG, aNotification]] ;
    if (self.continuous) [self performCallback:@"textChanged"] ;
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
    [self performCallback:@[ @"didEndEditing", reason]] ;
}

@end

#pragma mark - Module Functions

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

/*!
 Creates a non-editable, non-selectable text field that displays attributed text.
 The line break mode of this field is determined by the attributed string's NSParagraphStyle attribute.
 -param attributedStringValue The attributed string to display in the field.
 -return An initialized text field object.
 */
/*!
 Creates a non-wrapping, non-editable, non-selectable text field that displays text in the default system font.
 -param stringValue The title text to display in the field.
 -return An initialized text field object.
 */
static int textfield_newLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TANY, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield ;
    if (lua_type(L, 1) == LUA_TUSERDATA) {
        [skin checkArgs:LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
        textfield = [HSASMGUITKElementTextField labelWithAttributedString:[skin toNSObjectAtIndex:1]] ;
    } else {
        [skin checkArgs:LS_TSTRING, LS_TBREAK] ;
        textfield = [HSASMGUITKElementTextField labelWithString:[skin toNSObjectAtIndex:1]] ;
    }
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/*!
 Creates a non-wrapping editable text field.
 -param stringValue The initial contents of the text field, or nil for an initially empty text field.
 -return An initialized text field object.
 */
static int textfield_newTextField(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield = [HSASMGUITKElementTextField textFieldWithString:[skin toNSObjectAtIndex:1]] ;
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/*!
 Creates a wrapping, non-editable, selectable text field that displays text in the default system font.
 -param stringValue The title text to display in the field.
 -return An initialized text field object.
 */
static int textfield_newWrappingLabel(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TSTRING, LS_TBREAK] ;

    HSASMGUITKElementTextField *textfield = [HSASMGUITKElementTextField wrappingLabelWithString:[skin toNSObjectAtIndex:1]] ;
    if (textfield) {
        [skin pushNSObject:textfield] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Methods

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

static int textfield_selectText(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    [textfield selectText:nil] ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

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

static int textfield_lineBreakMode(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared]  ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 2) {
        NSString *key = [skin toNSObjectAtIndex:2] ;
        NSNumber *lineBreakMode = TEXT_LINEBREAK[key] ;
        if (lineBreakMode) {
            textfield.lineBreakMode = [lineBreakMode unsignedIntegerValue] ;
        } else {
            return luaL_argerror(L, 1, [[NSString stringWithFormat:@"must be one of %@", [[TEXT_LINEBREAK allKeys] componentsJoinedByString:@", "]] UTF8String]) ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        NSNumber *lineBreakMode = @(textfield.lineBreakMode) ;
        NSArray *temp = [TEXT_LINEBREAK allKeysForObject:lineBreakMode];
        NSString *answer = [temp firstObject] ;
        if (answer) {
            [skin pushNSObject:answer] ;
        } else {
            [skin logWarn:[NSString stringWithFormat:@"%s:unrecognized control tint %@ -- notify developers", USERDATA_TAG, lineBreakMode]] ;
            lua_pushnil(L) ;
        }
    }
    return 1;
}

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

static int textfield_placeholderString(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        NSString *placeholderString = ((NSTextFieldCell *)textfield.cell).placeholderString ;
        [skin pushNSObject:([placeholderString isEqualToString:@""] ? ((NSTextFieldCell *)textfield.cell).placeholderAttributedString : placeholderString)] ;
    } else {
        if (lua_type(L, 2) == LUA_TUSERDATA) {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, "hs.styledtext", LS_TBREAK] ;
            ((NSTextFieldCell *)textfield.cell).placeholderString = @"" ;
            ((NSTextFieldCell *)textfield.cell).placeholderAttributedString = [skin toNSObjectAtIndex:2] ;
        } else {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
            ((NSTextFieldCell *)textfield.cell).placeholderString = [skin toNSObjectAtIndex:2] ;
        }
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

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

static int textfield_usesSingleLineMode(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, textfield.usesSingleLineMode) ;
    } else {
        textfield.usesSingleLineMode = (BOOL)lua_toboolean(L, 2) ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

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

static int textfield_stringValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TANY | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    BOOL getAttributed = NO ;
    if (lua_type(L, -1) == LUA_TBOOLEAN) {
        getAttributed = (BOOL)lua_toboolean(L, -1) ;
        lua_pop(L, 1) ;
    }
    if (lua_gettop(L) == 1) {
        [skin pushNSObject:getAttributed ? textfield.attributedStringValue : textfield.stringValue] ;
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

static int textfield_automaticTextCompletionEnabled(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    HSASMGUITKElementTextField *textfield = [skin toNSObjectAtIndex:1] ;

    if (lua_gettop(L) == 1) {
        if ([textfield respondsToSelector:NSSelectorFromString(@"automaticTextCompletionEnabled")]) {
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
    {"singleLineMode",          textfield_usesSingleLineMode},
    {"expandIntoTooltip",       textfield_allowsExpansionToolTips},
    {"lineBreakMode",           textfield_lineBreakMode},

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
        @"singleLineMode",
        @"expandIntoTooltip",
        @"lineBreakMode",
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
    if ([NSTextField instancesRespondToSelector:NSSelectorFromString(@"automaticTextCompletionEnabled")]) {
        lua_pushstring(L, "automaticTextCompletion") ;
        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    }
    lua_setfield(L, -2, "_propertyList") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritController") ;
    lua_pushboolean(L, YES) ; lua_setfield(L, -2, "_inheritView") ;
    lua_pop(L, 1) ;

    return 1;
}
