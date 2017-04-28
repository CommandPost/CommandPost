local test		= require("cp.test")
local log		= require("hs.logger").new("testfcpids")

local fcp		= require("cp.apple.finalcutpro")
local ids		= require("cp.apple.finalcutpro.ids")
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
		ok(fcp:primaryWindow():isShowing())
		ok(fcp:browser():isShowing())
		ok(fcp:timeline():isShowing())
		ok(fcp:inspector():isShowing())
		ok(fcp:viewer():isShowing())
		ok(not fcp:eventViewer():isShowing())
	end)
	
	test("Check Event Viewer", function()
		-- Reset to default workspace
		reset()
		
		-- Turn it on and off.
		ok(not fcp:eventViewer():isShowing())
		fcp:eventViewer():showOnPrimary()
		ok(fcp:eventViewer():isShowing())
		fcp:eventViewer():hide()
		ok(not fcp:eventViewer():isShowing())
	end)
	
	test("Command Editor", function()
		reset()
		
		-- The Command Editor.
		ok(not fcp:commandEditor():isShowing())
		fcp:commandEditor():show()
		ok(fcp:commandEditor():isShowing())
		ok(fcp:commandEditor():saveButton():UI() ~= nil)
		fcp:commandEditor():hide()
		ok(not fcp:commandEditor():isShowing())
	end)
	
	test("Export Dialog", function()
		reset()
		
		-- Export Dialog
		ok(not fcp:exportDialog():isShowing())
		fcp:exportDialog():show()
		ok(fcp:exportDialog():isShowing())
		fcp:exportDialog():hide()
		ok(not fcp:exportDialog():isShowing())
	end)
	
	test("Media Importer", function()
		reset()
		
		-- Media Importer
		ok(not fcp:mediaImport():isShowing())
		fcp:mediaImport():show()
		ok(fcp:mediaImport():isShowing())
		fcp:mediaImport():hide()
		-- The window takes a moment to close sometimes, give it a second.
		just.doWhile(function() return fcp:mediaImport():isShowing() end, 1.0)
		ok(not fcp:mediaImport():isShowing())
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
				
		-- Check the search UI
		ok(libraries:searchToggle():isShowing())
		-- Show the search field if necessary
		if not libraries:search():isShowing() then
			libraries:searchToggle():press()
		end
		ok(libraries:search():isShowing())
		ok(libraries:filterToggle():isShowing())
		-- turn it back off
		libraries:searchToggle():press()
		ok(not libraries:search():isShowing())
		ok(not libraries:filterToggle():isShowing())

		-- Check that it hides
		libraries:hide()
		ok(not libraries:isShowing())
		ok(not libraries:toggleViewMode():isShowing())
		ok(not libraries:appearanceAndFiltering():isShowing())
		ok(not libraries:searchToggle():isShowing())
		ok(not libraries:search():isShowing())
		ok(not libraries:filterToggle():isShowing())
	end)
	
	test("Libraries Filmstrip", function()
		reset()
		local libraries = fcp:libraries()
	
		-- Check Filmstrip/List view
		libraries:filmstrip():show()
		ok(libraries:filmstrip():isShowing())
		ok(not libraries:list():isShowing())
	end)
	
	test("Libraries List", function()
		reset()
		local libraries = fcp:libraries()
		local list		= libraries:list()
		
		list:show()
		ok(list:isShowing())
		ok(not libraries:filmstrip():isShowing())
		
		-- Check the sub-components are available.
		ok(list:playerUI() ~= nil)
		ok(list:contents():isShowing())
		ok(list:clipsUI() ~= nil)
	end)
	
	test("Timeline", function()
		reset()
		local timeline = fcp:timeline()
		
		ok(timeline:isShowing())
		timeline:hide()
		ok(not timeline:isShowing())
	end)
	
	test("Timeline Appearance", function()
		reset()
		local appearance = fcp:timeline():toolbar():appearance()
		
		ok(appearance:toggle():isShowing())
		ok(not appearance:isShowing())
		ok(not appearance:clipHeight():isShowing())
		
		appearance:show()
		ok(appearance:isShowing())
		ok(appearance:clipHeight():isShowing())
		
		appearance:hide()
		ok(not appearance:isShowing())
		ok(not appearance:clipHeight():isShowing())
	end)
	
	test("Timeline Contents", function()
		reset()
		local contents = fcp:timeline():contents()
		
		ok(contents:isShowing())
		ok(contents:scrollAreaUI() ~= nil)
	end)
	
	test("Timeline Toolbar", function()
		reset()
		local toolbar = fcp:timeline():toolbar()
		
		ok(toolbar:isShowing())
		ok(toolbar:skimmingGroupUI() ~= nil)
		ok(toolbar:skimmingGroupUI():attributeValue("AXIdentifier") == ids "TimelineToolbar" "SkimmingGroup")
		
		ok(toolbar:effectsGroupUI() ~= nil)
		ok(toolbar:effectsGroupUI():attributeValue("AXIdentifier") == ids "TimelineToolbar" "EffectsGroup")
		
	end)
	
	test("Viewer", function()
		reset()
		local viewer = fcp:viewer()
		
		ok(viewer:isShowing())
		ok(viewer:topToolbarUI() ~= nil)
		ok(viewer:bottomToolbarUI() ~= nil)
		ok(viewer:formatUI() ~= nil)
		ok(viewer:getFramerate() ~= nil)
		ok(viewer:getTitle() ~= nil)
	end)
	
	test("PreferencesWindow", function()
		reset()
		local prefs = fcp:preferencesWindow()
		
		prefs:show()
		ok(prefs:isShowing())
		
		prefs:hide()
		ok(not prefs:isShowing())
	end)
	
	test("ImportPanel", function()
		reset()
		local panel = fcp:preferencesWindow():importPanel()
		
		-- Make sure the preferences window is hidden
		fcp:preferencesWindow():hide()
		ok(not panel:isShowing())
		
		-- Show the import preferences panel
		panel:show()
		ok(panel:isShowing())
		ok(panel:createProxyMedia():isShowing())
		ok(panel:createOptimizedMedia():isShowing())
		ok(panel:copyToMediaFolder():isShowing())
		ok(panel:leaveInPlace():isShowing())
		ok(panel:copyToMediaFolder():isChecked() or panel:leaveInPlace():isChecked())
		
		panel:hide()
		ok(not panel:isShowing())
	end)
	
	test("PlaybackPanel", function()
		reset()
		local panel = fcp:preferencesWindow():playbackPanel()
		
		-- Make sure the preferences window is hidden
		fcp:preferencesWindow():hide()
		ok(not panel:isShowing())
		
		-- Show the import preferences panel
		panel:show()
		ok(panel:isShowing())
		ok(panel:createMulticamOptimizedMedia():isShowing())
		ok(panel:backgroundRender():isShowing())
		
		panel:hide()
		ok(not panel:isShowing())
	end)
end

return run