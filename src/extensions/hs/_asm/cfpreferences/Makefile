mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

MODULE := $(current_dir)
PREFIX ?= ~/.hammerspoon
MODPATH = hs/_asm
VERSION ?= 0.x
HS_APPLICATION ?= /Applications

# get from https://github.com/asmagill/hammerspoon-config/blob/master/utils/docmaker.lua
# if you want to generate a readme file similar to the ones I generally use. Adjust the copyright in the file and adjust
# this variable to match where you save docmaker.lua relative to your hammerspoon configuration directory
# (usually ~/.hammerspoon)
MARKDOWNMAKER = utils/docmaker.lua

OBJCFILE = ${wildcard *.m}
LUAFILE  = ${wildcard *.lua}
HEADERS  = ${wildcard *.h}

# swap if all objective-c files should be compiled into one target -- this is necessary if you organize your code in
# multiple files but need them to access functions/objects defined in different files -- each dynamic library is loaded
# individually by Hammerspoon so they can't see the exports of each other directly.
SOFILE  := $(OBJCFILE:.m=.so)
# SOFILE  := internal.so
DEBUG_CFLAGS ?= -g

# special vars for uninstall
space :=
space +=
comma := ,
ALLFILES := $(LUAFILE)
ALLFILES += $(SOFILE)

.SUFFIXES: .m .so

#CC=cc
CC=@clang
WARNINGS ?= -Weverything -Wno-objc-missing-property-synthesis -Wno-implicit-atomic-properties -Wno-direct-ivar-access -Wno-cstring-format-directive -Wno-padded -Wno-covered-switch-default -Wno-missing-prototypes -Werror-implicit-function-declaration
EXTRA_CFLAGS ?= -F$(HS_APPLICATION)/Hammerspoon.app/Contents/Frameworks -mmacosx-version-min=10.10

CFLAGS  += $(DEBUG_CFLAGS) -fmodules -fobjc-arc -DHS_EXTERNAL_MODULE $(WARNINGS) $(EXTRA_CFLAGS)
LDFLAGS += -dynamiclib -undefined dynamic_lookup $(EXTRA_LDFLAGS)

all: verify $(SOFILE)

release: clean all
	HS_APPLICATION=$(HS_APPLICATION) PREFIX=tmp make install ; cd tmp ; tar -cf ../$(MODULE)-v$(VERSION).tar hs ; cd .. ; gzip $(MODULE)-v$(VERSION).tar

releaseWithDocs: clean all docs
	HS_APPLICATION=$(HS_APPLICATION) PREFIX=tmp make install ; cd tmp ; tar -cf ../$(MODULE)-v$(VERSION).tar hs ; cd .. ; gzip $(MODULE)-v$(VERSION).tar

# swap if all objective-c files should be compiled into one target
.m.so: $(HEADERS) $(OBJCFILE)
	$(CC) $< $(CFLAGS) $(LDFLAGS) -o $@

# internal.so: $(HEADERS) $(OBJCFILE)
# 	$(CC) $(OBJCFILE) $(CFLAGS) $(LDFLAGS) -o $@

install: verify install-objc install-lua
	test -f docs.json && install -m 0644 docs.json $(PREFIX)/$(MODPATH)/$(MODULE) || echo "No docs.json file to install"

verify: $(LUAFILE)
	@if $$(hash lua-5.3 >& /dev/null); then (luac-5.3 -p $(LUAFILE) && echo "Lua Compile Verification Passed"); else echo "Skipping Lua Compile Verification"; fi

install-objc: $(SOFILE)
	mkdir -p $(PREFIX)/$(MODPATH)/$(MODULE)
	install -m 0644 $(SOFILE) $(PREFIX)/$(MODPATH)/$(MODULE)
# swap if all objective-c files should be compiled into one target
	cp -vpR $(OBJCFILE:.m=.so.dSYM) $(PREFIX)/$(MODPATH)/$(MODULE)
# 	cp -vpR $(SOFILE:.so=.so.dSYM) $(PREFIX)/$(MODPATH)/$(MODULE)

install-lua: $(LUAFILE)
	mkdir -p $(PREFIX)/$(MODPATH)/$(MODULE)
	install -m 0644 $(LUAFILE) $(PREFIX)/$(MODPATH)/$(MODULE)

docs:
	hs -c "require(\"hs.doc\").builder.genJSON(\"$(dir $(mkfile_path))\")" > docs.json

markdown:
	hs -c "dofile(\"$(MARKDOWNMAKER)\").genMarkdown([[$(dir $(mkfile_path))]])" > README.tmp.md

markdownWithTOC:
	hs -c "dofile(\"$(MARKDOWNMAKER)\").genMarkdown([[$(dir $(mkfile_path))]], true)" > README.tmp.md

clean:
	rm -rf $(SOFILE) *.dSYM tmp docs.json

uninstall:
	rm -v -f $(PREFIX)/$(MODPATH)/$(MODULE)/{$(subst $(space),$(comma),$(ALLFILES))}
# swap if all objective-c files should be compiled into one target
	(pushd $(PREFIX)/$(MODPATH)/$(MODULE)/ ; rm -v -fr $(OBJCFILE:.m=.so.dSYM) ; popd)
# 	(pushd $(PREFIX)/$(MODPATH)/$(MODULE)/ ; rm -v -fr $(SOFILE:.so=.so.dSYM) ; popd)
	rm -v -f $(PREFIX)/$(MODPATH)/$(MODULE)/docs.json
	rmdir -p $(PREFIX)/$(MODPATH)/$(MODULE) ; exit 0

.PHONY: all clean uninstall verify install install-objc install-lua docs markdown markdownWithTOC
