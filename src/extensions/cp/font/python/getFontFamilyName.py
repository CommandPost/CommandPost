#!/usr/bin/python
import sys
from fontTools import ttLib

FONT_SPECIFIER_NAME_ID = 4
FONT_SPECIFIER_FAMILY_ID = 1
def shortName( font ):
	"""Get the short name from the font's names table"""
	name = ""
	family = ""
	for record in font['name'].names:
		if record.nameID == FONT_SPECIFIER_NAME_ID and not name:
			if '\000' in record.string:
				name = unicode(record.string, 'utf-16-be').encode('utf-8')
			else:
				name = record.string
		elif record.nameID == FONT_SPECIFIER_FAMILY_ID and not family:
			if '\000' in record.string:
				family = unicode(record.string, 'utf-16-be').encode('utf-8')
			else:
				family = record.string
		if name and family:
			break
	return name, family


tt = ttLib.TTFont(sys.argv[1], fontNumber=0)
print shortName(tt)[1]