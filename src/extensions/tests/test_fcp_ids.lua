local test		= require("cp.test")

local fcp		= require("cp.finalcutpro")
local just		= require("cp.just")

function run()
	test("Launch FCP", function()
		-- Launch FCP
		fcp:launch()
		ok(fcp:isRunning(), "FCP is running")
	end)

	test("Check FCP Primary Components", function()
		-- Reset to the default workspace
		fcp:selectMenu("Window", "Workspaces", "Default")

		-- Test that various UI elements are able to be found.
		ok(fcp:primaryWindow():isShowing(), "Primary Window not showing")
		ok(fcp:browser():isShowing(), "Browser is showing")
		ok(fcp:timeline():isShowing(), "Timeline is showing")
		ok(fcp:inspector():isShowing(), "Inspector is showing")
		ok(fcp:viewer():isShowing(), "Viewer is showing")
		ok(not fcp:eventViewer():isShowing(), "Event Viewer is not showing")
	end)
	
	test("Check Event Viewer", function()
		-- Reset to default workspace
		fcp:selectMenu("Window", "Workspaces", "Default")
		-- Turn it on and off.
		ok(not fcp:eventViewer():isShowing(), "Event Viewer is initially not showing")
		fcp:eventViewer():showOnPrimary()
		ok(fcp:eventViewer():isShowing(), "Event Viewer displays after showing")
		fcp:eventViewer():hide()
		ok(not fcp:eventViewer():isShowing(), "Event Viewer does not display after hiding")
	end)
	
	test("Command Editor", function()
		-- The Command Editor.
		ok(not fcp:commandEditor():isShowing(), "Command Editor is not showing")
		fcp:commandEditor():show()
		ok(fcp:commandEditor():isShowing(), "Command Editor is showing")
		ok(fcp:commandEditor():saveButton():UI() ~= nil, "Command Editor 'Save' button found")
		fcp:commandEditor():hide()
		ok(not fcp:commandEditor():isShowing(), "Command Editor is not showing")
	end)
	
	test("Export Dialog", function()
		-- Export Dialog
		ok(not fcp:exportDialog():isShowing(), "Export Dialog is not showing")
		fcp:exportDialog():show()
		ok(fcp:exportDialog():isShowing(), "Export Dialog is showing")
		fcp:exportDialog():hide()
		ok(not fcp:exportDialog():isShowing(), "Export Dialog is closed")
	end)
	
	test("Media Importer", function()
		-- Media Importer
		ok(not fcp:mediaImport():isShowing(), "Media Import should not be showing yet")
		fcp:mediaImport():show()
		ok(fcp:mediaImport():isShowing(), "Media Import should be showing")
		fcp:mediaImport():hide()
		-- The window takes a moment to close sometimes, give it a second.
		just.doWhile(function() return fcp:mediaImport():isShowing() end, 1.0)
		ok(not fcp:mediaImport():isShowing(), "Media Import should not be showing now")
	end)
	
	test("Effects Browser", function()
		local browser = fcp:effects()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)
	
	test("Transitions Browser", function()
		local browser = fcp:transitions()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)

	test("Media Browser", function()
		local browser = fcp:media()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)

	test("Generators Browser", function()
		local browser = fcp:generators()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)
	
end

return run