# -*- coding: utf-8 -*-
from __future__ import unicode_literals

# Use like this: dmgbuild -s dmg/settings.py

# This can be overridden adding '-D filename=xxxx' to the command line
filename = 'build/FCPXHacks.dmg'

# This can be overridden adding '-D volume_name=xxxx' to the command line
volume_name = 'FCPX Hacks'

# Volume format (see hdiutil create -help)
format = defines.get('format', 'UDBZ')

# Files to include
files = [ 'src/init.lua', 'src/hs' ]

hammerspoon = '~/.hammerspoon'

# Symlinks to create
symlinks = { 'Hammerspoon': hammerspoon, "Applications": "/Applications" }

# Volume icon
#
# You can either define icon, in which case that icon file will be copied to the
# image, *or* you can define badge_icon, in which case the icon file you specify
# will be used to badge the system's Removable Disk icon
#
#icon = '/path/to/icon.icns'
#badge_icon = 'src/hs/fcpx-hacks/assets/fcpxhacks.icns'

# Where to put the icons
icon_locations = {
    'init.lua':     (110, 161),
    'hs':           (220, 161),
    'Hammerspoon':  (430, 161)
    }
    
background = 'dmg/backgroundImage-assets/backgroundImage.png'

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

# Window position in ((x, y), (w, h)) format
window_rect = ((100, 100), (524, 400))

# Select the default view; must be one of
#
#    'icon-view'
#    'list-view'
#    'column-view'
#    'coverflow'
#
default_view = 'icon-view'

# General view configuration
show_icon_preview = False

# Set these to True to force inclusion of icon/list view settings (otherwise
# we only include settings for the default view)
include_icon_view_settings = 'auto'
include_list_view_settings = 'auto'

# .. Icon view configuration ...................................................

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = 'bottom' # or 'right'
text_size = 16
icon_size = 64