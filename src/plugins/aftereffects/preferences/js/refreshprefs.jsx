var path = app.preferences.getPrefAsString('General Section', 'Shortcut File Location', PREFType.PREF_Type_MACHINE_SPECIFIC);
app.preferences.savePrefAsString('General Section', 'Shortcut File Location', path, PREFType.PREF_Type_MACHINE_SPECIFIC);
app.preferences.saveToDisk();
//app.preferences.reload();