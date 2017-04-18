local fcp	= require("cp.finalcutpro")
local just	= require("cp.just")

function test()
	print "Testing FCP UI elements."
	-- Launch FCP
	fcp:launch()

	-- Reset to the default workspace
	fcp:selectMenu("Window", "Workspaces", "Default")

	-- Test that various UI elements are able to be found.
	assert(fcp:primaryWindow():isShowing(), "Primary Window is not showing")
	assert(fcp:browser():isShowing(), "Browser is not showing")
	assert(fcp:timeline():isShowing(), "Timeline is not showing")
	assert(fcp:inspector():isShowing(), "Inspector is not showing")
	
	-- The Command Editor.
	assert(not fcp:commandEditor():isShowing(), "Command Editor should not be showing")
	fcp:commandEditor():show()
	assert(fcp:commandEditor():isShowing(), "Command Editor is not showing")
	assert(fcp:commandEditor():saveButton():UI() ~= nil, "Command Editor 'Save' button not found")
	fcp:commandEditor():hide()
	assert(not fcp:commandEditor():isShowing(), "Command Editor should not be showing")
	
	-- Export Dialog
	assert(not fcp:exportDialog():isShowing(), "Export Dialog should not be showing")
	fcp:exportDialog():show()
	assert(fcp:exportDialog():isShowing(), "Export Dialog should be showing")
	fcp:exportDialog():hide()
	assert(not fcp:exportDialog():isShowing(), "Export Dialog should have closed")
	
	-- Media Importer
	assert(not fcp:mediaImport():isShowing(), "Media Import should not be showing yet")
	fcp:mediaImport():show()
	assert(fcp:mediaImport():isShowing(), "Media Import should be showing")
	fcp:mediaImport():hide()
	-- The window takes a moment to close sometimes, give it a second.
	just.doWhile(function() return fcp:mediaImport():isShowing() end, 1.0)
	assert(not fcp:mediaImport():isShowing(), "Media Import should not be showing now")
	
	print "All tests passed."
end

return test