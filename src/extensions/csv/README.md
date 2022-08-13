# Lua-CSV - delimited file reading

## 1. What?

Lua-CSV is a Lua module for reading delimited text files (popularly CSV and
tab-separated files, but you can specify the separator).

Lua-CSV tries to auto-detect whether a file is delimited with commas or tabs,
copes with non-native newlines, survives newlines and quotes inside quoted
fields and offers an iterator interface so it can handle large files.


## 2. How?

    local csv = require("csv")
    local f = csv.open("file.csv")
    for fields in f:lines() do
      for i, v in ipairs(fields) do print(i, v) end
    end

`csv.open` takes a second argument `parameters`, a table of parameters
controlling how the file is read:

+ `separator` sets the separator.  It'll probably guess the separator
  correctly if it's a comma or a tab (unless, say, the first field in a
  tab-delimited file contains a comma), but if you want something else you'll
  have to set this.  It could be more than one character, but it's used as
  part of a set: `"["..sep.."\n\r]"`

+ Set `header` to true if the file contains a header and each set of fields
  will be keyed by the names in the header rather than by integer index.

+ `columns` provides a mechanism for column remapping.
  Suppose you have a csv file as follows:

        Word,Number
        ONE,10

    And columns is:

    + `{ word = true }` then the only field in the file would be
        `{ word = "ONE" }`
    + `{ first = { name = "word"} }` then it would be `{ first = "ONE" }`
    + `{ word = { transform = string.lower }}` would give `{ word = "one" }`
    + finally,

            { word = true
              number = { transform = function(x) return tonumber(x) / 10 end }}

      would give `{ word = "ONE", number = 1 }`

    A column can have more than one name: 
    `{ first = { names = {"word", "worm"}}}` to help cope with badly specified
    file formats and spelling mistakes.

+ `buffer_size` controls the size of the blocks the file is read in.  The
  default is 1MB.  It used to be 4096 bytes which is what `pagesize` says on
  my system, but that seems kind of small.

`csv.openstring` works exactly like `csv.open` except the first argument
is the contents of the csv file. In this case `buffer_size` is set to
the length of the string.

## 3. Requirements

Lua 5.1, 5.2 or LuaJIT.


## 4. Issues

+ Some whitespace-delimited files might use more than one space between
  fields, for example if the columns are "manually" aligned:

        street           nr  city
        "Oneway Street"   1  Toontown

    It won't cope with this - you'll get lots of extra empty fields.

## 5. Wishlist

+ Tests would be nice.
+ So would better LDoc documentation.


## 6. Alternatives

+ [Penlight](http://github.com/stevedonovan/penlight) contains delimited
  file reading.  It reads the whole file in one go.
+ The Lua Wiki contains two pages on CSV
  [here](http://lua-users.org/wiki/LuaCsv) and
  [here](http://lua-users.org/wiki/CsvUtils).
+ There's an example using [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)
  to parse CSV [here](http://www.inf.puc-rio.br/~roberto/lpeg/#CSV)
