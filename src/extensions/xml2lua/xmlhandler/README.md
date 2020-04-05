# XML Handlers
This directory contains a list of handlers used by the XML parser to process a XML producing different results.
There are currently 3 available handlers:

- tree: generates a lua table from an XML content string (the most common used handler).
- print: generates a simple event trace which outputs messages to the terminal during the XML parsing, usually for debugging purposes.
- dom: generates a DOM-like node tree structure with a single ROOT node parent.

# Usage
To get a handler instance you must call, for instance, `handler = require("xmlhandler.tree")`.
Then, you have to use one the handler instance when getting an instance of the XML parser using `parser = xml2lua.parser(handler)`.
Notice the module `xml2lua` should have been loaded before using `require("xml2lua")`.
This way, the handler is called internally when the `parser:parse(xml)` function is called.

Check the documentation on the root directory for complete examples.