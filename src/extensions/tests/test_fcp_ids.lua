local test		= require("cp.test")
local log		= require("hs.logger").new("testfcpids")

local fcp		= require("cp.finalcutpro")
local just		= require("cp.just")

local function reset()
	fcp:launch()
	fcp:selectMenu("Window", "Workspaces", "Default")
end

local function run()
	test("Launch FCP", function()
		-- Launch FCP
		fcp:launch()
		ok(fcp:isRunning(), "FCP is running")
	end)

	test("Check FCP Primary Components", function()
		-- Reset to the default workspace
		reset()

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
		reset()
		
		-- Turn it on and off.
		ok(not fcp:eventViewer():isShowing(), "Event Viewer is initially not showing")
		fcp:eventViewer():showOnPrimary()
		ok(fcp:eventViewer():isShowing(), "Event Viewer displays after showing")
		fcp:eventViewer():hide()
		ok(not fcp:eventViewer():isShowing(), "Event Viewer does not display after hiding")
	end)
	
	test("Command Editor", function()
		reset()
		
		-- The Command Editor.
		ok(not fcp:commandEditor():isShowing(), "Command Editor is not showing")
		fcp:commandEditor():show()
		ok(fcp:commandEditor():isShowing(), "Command Editor is showing")
		ok(fcp:commandEditor():saveButton():UI() ~= nil, "Command Editor 'Save' button found")
		fcp:commandEditor():hide()
		ok(not fcp:commandEditor():isShowing(), "Command Editor is not showing")
	end)
	
	test("Export Dialog", function()
		reset()
		
		-- Export Dialog
		ok(not fcp:exportDialog():isShowing(), "Export Dialog is not showing")
		fcp:exportDialog():show()
		ok(fcp:exportDialog():isShowing(), "Export Dialog is showing")
		fcp:exportDialog():hide()
		ok(not fcp:exportDialog():isShowing(), "Export Dialog is closed")
	end)
	
	test("Media Importer", function()
		reset()
		
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
		reset()
		
		local browser = fcp:effects()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)
	
	test("Transitions Browser", function()
		reset()
		
		local browser = fcp:transitions()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)

	test("Media Browser", function()
		reset()
		
		local browser = fcp:media()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)

	test("Generators Browser", function()
		reset()
		
		local browser = fcp:generators()
		browser:show()
		ok(browser:isShowing())
		ok(browser:sidebar():isShowing())
		ok(browser:contents():isShowing())
		browser:hide()
		ok(not browser:isShowing())
	end)
	
	test("Inspector", function()
		reset()
		
		local inspector = fcp:inspector()
		inspector:show()
		ok(inspector:isShowing())
		inspector:hide()
		ok(not inspector:isShowing())
	end)
	
	test("Libraries Browser", function()
		reset()
		
		-- Show it
		local libraries = fcp:libraries()
		libraries:show()
		
		-- Check UI elements
		ok(libraries:isShowing())
		ok(libraries:toggleViewMode():isShowing())
		ok(libraries:appearanceAndFiltering():isShowing())
		ok(libraries:sidebar():isShowing())
		
		-- Check Filmstrip/List view
		libraries:filmstrip():show()
		ok(libraries:filmstrip():isShowing())
		ok(not libraries:list():isShowing())
		
		libraries:list():show()
		ok(libraries:list():isShowing())
		ok(not libraries:filmstrip():isShowing())
		
		ok(libraries:searchToggle():isShowing())
		-- Show the search field
		if not libraries:search():isShowing() then
			log.df("search hidden; showing now")
			libraries:searchToggle():press()
		end
		-- the UI is delayed sometimes.
		ok(just.doUntil(function() return libraries:search():isShowing() end))
		ok(just.doUntil(function() return libraries:filterToggle():isShowing() end))
		-- turn it back off
		libraries:searchToggle():press()
		-- the UI is delayed sometimes.
		ok(just.doUntil(function() return not libraries:search():isShowing() end))
		ok(just.doUntil(function() return not libraries:filterToggle():isShowing() end))

		-- Check that it hides
		libraries:hide()
		ok(not libraries:isShowing())
		ok(not libraries:toggleViewMode():isShowing())
		ok(not libraries:appearanceAndFiltering():isShowing())
		ok(not libraries:searchToggle():isShowing())
		ok(not libraries:search():isShowing())
		ok(not libraries:filterToggle():isShowing())
	end)
end

return run