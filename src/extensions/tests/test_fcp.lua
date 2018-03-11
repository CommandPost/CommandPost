local log					= require("hs.logger").new("testfcp")

local fs					= require("hs.fs")

local config				= require("cp.config")
local fcp					= require("cp.apple.finalcutpro")
local ids					= require("cp.apple.finalcutpro.ids")
local just					= require("cp.just")
local test					= require("cp.test")
local tools					= require("cp.tools")

local v						= require("semver")

local format				= string.format
local rmdir, mkdir, attributes	= tools.rmdir, fs.mkdir, fs.attributes

local TEST_LIBRARY 			= "Test Library"

local TEST_DIRECTORY 	= fs.temporaryDirectory() .. "CommandPost"
local TEST_LIBRARY_PATH 		= TEST_DIRECTORY .. "/" .. TEST_LIBRARY .. ".fcpbundle"

return test.suite("cp.apple.finalcutpro")
:beforeEach(function() -- do this before each test
    fcp:closeLibrary(TEST_LIBRARY)

    -- Copy Test Library to Temporary Directory:
    local testLibrary = config.scriptPath .. "/tests/fcp/libraries/" .. fcp:getVersion() .. "/" .. TEST_LIBRARY .. ".fcpbundle"

    -- remove any old copies of the library
    if attributes(TEST_DIRECTORY) ~= nil then
    local ok, err = rmdir(TEST_DIRECTORY, true)
    if not ok then
    error(format("Unable to remove the temporary directory: %s", err))
    end
    end
    -- ensure the target directory exists.
    local ok, err = mkdir(TEST_DIRECTORY)
    if not ok then
    error(format("Unable to create the temporary directory: %s", err))
    end

    -- copy the test library to the temporary directory
    local output, status, type, rc = hs.execute([[cp -R "]] .. testLibrary .. [[" "]] .. TEST_DIRECTORY .. [["]])
    if not status then
    error(format("Unable to copy the Test Library to '%s': %s (%s: %s)", TEST_DIRECTORY, output, type, rc))
    end

    -- check it copied ok.
    if not fs.attributes(TEST_LIBRARY_PATH) then
    error(format("Unable to find the Test Library in the copied destination: %s", TEST_LIBRARY_PATH))
    end

    -- give the OS a second to catch up.
    -- just.wait(1)

    fcp:launch()
    just.doUntil(function() return fcp:isRunning() end, 10)
    fcp:selectMenu({"Window", "Workspaces", "Default"})

    if not fcp:openLibrary(TEST_LIBRARY_PATH) then
    error(format("Unable to open the Test Library: %s", TEST_LIBRARY_PATH))
    end

    -- keep trying until the library loads successfully, waiting up to 5 seconds.
    just.doUntil(function() return fcp:libraries():selectLibrary(TEST_LIBRARY) ~= nil end, 5.0)

    if not just.doUntil(function() return fcp:libraries():openClipTitled("Test Project") end, 10) then
    error(format("Unable to open the 'Test Project' clip."))
    end
end)
:afterEach(function() -- do this after each test.
    fcp:closeLibrary(TEST_LIBRARY)
    -- delete the temporary library copy.
    local ok, err = rmdir(TEST_DIRECTORY, true)
    if not ok then
    error(format("Unable to remove the temporary directory: %s", err))
    end
end)
:with(
    test("Launch FCP", function()
    -- Launch FCP
    fcp:launch()
    ok(fcp:isRunning(), "FCP is running")
    end),

    test("Check FCP Primary Components", function()
    -- Test that various UI elements are able to be found.
    ok(fcp:primaryWindow():isShowing())
    ok(fcp:browser():isShowing())
    ok(fcp:timeline():isShowing())
    ok(fcp:inspector():isShowing())
    ok(fcp:viewer():isShowing())
    ok(not fcp:eventViewer():isShowing())
    end),

    test("Check Event Viewer", function()
    -- Turn it on and off.
    ok(not fcp:eventViewer():isShowing())
    fcp:eventViewer():showOnPrimary()
    ok(fcp:eventViewer():isShowing())
    fcp:eventViewer():hide()
    ok(not fcp:eventViewer():isShowing())
    end),

    test("Command Editor", function()
    -- The Command Editor.
    ok(not fcp:commandEditor():isShowing())
    fcp:commandEditor():show()
    ok(fcp:commandEditor():isShowing())
    ok(fcp:commandEditor():saveButton():UI() ~= nil)
    fcp:commandEditor():hide()
    ok(not fcp:commandEditor():isShowing())
    end),

    test("Export Dialog", function()
    -- Need to close and re-open the library so that all media is linked correctly.
    -- just.wait(1)
    -- fcp:closeLibrary(TEST_LIBRARY)
    -- -- just.wait(5)
    -- fcp:openLibrary(TEST_LIBRARY_PATH)

    -- Export Dialog
    ok(not fcp:exportDialog():isShowing())
    fcp:exportDialog():show()

    -- There may be a 'Missing media' alert, due to a bug(?) in FCPX where media from the library is missing the first load.
    if fcp:alert():isShowing() then
    local message = fcp:string("FFMissingMediaMessageText"):gsub("%%@", ".*")
    if fcp:alert():containsText(message) then
    fcp:alert():default():press()
    else
    ok(false, "Unexpected Alert displayed while opening the Export Dialog.")
    fcp:alert():hide()
    end
    end

    ok(fcp:exportDialog():isShowing())
    fcp:exportDialog():hide()
    ok(not fcp:exportDialog():isShowing())
    end),

    test("Media Importer", function()
    -- Media Importer
    ok(not fcp:mediaImport():isShowing())
    fcp:mediaImport():show()
    ok(fcp:mediaImport():isShowing())
    fcp:mediaImport():hide()
    -- The window takes a moment to close sometimes, give it a second.
    just.doWhile(function() return fcp:mediaImport():isShowing() end, 1.0)
    ok(not fcp:mediaImport():isShowing())
    end),

    test("Effects Browser", function()
    local browser = fcp:effects()
    browser:show()
    ok(browser:isShowing())
    ok(browser:sidebar():isShowing())
    ok(browser:contents():isShowing())
    browser:hide()
    ok(not browser:isShowing())
    end),

    test("Transitions Browser", function()
    local browser = fcp:transitions()
    browser:show()
    ok(browser:isShowing())
    ok(browser:sidebar():isShowing())
    ok(browser:contents():isShowing())
    browser:hide()
    ok(not browser:isShowing())
    end),

    test("Media Browser", function()
    local browser = fcp:media()
    browser:show()
    ok(browser:isShowing())
    ok(browser:sidebar():isShowing())
    browser:hide()
    ok(not browser:isShowing())
    end),

    test("Generators Browser", function()
    local browser = fcp:generators()
    browser:show()
    ok(browser:isShowing())
    ok(browser:sidebar():isShowing())
    ok(browser:contents():isShowing())
    browser:hide()
    ok(not browser:isShowing())
    end),

    test("Inspector", function()
    local inspector = fcp:inspector()
    inspector:show()
    just.doUntil(function() return inspector:isShowing() end, 1)
    ok(inspector:isShowing())
    inspector:hide()
    ok(not inspector:isShowing())
    end),

    test("Color Inspector", function()
    local color = fcp:inspector():color()
    color:show()
    just.doUntil(function() return color:isShowing() end, 1)
    ok(color:isShowing())
    ok(color:corrections():isShowing())

    color:hide()
    ok(not color:isShowing())
    end),

    test("Color Board", function()
    local tc = fcp:timeline():contents()
    -- get the set of clips (expand secondary storylines)
    local clips = tc:clipsUI(true)
    if #clips < 1 then
    error("Unable to find any clips to adjust color for.")
    end
    -- select the first clip.
    tc:selectClip(clips[1])

    local colorBoard = fcp:colorBoard()
    colorBoard:show()
    just.doUntil(function() return colorBoard:isShowing() end, 5)
    ok(colorBoard:isShowing())

    local testPuck = function(puck, hasAngle)
    -- check the pucks
    ok(puck:select():isShowing())
    ok(eq(puck:percent(15), 15), puck)
    ok(eq(puck:percent(), 15), puck)
    ok(eq(puck:percent(100), 100), puck)
    ok(eq(puck:percent(101), 100), puck)
    ok(eq(puck:percent(0), 0), puck)
    ok(eq(puck:percent(-101), -100), puck)
    ok(eq(puck:percent("50"), 50), puck)

    if hasAngle then
    -- in 10.4+ the color board now cycles through the angle back to 0 after it hits 360, and vice versa for negative angles.
    local cycleAngle = v(fcp:getVersion()) >= v("10.4")

    ok(eq(puck:angle(100), 100), puck)
    ok(eq(puck:angle(359), 359), puck)
    ok(eq(puck:angle(360), cycleAngle and 0 or 360), puck)
    ok(eq(puck:angle(0), 0), puck)
    ok(eq(puck:angle(-1), cycleAngle and 359 or 0), puck)
    end
    end

    local allAspects = {colorBoard:color(), colorBoard:saturation(), colorBoard:exposure()}

    local testAspect = function(aspect, hasAngle)
    aspect:show()

    for _,otherAspect in ipairs(allAspects) do
    ok(eq(otherAspect:isShowing(), aspect:index() == otherAspect:index()), string.format("Comparing '%s' to '%s' has an unexpected 'isShowing' status: %s", otherAspect:id(), aspect:id(), aspect:isShowing()))
    end

    -- check the pucks
    testPuck(aspect:master(), hasAngle)
    testPuck(aspect:shadows(), hasAngle)
    testPuck(aspect:midtones(), hasAngle)
    testPuck(aspect:highlights(), hasAngle)
    end

    -- check at full height
    fcp:inspector():isFullHeight(true)
    testAspect(colorBoard:color(), true)
    testAspect(colorBoard:saturation(), false)
    testAspect(colorBoard:exposure(), false)

    -- and half-height (in some versions of FCP, puck property rows are hidden unless selected.)
    -- fcp:inspector():isFullHeight(false)
    -- testAspect(colorBoard:color(), true)
    -- testAspect(colorBoard:saturation(), false)
    -- testAspect(colorBoard:exposure(), false)

    end),

    test("Libraries Browser", function()
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
    if not libraries:search():isShowing() or not libraries:filterToggle():isShowing() then
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
    end),

    test("Libraries Filmstrip", function()
    local libraries = fcp:libraries()

    -- Check Filmstrip/List view
    libraries:filmstrip():show()
    ok(libraries:filmstrip():isShowing())
    ok(not libraries:list():isShowing())
    end),

    test("Libraries List", function()
    local libraries = fcp:libraries()
    local list		= libraries:list()

    list:show()
    ok(list:isShowing())
    ok(not libraries:filmstrip():isShowing())

    -- Check the sub-components are available.
    ok(list:playerUI() ~= nil)
    ok(list:contents():isShowing())
    ok(list:clipsUI() ~= nil)
    end),

    test("Timeline", function()
    local timeline = fcp:timeline()

    ok(timeline:isShowing())
    timeline:hide()
    ok(not timeline:isShowing())
    end),

    test("Timeline Appearance", function()
    local appearance = fcp:timeline():toolbar():appearance()

    ok(appearance:toggle():isShowing())
    ok(not appearance:isShowing())
    ok(not appearance:clipHeight():isShowing())

    appearance:show()
    ok(just.doUntil(function() return appearance:isShowing() end))
    ok(appearance:clipHeight():isShowing())

    appearance:hide()
    ok(not appearance:isShowing())
    ok(not appearance:clipHeight():isShowing())
    end),

    test("Timeline Contents", function()
    local contents = fcp:timeline():contents()

    ok(contents:isShowing())
    ok(contents:scrollAreaUI() ~= nil)
    end),

    test("Timeline Toolbar", function()
    local toolbar = fcp:timeline():toolbar()

    ok(toolbar:isShowing())
    ok(toolbar:skimmingGroupUI() ~= nil)
    ok(toolbar:skimmingGroupUI():attributeValue("AXIdentifier") == ids "TimelineToolbar" "SkimmingGroup")

    ok(toolbar:effectsGroupUI() ~= nil)
    ok(toolbar:effectsGroupUI():attributeValue("AXIdentifier") == ids "TimelineToolbar" "EffectsGroup")

    end),

    test("Viewer", function()
    local viewer = fcp:viewer()

    ok(viewer:isShowing())
    ok(viewer:topToolbarUI() ~= nil)
    ok(viewer:bottomToolbarUI() ~= nil)
    ok(viewer:formatUI() ~= nil)
    ok(viewer:framerate() ~= nil)
    ok(viewer:title() ~= nil)
    end),

    test("PreferencesWindow", function()
    local prefs = fcp:preferencesWindow()

    prefs:show()
    ok(prefs:isShowing())

    prefs:hide()
    ok(not prefs:isShowing())
    end),

    test("ImportPanel", function()
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
    ok(panel:copyToMediaFolder():checked() or panel:leaveInPlace():checked())

    panel:hide()
    end),

    test("PlaybackPanel", function()
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
    end)
)
-- custom run function, that loops through all languages (or languages provided)
:onRun(function(self, runTests, languages, ...)
    local wasRunning = fcp:isRunning()

    -- Figure out which languages to test
    if type(languages) == "table" then
    languages = languages and #languages > 0 and languages
    elseif type(languages) == "string" then
    languages = { languages }
    elseif languages == nil or languages == true then
    languages = fcp:getSupportedLanguages()
    else
    error(string.format("Unsupported 'languages' filter: %s", languages))
    end

    -- Store the current language:
    local originalLanguage = fcp:currentLanguage()
    local originalName = self.name

    for _,lang in ipairs(languages) do
    -- log.df("Testing FCPX in the '%s' language...", lang)
    self.name = originalName .. " > " .. lang
    if fcp:currentLanguage(lang) then
    just.wait(2)
    fcp:launch()
    just.doUntil(fcp.isRunning)

    -- run the actual tests
    runTests(self, ...)
    else
    log.ef("Unable to set FCPX to use the '%s' language.", lang)
    end
    end

    -- Reset to the current language
    if not wasRunning then
    fcp:quit()
    end
    fcp:currentLanguage(originalLanguage)
    self.name = originalName

end)