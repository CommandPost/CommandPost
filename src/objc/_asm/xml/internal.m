@import Cocoa ;
@import LuaSkin ;

// Documentation Needed:
//  Need examples/documentation for XPath and XQuery queries

// DTD Methods needed

// Module Functions:
// open should take a true url, not just a file
// NSXMLNode localNameForName, prefixForName
// NSXMLDTD  predefinedEntityDeclarationForName
//
// // Module Methods:
// // NSXMLNode nodesForXPath objectsForXQuery:constants:
//
// should we allow creating an xml doc from scratch?

#define USERDATA_TAG        "hs._asm.xml"
static int refTable ;

#define get_objectFromUserdata(objType, L, idx) (objType*)*((void**)luaL_checkudata(L, idx, USERDATA_TAG))

#pragma mark - Support Functions and Classes

#pragma mark - Module Functions

/// hs._asm.xml.openDTD(url) -> xmlDTD object
/// Constructor
/// Returns an xmlDTD object created from the contents of the specified URL source.
///
/// Parameters:
///  * url - the url specifying the location of the DTD declarations
///
/// Returns:
///  * an xmlDTD object
static int xml_openDTD(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    NSXMLDTD *xmlDTD;
    NSError  *err=nil;

    NSURL *furl = [NSURL URLWithString:[skin toNSObjectAtIndex:1]];

    if (!furl) {
        return luaL_error(L, "Malformed URL %s.", lua_tostring(L, 1)) ;
    }

    xmlDTD = [[NSXMLDTD alloc] initWithContentsOfURL:furl
                                                  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveEntities)
                                                    error:&err];
    if (err) {
        [skin pushNSObject:[err description]] ;
        return lua_error(L) ;
    }

    [skin pushNSObject:xmlDTD] ;
    return 1 ;
}

/// hs._asm.xml.openURL(url) -> xmlDocument object
/// Constructor
/// Returns an xmlDocument object created from the XML or HTML contents of the specified URL source.
///
/// Parameters:
///  * url - the url specifying the location of the XML or HTML source
///
/// Returns:
///  * an xmlDocument object
static int xml_openURL(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    NSXMLDocument *xmlDoc;
    NSError       *err=nil;

    NSURL         *furl = [NSURL URLWithString:[skin toNSObjectAtIndex:1]];

    if (!furl) {
        return luaL_error(L, "Malformed URL %s.", lua_tostring(L, 1)) ;
    }

    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
                                                  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA|NSXMLNodeLoadExternalEntitiesAlways)
                                                    error:&err];
    if (xmlDoc == nil) {
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
                                                      options:NSXMLDocumentTidyXML|NSXMLNodeLoadExternalEntitiesAlways
                                                        error:&err];
    }

    if (err) {
        [skin pushNSObject:[err description]] ;
        return lua_error(L) ;
    }

    [skin pushNSObject:xmlDoc] ;
    return 1 ;
}

/// hs._asm.xml.open(file) -> xmlDocument object
/// Constructor
/// Returns an xmlDocument object created from the XML or HTML contents of the file specified.
///
/// Parameters:
///  * file - the path to the file containing the XML or HTML source
///
/// Returns:
///  * an xmlDocument object
///
/// Notes:
///  * This is a wrapper for [hs._asm.xml.openURL](#openURL) which converts the specified path into a properly formatted file URL.
static int xml_open(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    NSString *file = [skin toNSObjectAtIndex:1] ;
    NSURL    *furl = [NSURL fileURLWithPath:[file stringByExpandingTildeInPath]];
    if (!furl) {
        return luaL_error(L, "Can't create a file URL for file %s.", [file UTF8String]) ;
    }
    lua_pop(L, 1) ;

    lua_pushcfunction(L, xml_openURL) ;
    lua_pushstring(L, [[furl absoluteString] UTF8String]) ;
    if (lua_pcall(L, 1, 1, 0) != LUA_OK)
        return lua_error(L) ;
    else
        return 1 ;
}

/// hs._asm.xml.localNameFor(qualifiedName) -> string
/// Function
/// Returns the local name of the specified qualified name
///
/// Parameters:
///  * qualifiedName - a namespace-qualifying name for a node
///
/// Returns:
///  * a string containing the local name for the specified namespace-qualifying name
///
/// Notes:
///  * for example, `hs._asm.xml.localNameFor("acme:chapter")` would return `chapter`
static int xml_localNameFor(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    [skin pushNSObject:[NSXMLNode localNameForName:[skin toNSObjectAtIndex:1]]] ;
    return 1 ;
}

/// hs._asm.xml.prefixFor(qualifiedName) -> string
/// Function
/// Returns the prefix of the specified qualified name
///
/// Parameters:
///  * qualifiedName - a namespace-qualifying name for a node
///
/// Returns:
///  * a string containing the prefix for the specified namespace-qualifying name
///
/// Notes:
///  * for example, `hs._asm.xml.prefixFor("acme:chapter")` would return  `acme`
static int xml_prefixFor(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    [skin pushNSObject:[NSXMLNode prefixForName:[skin toNSObjectAtIndex:1]]] ;
    return 1 ;
}

/// hs._asm.xml.predefinedEntityDeclaration(entityName) -> xmlDTDNode object
/// Constructor
/// Returns an xmlDTDNode object for the predefined entity specified
///
/// Parameters:
///  * entityName - the name of the predefined entity
///
/// Returns:
///  * an xmlDTDNode object for the specified predefined entity, or nil if no predefined entity with that name exists.
///
/// Notes:
///  * The five predefined entity references (or character references) are:
///    * < (less-than sign)    - with the entity name "lt"
///    * > (greater-than sign) - with the entity name "gt"
///    * & (ampersand)         - with the entity name "amp"
///    * " (quotation mark)    - with the entity name "quot"
///    * ' (apostrophe)        - with the entity name "apos"
static int xml_predefinedEntityDeclaration(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TSTRING | LS_TNUMBER, LS_TBREAK] ;
    luaL_checkstring(L, 1) ;
    NSString *name = [NSString stringWithUTF8String:luaL_checkstring(L, 1)] ;
    NSXMLDTDNode *node = [NSXMLDTD predefinedEntityDeclarationForName:name] ;
    [skin pushNSObject:node] ;
    return 1 ;
}

#pragma mark - Common Module Methods

/// hs._asm.xml:nodeType() -> string
/// Method
/// Returns the specific NSXML class type of the object as a string.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the XML class type as a string
///
/// Notes:
///  * the possible returned values are as follows:
///    * NSXMLNode     - the base class; generally, you should not see this value, as a more specific label from the following should be returned instead.
///    * NSXMLDocument - the object represents an XML Document internalized into a logical tree structure
///    * NSXMLElement  - the object represents an element node in an XML tree structure
///    * NSXMLDTD      - the object represents a Document Type Definition
///    * NSXMLDTDNode  - the object represents an element, attribute-list, entity, or notation declaration in a Document Type Declaration
static int xml_nodeType(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")])           lua_pushstring(L, "NSXMLDTD") ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")])  lua_pushstring(L, "NSXMLDTDNode") ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")]) lua_pushstring(L, "NSXMLDocument") ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLElement")])  lua_pushstring(L, "NSXMLElement") ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLNode")])     lua_pushstring(L, "NSXMLNode") ;
    else                                                              lua_pushstring(L, "unknown") ;

    return 1 ;
}


/// hs._asm.xml:rootDocument() -> xmlDocument obejct
/// Method
/// Returns the NSXMLDocument object containing the root element and representing the XML document as a whole.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an xmlDocument object
static int xml_rootDocument(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj rootDocument]] ;
    return 1 ;
}

/// hs._asm.xml:parent() -> xmlNode obejct
/// Method
/// Returns the parent node of the object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an xmlNode object, or nil if no parent exists for this object
static int xml_parent(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj parent]] ;
    return 1 ;
}

/// hs._asm.xml:childAtIndex(index) -> xmlNode obejct
/// Method
/// Returns the child node at the specified index.
///
/// Parameters:
///  * index - an integer index specifying the child object to return
///
/// Returns:
///  * an xmlNode object, or nil if no child exists at that index
///
/// Notes:
///  * The returned node object can represent an element, comment, text, or processing instruction.
static int xml_childAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    lua_Integer idx = luaL_checkinteger(L, 2) ;

    if (idx < 0 || idx > (lua_Integer)[obj childCount])
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index must be between 0 and %lu", [obj childCount]] UTF8String]) ;

    @try {
        [skin pushNSObject:[obj childAtIndex:(NSUInteger)idx]] ;
    } @catch (NSException *theException) {
        [skin logError:[NSString stringWithFormat:@"%@:%@", [theException name], [theException reason]]] ;
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.xml:childCount() -> integer
/// Method
/// Returns the number of child nodes for the object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the number of child nodes for the object
static int xml_childCount(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    lua_pushinteger(L, (lua_Integer)[obj childCount]) ;
    return 1 ;
}

/// hs._asm.xml:children() -> table
/// Method
/// Returns the children of the object in a table as an array.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the children of the object in a table as an array.
static int xml_children(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj children]] ;
    return 1 ;
}

/// hs._asm.xml:nextNode() -> xmlNode object
/// Method
/// Returns the next xmlNode object in document order.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the next xmlNode object in document order.
///
/// Notes:
///  * Use this method to “walk” forward through the tree structure representing an XML document or document section. Document order is the natural order that XML constructs appear in markup text. This method bypasses namespace and attribute nodes when traversing the tree in document order.
static int xml_nextNode(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj nextNode]] ;
    return 1 ;
}

/// hs._asm.xml:nextSibling() -> xmlNode object
/// Method
/// Returns the next xmlNode object that is a sibling node to the object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the next xmlNode object that is a sibling node to the object.
///
/// Notes:
///  * This object will have an index value that is one more than the object’s. If there are no more subsequent siblings (that is, other child nodes of the object’s parent) the method returns nil.
static int xml_nextSibling(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj nextSibling]] ;
    return 1 ;
}

/// hs._asm.xml:previousNode() -> xmlNode object
/// Method
/// Returns the previous xmlNode object in document order.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the previous xmlNode object in document order.
///
/// Notes:
///  * Use this method to “walk” backward through the tree structure representing an XML document or document section. Document order is the natural order that XML constructs appear in markup text. This method bypasses namespace and attribute nodes when traversing the tree in document order.
static int xml_previousNode(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj previousNode]] ;
    return 1 ;
}

/// hs._asm.xml:previousSibling() -> xmlNode object
/// Method
/// Returns the previous xmlNode object that is a sibling node to the object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the previous xmlNode object that is a sibling node to the object.
///
/// Notes:
///  * This object will have an index value that is one less than the object’s. If there are no more previous siblings (that is, other child nodes of the object’s parent) the method returns nil.
static int xml_previousSibling(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj previousSibling]] ;
    return 1 ;
}

/// hs._asm.xml:xmlString([options]) -> string
/// Method
/// Returns the string representation of the object as it would appear in an XML document.
///
/// Parameters:
///  * options - an optional integer value made by logically OR'ing together options described in [hs._asm.xml.nodeOptions](#nodeOptions).  Defaults to `hs._asm.xml.nodeOptions.optionsNone`.
///
/// Returns:
///  * the string representation of the object as it would appear in an XML document.
///
/// Notes:
///  * The returned string includes the string representations of all children.
static int xml_xmlString(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL, LS_TBREAK] ;
    NSXMLNode   *obj = [skin toNSObjectAtIndex:1] ;
    lua_Integer options = NSXMLNodeOptionsNone ;

    if (lua_type(L, 2) != LUA_TNONE) options = luaL_checkinteger(L, 2) ;

    [skin pushNSObject:[obj XMLStringWithOptions:(NSUInteger)options]] ;
    return 1 ;
}

/// hs._asm.xml:canonicalXMLString([comments]) -> string
/// Method
/// Returns a string encapsulating the object’s XML in canonical form.
///
/// Parameters:
///  * comments - an optional boolean indicating whether or not comment nodes should be included.  Defaults to true.
///
/// Returns:
///  * a string encapsulating the object’s XML in canonical form.
///
/// Notes:
///  * The canonical form of an XML document is defined by the World Wide Web Consortium at http://www.w3.org/TR/xml-c14n. Generally, if two documents with varying physical representations have the same canonical form, then they are considered logically equivalent within the given application context. The following list summarizes most key aspects of canonical form as defined by the W3C recommendation:
///    * Encodes the document in UTF-8.
///    * Normalizes line breaks to “#xA” on input before parsing.
///    * Normalizes attribute values in the manner of a validating processor.
///    * Replaces character and parsed entity references with their character content.
///    * Replaces CDATA sections with their character content.
///    * Removes the XML declaration and the document type declaration (DTD).
///    * Converts empty elements to start-end tag pairs.
///    * Normalizes whitespace outside of the document element and within start and end tags.
///    * Retains all whitespace characters in content (excluding characters removed during line-feed normalization).
///    * Sets attribute value delimiters to quotation marks (double quotes).
///    * Replaces special characters in attribute values and character content with character references.
///    * Removes superfluous namespace declarations from each element.
///    * Adds default attributes to each element.
///    * Imposes lexicographic order on the namespace declarations and attributes of each element.
static int xml_canonicalXMLString(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBOOLEAN | LS_TOPTIONAL, LS_TBREAK] ;
    NSXMLNode   *obj = [skin toNSObjectAtIndex:1] ;
    BOOL        preserveComments = YES ;

    if (lua_type(L, 2) != LUA_TNONE) preserveComments = (BOOL)lua_toboolean(L, 2) ;

    [skin pushNSObject:[obj canonicalXMLStringPreservingComments:preserveComments]] ;
    return 1 ;
}

/// hs._asm.xml:index() -> integer
/// Method
/// Returns the index of the object identifying its position relative to its sibling nodes.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the index of the object identifying its position relative to its sibling nodes.
static int xml_index(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    lua_pushinteger(L, (lua_Integer)[obj index]) ;
    return 1 ;
}

/// hs._asm.xml:kind() -> string
/// Method
/// Returns the kind of node the object is as a string.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a string representing the type of information represented by this node.  Possible values include:
///    * invalid               - a node object created without a valid kind being specified
///    * document              - a document node
///    * element               - an element node
///    * attribute             - an attribute node
///    * namespace             - a namespace node
///    * processingInstruction - a processing instruction node
///    * comment               - a comment node
///    * text                  - a text node
///    * DTD                   - a document type declaration node
///    * entityDeclaration     - an entity declaration node
///    * attributeDeclaration  - an attribute declaration node
///    * elementDeclaration    - an element declaration node
///    * notationDeclaration   - a notation declaration
///    * unknown               - should not occur -- the presence of this value indicates that an error has occurred of that Apple has changed the NSXML* classes and this module should be updated.
static int xml_kind(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    switch ([obj kind]) {
        case NSXMLInvalidKind:               lua_pushstring(L, "invalid") ; break ;
        case NSXMLDocumentKind:              lua_pushstring(L, "document") ; break ;
        case NSXMLElementKind:               lua_pushstring(L, "element") ; break ;
        case NSXMLAttributeKind:             lua_pushstring(L, "attribute") ; break ;
        case NSXMLNamespaceKind:             lua_pushstring(L, "namespace") ; break ;
        case NSXMLProcessingInstructionKind: lua_pushstring(L, "processingInstruction") ; break ;
        case NSXMLCommentKind:               lua_pushstring(L, "comment") ; break ;
        case NSXMLTextKind:                  lua_pushstring(L, "text") ; break ;
        case NSXMLDTDKind:                   lua_pushstring(L, "DTD") ; break ;
        case NSXMLEntityDeclarationKind:     lua_pushstring(L, "entityDeclaration") ; break ;
        case NSXMLAttributeDeclarationKind:  lua_pushstring(L, "attributeDeclaration") ; break ;
        case NSXMLElementDeclarationKind:    lua_pushstring(L, "elementDeclaration") ; break ;
        case NSXMLNotationDeclarationKind:   lua_pushstring(L, "notationDeclaration") ; break ;
        default:                             lua_pushstring(L, "unknown") ; break ;
    }
    return 1 ;
}

/// hs._asm.xml:level() -> integer
/// Method
/// Returns the nesting level of the object within the tree hierarchy.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the nesting level of the object within the tree hierarchy.
///
/// Notes:
///  * The root element of a document has a nesting level of one.
static int xml_level(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    lua_pushinteger(L, (lua_Integer)[obj level]) ;
    return 1 ;
}

/// hs._asm.xml:name() -> string
/// Method
/// Returns the name of the object node.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the name of the object node or nil if the object does not have a name.
///
/// Notes:
///  * This method is applicable only to objects representing elements, attributes, namespaces, processing instructions, and DTD-declaration nodes. If the object is not one of these kinds, this method returns nil.
static int xml_name(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj name]] ;
    return 1 ;
}

/// hs._asm.xml:objectValue() -> object
/// Method
/// Returns the value of the xmlObject node.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the value of the xmlObject node.  For nodes without content (for example, document nodes), this method returns the same value as [hs._asm.xml:stringValue](#stringValue), or an empty string if there is no string value.
static int xml_objectValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj objectValue]] ;
    return 1 ;
}

/// hs._asm.xml:stringValue() -> string
/// Method
/// Returns the content of the xmlObject as a string value.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the content of the xmlObject as a string value.
///
/// Notes:
///  * If the receiver is a node object of element kind, the content is that of any text-node children. This method recursively visits elements nodes and concatenates their text nodes in document order with no intervening spaces.
///  * If the receiver’s content is set as an object value, this method returns the string value representing the object.
///  * If the object value is one of the standard, built-in ones (NSNumber, NSCalendarDate, and so on), the string value is in canonical format as defined by the W3C XML Schema Data Types specification.
///  * If the object value is not represented by one of these classes (or if the default value transformer for a class has been overridden), the string value is generated by the NSValueTransformer registered for that object type.
static int xml_stringValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj stringValue]] ;
    return 1 ;
}

/// hs._asm.xml:setStringValue(value) -> string
/// Method
/// Returns the content of the xmlObject as a string value.
///
/// Parameters:
///  * value - The value you want to set the string value to.
///
/// Returns:
///  * the content of the xmlObject as a string value.
static int xml_setStringValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    
    NSString *value = [skin toNSObjectAtIndex:2] ;
    [obj setStringValue:value];
    
    [skin pushNSObject:[obj stringValue]] ;
    return 1 ;
}

/// hs._asm.xml:setStringValue(value) -> string
/// Method
/// Returns the content of the xmlObject as a string value.
///
/// Parameters:
///  * value - The value you want to set the string value to.
///
/// Returns:
///  * the content of the xmlObject as a string value.
static int xml_updateStringValue(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    
    NSXMLElement *obj = [skin toNSObjectAtIndex:1] ;
    NSString *value = [skin toNSObjectAtIndex:2] ;

    //NSXMLElement *element;
    NSXMLNode *node = [[NSXMLNode alloc] initWithKind: NSXMLTextKind];
    [node setStringValue:value];

    [obj addChild: node];
    
    [skin pushNSObject:[obj stringValue]] ;
    return 1 ;
}

/// hs._asm.xml:URI() -> string
/// Method
/// Returns the URI associated with the xmlObject.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the URI associated with the xmlObject
///
/// Notes:
///  * A node’s URI is derived from its namespace or a document’s URI; for documents, the URI comes either from the parsed XML or is explicitly set.
static int xml_URI(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj URI]] ;
    return 1 ;
}

/// hs._asm.xml:localName() -> string
/// Method
/// Returns the local name of the xmlObject.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the local name of the xmlObject.
///
/// Notes:
///  * The local name is the part of a node name that follows a namespace-qualifying colon or the full name if there is no colon.
static int xml_localName(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj localName]] ;
    return 1 ;
}

/// hs._asm.xml:prefix() -> string
/// Method
/// Returns the prefix (namespace) of the xmlObject’s name.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the prefix (namespace) of the xmlObject.
///
/// Notes:
///  * The prefix is the part of a namespace-qualified name that precedes the colon.  This method returns an empty string if the object’s name is not qualified by a namespace.
static int xml_prefix(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj prefix]] ;
    return 1 ;
}

/// hs._asm.xml:XPath() -> string
/// Method
/// Returns the XPath expression identifying the xmlObject node’s location in the document tree.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the XPath expression identifying the xmlObject node’s location in the document tree.
static int xml_XPath(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    [skin pushNSObject:[obj XPath]] ;
    return 1 ;
}

/// hs._asm.xml:XPathQuery([query]) -> table
/// Method
/// Returns a table containing the nodes resulting from executing an XPath query upon xmlObject.
///
/// Parameters:
///  * query - an optional string that specifies an XPath query.  Defaults to ".".
///
/// Returns:
///  * a table containing the nodes (if any) that match the XPath query within the context of the xmlObject node.
static int xml_XPathQuery(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING | LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    NSError   *error ;
    NSString  *query = @"." ;

    if (lua_type(L, 2) != LUA_TNONE) {
        luaL_checkstring(L, 2) ;
        query = [skin toNSObjectAtIndex:2] ;
    }

    [skin pushNSObject:[obj nodesForXPath:query error:&error]] ;
    if (error) return luaL_error(L, [[error description] UTF8String]) ;
    return 1 ;
}

/// hs._asm.xml:XQuery([query], [constants]) -> table
/// Method
/// Returns a table containing the nodes resulting from executing an XQuery query upon xmlObject.
///
/// Parameters:
///  * query     - an optional string that specifies an XQuery query.  Defaults to ".".
///  * constants - an optional table containing the constants required for the query.  Defaults to an empty dictionary.
///
/// Returns:
///  * a table containing the nodes (if any) that match the XQuery query within the context of the xmlObject node.
static int xml_XQuery(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE | LS_TSTRING | LS_TNUMBER | LS_TOPTIONAL,
                    LS_TTABLE | LS_TOPTIONAL,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    NSError   *error ;
    NSString  *query = @"." ;
    NSDictionary *constants ;
    int          constIdx = 3 ;

    if ((lua_type(L, 2) != LUA_TNONE) && (lua_type(L, 2) != LUA_TTABLE)) {
        luaL_checkstring(L, 2) ;
        query = [skin toNSObjectAtIndex:2] ;
    } else {
        constIdx = 2 ;
    }

    if (lua_type(L, constIdx) != LUA_TNONE) {
        luaL_checktype(L, constIdx, LUA_TTABLE) ;
        constants = [skin toNSObjectAtIndex:constIdx] ;
    }

    [skin pushNSObject:[obj objectsForXQuery:query constants:constants error:&error]] ;
    if (error) return luaL_error(L, [[error description] UTF8String]) ;
    return 1 ;
}

#pragma mark - DTD & DTDNode Module Methods

/// hs._asm.xml:publicID() -> string
/// Method
/// Returns the xmlObject's public identifier.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the public identifier for the xmlObject.
///
/// Note:
///  * this method is only valid for DTD and DTDNode xmlObjects; if used on an xmlObject of a different type, it will result in an error.
static int xml_publicID(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")])
        [skin pushNSObject:[(NSXMLDTD *)obj publicID]] ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")])
        [skin pushNSObject:[(NSXMLDTDNode *)obj publicID]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDTD or NSXMLDTDNode") ;
    return 1 ;
}

/// hs._asm.xml:systemID() -> string
/// Method
/// Returns the xmlObject's system identifier.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the system identifier for the xmlObject.
///
/// Note:
///  * this method is only valid for DTD and DTDNode xmlObjects; if used on an xmlObject of a different type, it will result in an error.
static int xml_systemID(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")])
        [skin pushNSObject:[(NSXMLDTD *)obj systemID]] ;
    else if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")])
        [skin pushNSObject:[(NSXMLDTDNode *)obj systemID]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDTD or NSXMLDTDNode") ;
    return 1 ;
}

#pragma mark - DTD Module Methods

static int xml_elementDeclaration(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING | LS_TNUMBER,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")]) {
        luaL_checkstring(L, 2) ;
        NSString *name = [NSString stringWithUTF8String:luaL_checkstring(L, 2)] ;
        NSXMLDTDNode *node = [(NSXMLDTD *)obj elementDeclarationForName:name] ;
        [skin pushNSObject:node] ;
    } else
        return luaL_argerror(L, 1, "expected NSXMLDTD") ;
    return 1 ;
}

static int xml_attributeElementDeclaration(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING | LS_TNUMBER,
                    LS_TSTRING | LS_TNUMBER,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")]) {
        luaL_checkstring(L, 2) ;
        luaL_checkstring(L, 3) ;
        NSString *name = [NSString stringWithUTF8String:luaL_checkstring(L, 2)] ;
        NSString *elementName = [NSString stringWithUTF8String:luaL_checkstring(L, 3)] ;
        NSXMLDTDNode *node = [(NSXMLDTD *)obj attributeDeclarationForName:name
                                                              elementName:elementName] ;
        [skin pushNSObject:node] ;
    } else
        return luaL_argerror(L, 1, "expected NSXMLDTD") ;
    return 1 ;
}

static int xml_entityDeclaration(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING | LS_TNUMBER,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")]) {
        NSString *name = [NSString stringWithUTF8String:luaL_checkstring(L, 2)] ;
        NSXMLDTDNode *node = [(NSXMLDTD *)obj entityDeclarationForName:name] ;
        [skin pushNSObject:node] ;
    } else
        return luaL_argerror(L, 1, "expected NSXMLDTD") ;
    return 1 ;
}

static int xml_notationDeclaration(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING | LS_TNUMBER,
                    LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTD")]) {
        NSString *name = [NSString stringWithUTF8String:luaL_checkstring(L, 2)] ;
        NSXMLDTDNode *node = [(NSXMLDTD *)obj notationDeclarationForName:name] ;
        [skin pushNSObject:node] ;
    } else
        return luaL_argerror(L, 1, "expected NSXMLDTD") ;
    return 1 ;
}

#pragma mark - DTDNode Module Methods

static int xml_isExternal(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")])
        lua_pushboolean(L, [(NSXMLDTDNode *)obj isExternal]) ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDTDNode") ;
    return 1 ;
}

static int xml_notationName(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")])
        [skin pushNSObject:[(NSXMLDTDNode *)obj notationName]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDTDNode") ;
    return 1 ;
}

static int xml_DTDKind(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDTDNode")]) {
        switch ([(NSXMLDTDNode *)obj DTDKind]) {
          case NSXMLEntityGeneralKind:               lua_pushstring(L, "entityGeneral") ; break ;
          case NSXMLEntityParsedKind:                lua_pushstring(L, "entityParsed") ; break ;
          case NSXMLEntityUnparsedKind:              lua_pushstring(L, "entityUnparsed") ; break ;
          case NSXMLEntityParameterKind:             lua_pushstring(L, "entityParameter") ; break ;
          case NSXMLEntityPredefined:                lua_pushstring(L, "entityPredefined") ; break ;
          case NSXMLAttributeCDATAKind:              lua_pushstring(L, "attributeCDATA") ; break ;
          case NSXMLAttributeIDKind:                 lua_pushstring(L, "attributeID") ; break ;
          case NSXMLAttributeIDRefKind:              lua_pushstring(L, "attributeIDRef") ; break ;
          case NSXMLAttributeIDRefsKind:             lua_pushstring(L, "attributeIDRefs") ; break ;
          case NSXMLAttributeEntityKind:             lua_pushstring(L, "attributeEntity") ; break ;
          case NSXMLAttributeEntitiesKind:           lua_pushstring(L, "attributeEntities") ; break ;
          case NSXMLAttributeNMTokenKind:            lua_pushstring(L, "attributeNMToken") ; break ;
          case NSXMLAttributeNMTokensKind:           lua_pushstring(L, "attributeNMTokens") ; break ;
          case NSXMLAttributeEnumerationKind:        lua_pushstring(L, "attributeEnumeration") ; break ;
          case NSXMLAttributeNotationKind:           lua_pushstring(L, "attributeNotation") ; break ;
          case NSXMLElementDeclarationUndefinedKind: lua_pushstring(L, "elementDeclarationUndefined") ; break ;
          case NSXMLElementDeclarationEmptyKind:     lua_pushstring(L, "elementDeclarationEmpty") ; break ;
          case NSXMLElementDeclarationAnyKind:       lua_pushstring(L, "elementDeclarationAny") ; break ;
          case NSXMLElementDeclarationMixedKind:     lua_pushstring(L, "elementDeclarationMixed") ; break ;
          case NSXMLElementDeclarationElementKind:   lua_pushstring(L, "elementDeclarationElement") ; break ;
          default:                                   lua_pushstring(L, "unknown") ; break ;
      }
    } else
        return luaL_argerror(L, 1, "expected NSXMLDTDNode") ;
    return 1 ;
}

#pragma mark - Document Module Methods

static int xml_rootElement(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;

    if (![obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;

    [skin pushNSObject:[(NSXMLDocument *)obj rootElement]] ;
    return 1 ;
}

static int xml_characterEncoding(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        [skin pushNSObject:[(NSXMLDocument *)obj characterEncoding]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}

static int xml_DTD(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        [skin pushNSObject:[(NSXMLDocument *)obj DTD]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}

static int xml_MIMEType(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        [skin pushNSObject:[(NSXMLDocument *)obj MIMEType]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}

static int xml_version(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        [skin pushNSObject:[(NSXMLDocument *)obj version]] ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}

static int xml_isStandalone(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")])
        lua_pushboolean(L, [(NSXMLDocument *)obj isStandalone]) ;
    else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}


static int xml_documentContentKind(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;
    if ([obj isKindOfClass:NSClassFromString(@"NSXMLDocument")]) {
        switch([(NSXMLDocument *)obj documentContentKind]) {
           case NSXMLDocumentXMLKind:   lua_pushstring(L, "XML") ; break ;
           case NSXMLDocumentXHTMLKind: lua_pushstring(L, "XHTML") ; break ;
           case NSXMLDocumentHTMLKind:  lua_pushstring(L, "HTML") ; break ;
           case NSXMLDocumentTextKind:  lua_pushstring(L, "text") ; break ;
           default:                     lua_pushstring(L, "unknown") ; break ;
        }
    } else
        return luaL_argerror(L, 1, "expected NSXMLDocument") ;
    return 1 ;
}

#pragma mark - Element Module Methods

static int xml_attributes(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;

    if (![obj isKindOfClass:NSClassFromString(@"NSXMLElement")])
        return luaL_argerror(L, 1, "expected NSXMLElement") ;

    [skin pushNSObject:[(NSXMLElement *)obj attributes]] ;
    return 1 ;
}

static int xml_namespaces(lua_State *L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSXMLNode *obj = [skin toNSObjectAtIndex:1] ;

    if (![obj isKindOfClass:NSClassFromString(@"NSXMLElement")])
        return luaL_argerror(L, 1, "expected NSXMLElement") ;

    [skin pushNSObject:[(NSXMLElement *)obj namespaces]] ;
    return 1 ;
}

#pragma mark - Module Constants

static int xml_nodeIOConstants(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, NSXMLNodeOptionsNone) ;                        lua_setfield(L, -2, "optionsNone") ;
      lua_pushinteger(L, NSXMLNodeIsCDATA) ;                            lua_setfield(L, -2, "isCDATA") ;
      lua_pushinteger(L, NSXMLNodeExpandEmptyElement) ;                 lua_setfield(L, -2, "expandEmptyElement") ;
      lua_pushinteger(L, NSXMLNodeCompactEmptyElement) ;                lua_setfield(L, -2, "compactEmptyElement") ;
      lua_pushinteger(L, NSXMLNodeUseSingleQuotes) ;                    lua_setfield(L, -2, "useSingleQuotes") ;
      lua_pushinteger(L, NSXMLNodeUseDoubleQuotes) ;                    lua_setfield(L, -2, "useDoubleQuotes") ;
      lua_pushinteger(L, NSXMLNodeLoadExternalEntitiesAlways) ;         lua_setfield(L, -2, "loadExternalEntitiesAlways") ;
      lua_pushinteger(L, NSXMLNodeLoadExternalEntitiesSameOriginOnly) ; lua_setfield(L, -2, "loadExternalEntitiesSameOriginOnly") ;
      lua_pushinteger(L, NSXMLNodeLoadExternalEntitiesNever) ;          lua_setfield(L, -2, "loadExternalEntitiesNever") ;
      lua_pushinteger(L, NSXMLNodePrettyPrint) ;                        lua_setfield(L, -2, "prettyPrint") ;
      lua_pushinteger(L, NSXMLNodePreserveNamespaceOrder) ;             lua_setfield(L, -2, "preserveNamespaceOrder") ;
      lua_pushinteger(L, NSXMLNodePreserveAttributeOrder) ;             lua_setfield(L, -2, "preserveAttributeOrder") ;
      lua_pushinteger(L, NSXMLNodePreserveEntities) ;                   lua_setfield(L, -2, "preserveEntities") ;
      lua_pushinteger(L, NSXMLNodePreservePrefixes) ;                   lua_setfield(L, -2, "preservePrefixes") ;
      lua_pushinteger(L, NSXMLNodePreserveCDATA) ;                      lua_setfield(L, -2, "preserveCDATA") ;
      lua_pushinteger(L, NSXMLNodePreserveWhitespace) ;                 lua_setfield(L, -2, "preserveWhitespace") ;
      lua_pushinteger(L, NSXMLNodePreserveDTD) ;                        lua_setfield(L, -2, "preserveDTD") ;
      lua_pushinteger(L, NSXMLNodePreserveCharacterReferences) ;        lua_setfield(L, -2, "preserveCharacterReferences") ;
      lua_pushinteger(L, NSXMLNodePreserveEmptyElements) ;              lua_setfield(L, -2, "preserveEmptyElements") ;
      lua_pushinteger(L, NSXMLNodePreserveQuotes) ;                     lua_setfield(L, -2, "preserveQuotes") ;
      lua_pushinteger(L, NSXMLNodePreserveAll) ;                        lua_setfield(L, -2, "preserveAll") ;
    return 1 ;
}

// static int xml_documentIOConstants(lua_State *L) {
//     lua_newtable(L) ;
//       lua_pushinteger(L, NSXMLDocumentTidyHTML) ;                      lua_setfield(L, -2, "tidyHTML") ;
//       lua_pushinteger(L, NSXMLDocumentTidyXML) ;                       lua_setfield(L, -2, "tidyXML") ;
//       lua_pushinteger(L, NSXMLDocumentValidate) ;                      lua_setfield(L, -2, "validate") ;
//       lua_pushinteger(L, NSXMLDocumentXInclude) ;                      lua_setfield(L, -2, "XInclude") ;
//       lua_pushinteger(L, NSXMLDocumentIncludeContentTypeDeclaration) ; lua_setfield(L, -2, "includeContentTypeDeclaration") ;
//     return 1 ;
// }

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int NSXMLNode_toLua(lua_State *L, id obj) {
    void** xmlPtr = lua_newuserdata(L, sizeof(obj)) ;
    *xmlPtr = (__bridge_retained void *)obj ;
    luaL_getmetatable(L, USERDATA_TAG) ;
    lua_setmetatable(L, -2) ;
    return 1 ;
}

static id toNSXMLNodeTypeFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    NSXMLNode *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge NSXMLNode, L, idx) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
//     NSXMLNode *obj = [skin luaObjectAtIndex:1 toClass:"NSXMLNode"] ;

    lua_pushcfunction(L, xml_nodeType) ;
    lua_pushvalue(L, 1) ;
    lua_pcall(L, 1, 1, 0) ;
    NSString *title = [skin toNSObjectAtIndex:-1] ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin sharedWithState:L] ;
        NSXMLNode *obj1 = [skin luaObjectAtIndex:1 toClass:"NSXMLNode"] ;
        NSXMLNode *obj2 = [skin luaObjectAtIndex:2 toClass:"NSXMLNode"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    NSXMLNode *obj = get_objectFromUserdata(__bridge_transfer NSXMLNode, L, 1) ;
    if (obj) obj = nil ;
    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// static int meta_gc(lua_State* L) {
//     [hsimageReferences removeAllIndexes];
//     hsimageReferences = nil;
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
// NSXMLNode Methods
    {"nodeType",                    xml_nodeType},
    {"rootDocument",                xml_rootDocument},
    {"parent",                      xml_parent},
    {"childAtIndex",                xml_childAtIndex},
    {"childCount",                  xml_childCount},
    {"children",                    xml_children},
    {"nextNode",                    xml_nextNode},
    {"nextSibling",                 xml_nextSibling},
    {"previousNode",                xml_previousNode},
    {"previousSibling",             xml_previousSibling},
    {"xmlString",                   xml_xmlString},
    {"canonicalXMLString",          xml_canonicalXMLString},
    {"index",                       xml_index},
    {"kind",                        xml_kind},
    {"level",                       xml_level},
    {"name",                        xml_name},
    {"objectValue",                 xml_objectValue},
    {"stringValue",                 xml_stringValue},
    {"setStringValue",              xml_setStringValue},
    {"updateStringValue",           xml_updateStringValue},
    {"URI",                         xml_URI},
    {"localName",                   xml_localName},
    {"prefix",                      xml_prefix},
    {"XPath",                       xml_XPath},
    {"XPathQuery",                  xml_XPathQuery},
    {"XQuery",                      xml_XQuery},

// NSXMLDTD and NSXMLDTDNode Methods
    {"publicID",                    xml_publicID},
    {"systemID",                    xml_systemID},

// NSXMLDTD Methods
    {"elementDeclaration",          xml_elementDeclaration},
    {"attributeElementDeclaration", xml_attributeElementDeclaration},
    {"entityDeclaration",           xml_entityDeclaration},
    {"notationDeclaration",         xml_notationDeclaration},

// NSXMLDTDNode Methods
    {"isExternal",                  xml_isExternal},
    {"notationName",                xml_notationName},
    {"DTDKind",                     xml_DTDKind},

// NSXMLDocument Methods
    {"rootElement",                 xml_rootElement},
    {"characterEncoding",           xml_characterEncoding},
    {"DTD",                         xml_DTD},
    {"MIMEType",                    xml_MIMEType},
    {"version",                     xml_version},
    {"isStandalone",                xml_isStandalone},
    {"documentContentKind",         xml_documentContentKind},

// NSXMLElement Methods
    {"rawAttributes",               xml_attributes},
    {"namespaces",                  xml_namespaces},

    {"__tostring",                  userdata_tostring},
    {"__eq",                        userdata_eq},
    {"__gc",                        userdata_gc},
    {NULL,                          NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"open",                        xml_open},
    {"openURL",                     xml_openURL},
    {"openDTD",                     xml_openDTD},
    {"localNameFor",                xml_localNameFor},
    {"prefixFor",                   xml_prefixFor},
    {"predefinedEntityDeclaration", xml_predefinedEntityDeclaration},
    {NULL,                          NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs__asm_xml_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin sharedWithState:L] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    xml_nodeIOConstants(L) ; lua_setfield(L, -2, "nodeOptions") ;
//     xml_documentIOConstants(L) ; lua_setfield(L, -2, "documentOptions") ;

    [skin registerPushNSHelper:NSXMLNode_toLua           forClass:"NSXMLNode"] ;
    [skin registerLuaObjectHelper:toNSXMLNodeTypeFromLua forClass:"NSXMLNode"
                                              withUserdataMapping:USERDATA_TAG] ;

    return 1;
}
