#pragma once

@import Cocoa ;
@import LuaSkin ;

// #import "AXTextMarker.h"

#define USERDATA_TAG "hs._asm.axuielement"
#define OBSERVER_TAG "hs._asm.axuielement.observer"

#define get_axuielementref(L, idx, tag) *((AXUIElementRef*)luaL_checkudata(L, idx, tag))
#define get_axobserverref(L, idx, tag) *((AXObserverRef*)luaL_checkudata(L, idx, tag))


extern BOOL new_application(lua_State* L, pid_t pid) ;
extern void new_window(lua_State* L, AXUIElementRef win) ;

extern int pushAXUIElement(lua_State *L, AXUIElementRef theElement) ;
extern int pushAXObserver(lua_State *L, AXObserverRef theObserver) ;
extern const char *AXErrorAsString(AXError theError) ;

extern int pushCFTypeToLua(lua_State *L, CFTypeRef theItem, int refTable) ;
extern CFTypeRef lua_toCFType(lua_State *L, int idx) ;

int luaopen_hs__asm_axuielement_observer(lua_State* L) ;
