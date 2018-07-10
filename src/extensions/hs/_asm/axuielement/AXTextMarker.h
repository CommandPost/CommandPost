// Culled from various sources at https://webkit.org

// Nope.  Still crashes... functions seem to be defined in WebCore, but even if I force
// linking with WebCore with dlopen and verify functions actually have a value other than
// 0x0, invoking any of them crashes immediately...
//
// default	23:32:04.901909 -0500	kernel	AMFI: allowing exception handler for 'Hammerspoon' (36496) because SIP is disabled.
//   -- note, should try after re-enabling SIP... forgot about doing that
//
// and in actual crash log:
// Exception Type:        EXC_BAD_ACCESS (SIGBUS)
// Exception Codes:       KERN_PROTECTION_FAILURE at 0x00007fff9b9a4db8
// Exception Note:        EXC_CORPSE_NOTIFY
//
// Termination Signal:    Bus error: 10
// Termination Reason:    Namespace SIGNAL, Code 0xa
// Terminating Process:   exc handler [0]
//
// VM Regions Near 0x7fff9b9a4db8:
//     __DATA                 00007fff9b7b6000-00007fff9b7df000 [  164K] rw-/rwx SM=COW  /System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox
// --> __DATA                 00007fff9b7df000-00007fff9b9c7000 [ 1952K] rw-/rwx SM=COW  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore
//     __DATA                 00007fff9b9c7000-00007fff9b9fe000 [  220K] rw-/rwx SM=COW  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebKitLegacy.framework/Versions/A/WebKitLegacy
//
// Application Specific Information:
// Performing @selector(tryMessage:) from sender HSGrowingTextField 0x7fd95351d9b0
//
// Thread 0 Crashed:: Dispatch queue: com.apple.main-thread
// 0   ???                           	0x00007fff9b9a4db8 wkGetAXTextMarkerTypeID + 0

// from WebKit/Source/WebCore/accessibility/AccessibilityObject.h
typedef unsigned AXID;

// from WebKit/Source/WebCore/editing/TextAffinity.h
enum EAffinity { UPSTREAM = 0, DOWNSTREAM = 1 };

// from WebKit/Source/WebCore/accessibility/AXObjectCache.h
struct TextMarkerData {
    AXID axID;
// not gonna worry about this one for now...
//     Node* node;
    void* node;
    int offset;
    int characterStartIndex;
    int characterOffset;
    bool ignored;
    enum EAffinity affinity;
};

// from WebKit/Source/WebCore/platform/mac/WebCoreSystemInterface.mm
// extern CFTypeID (*wkGetAXTextMarkerTypeID)(void);
// extern CFTypeID (*wkGetAXTextMarkerRangeTypeID)(void);
// extern CFTypeRef (*wkCreateAXTextMarkerRange)(CFTypeRef start, CFTypeRef end);
// extern CFTypeRef (*wkCopyAXTextMarkerRangeStart)(CFTypeRef range);
// extern CFTypeRef (*wkCopyAXTextMarkerRangeEnd)(CFTypeRef range);
// extern CFTypeRef (*wkCreateAXTextMarker)(const void *bytes, size_t len);
// extern BOOL (*wkGetBytesFromAXTextMarker)(CFTypeRef textMarker, void *bytes, size_t length);
// extern AXUIElementRef (*wkCreateAXUIElementRef)(id element);

extern CFTypeID wkGetAXTextMarkerTypeID();
extern CFTypeID wkGetAXTextMarkerRangeTypeID();
extern CFTypeRef wkCreateAXTextMarkerRange(CFTypeRef start, CFTypeRef end);
extern CFTypeRef wkCopyAXTextMarkerRangeStart(CFTypeRef range);
extern CFTypeRef wkCopyAXTextMarkerRangeEnd(CFTypeRef range);
extern CFTypeRef wkCreateAXTextMarker(const void *bytes, size_t len);
extern BOOL wkGetBytesFromAXTextMarker(CFTypeRef textMarker, void *bytes, size_t length);
