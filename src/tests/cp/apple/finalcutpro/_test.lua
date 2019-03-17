-- test cases for the FCP API
-- By default, this will run all test cases across all supported locales in Final Cut Pro:
--
-- ```lua
-- _test("cp.apple.finalcutpro")()
-- ```
--
-- You can also trigger a specific version of Final Cut Pro by supplying it's path:
--
-- ```lua
-- _test("cp.apple.finalcutpro")({"de", "es"}, "/Applications/Final Cut Pro 10.3.4", "Launch FCP", "Command Editor")
-- ```
--
-- If you want to just run a specific test against a specific locale, you can do this:
--
-- ```lua
-- _test("cp.apple.finalcutpro")("en", nil, "Launch FCP")
-- ```
--
-- You can run multiple specific locales like so:
--
-- ```lua
-- _test("cp.apple.finalcutpro")({"de", "es"}, nil, "Launch FCP", "Command Editor")
-- ```

local require = require

local log           = require("hs.logger").new("testfcp")
local inspect       = require("hs.inspect")

local application   = require("hs.application")
local fs            = require("hs.fs")
local timer         = require("hs.timer")

local config        = require("cp.config")
local fcp           = require("cp.apple.finalcutpro")
local just          = require("cp.just")
local localeID      = require("cp.i18n.localeID")
local test          = require("cp.test")
local tools         = require("cp.tools")

local v             = require("semver")

local doAfter       = timer.doAfter
local format        = string.format

local rmdir, mkdir, attributes = tools.rmdir, fs.mkdir, fs.attributes

local TEST_LIBRARY = "Test Library"

local TEST_DIRECTORY = fs.temporaryDirectory() .. "CommandPost"

local libraryCount = 0

local APP_PATH

return test.suite("cp.apple.finalcutpro"):with(
    test(
        "Launch FCP",
        function()
            -- Launch FCP
            if APP_PATH then
                fcp:launch(nil, APP_PATH)
            else
                fcp:launch()
            end
            ok(fcp:isRunning(), "FCP is running")
        end
    ),
    test(
        "Check FCP Primary Components",
        function()
            -- Test that various UI elements are able to be found.
            ok(fcp:primaryWindow():isShowing())
            ok(fcp:browser():isShowing())
            ok(fcp:timeline():isShowing())
            ok(fcp:inspector():isShowing())
            ok(fcp:viewer():isShowing())
            ok(not fcp:eventViewer():isShowing())
        end
    ),
    test(
        "Viewer",
        function()
            local viewer = fcp:viewer()

            ok(viewer:isShowing())
            ok(viewer:topToolbarUI() ~= nil)
            ok(viewer:bottomToolbarUI() ~= nil)
            ok(viewer:formatUI() ~= nil)
            ok(viewer:framerate() ~= nil)
            ok(viewer:title() ~= nil)

            ok(eq(viewer:timecode("0"), "00:00:00:00"))
            ok(eq(viewer:timecode("0:12"), "00:00:00:12"))
        end
    ),
    test(
        "Event Viewer",
        function()
            -- Turn it on and off.
            ok(not fcp:eventViewer():isShowing())
            fcp:eventViewer():showOnPrimary()
            ok(fcp:eventViewer():isShowing())
            fcp:eventViewer():hide()
            ok(not fcp:eventViewer():isShowing())
        end
    ),
    test("Viewer Quality", function()
        local viewer = fcp:viewer()

        ok(viewer:isShowing())
        viewer:usingProxies(true)
        ok(eq(viewer:usingProxies(), true))
        ok(eq(viewer:betterQuality(), false))

        viewer:usingProxies(false)
        -- it can take a moment for the preference to sync.
        ok(eq(just.doUntil(viewer.usingProxies, 2, 0.01), false))
        ok(eq(viewer:betterQuality(), false))

        viewer:betterQuality(true)
        -- it can take a moment for the preference to sync.
        ok(eq(just.doUntil(viewer.betterQuality, 2, 0.01), true))
        ok(eq(viewer:usingProxies(), false))

        viewer:betterQuality(false)
        -- it can take a moment for the preference to sync.
        ok(eq(just.doUntil(viewer.betterQuality, 2, 0.01), false))
        ok(eq(viewer:usingProxies(), false))
    end),
    test(
        "Command Editor",
        function()
            -- The Command Editor.
            ok(not fcp:commandEditor():isShowing())
            fcp:commandEditor():show()
            ok(fcp:commandEditor():isShowing())
            ok(fcp:commandEditor():saveButton():UI() ~= nil)
            fcp:commandEditor():hide()
            ok(not fcp:commandEditor():isShowing())
        end
    ),
    test(
        "Export Dialog",
        function()
            local _, err
            local export = fcp:exportDialog()
            -- Export Dialog
            ok(not export:isShowing())
            export:show(1, true, true, true)

            ok(export:isShowing())
            export:hide()
            ok(not export:isShowing())

            -- switch to viewer > proxy mode, which has an additional warning message
            fcp:viewer():usingProxies(true)
            _, err = export:show(1, true, true, true, true)
            ok(err == nil)
            ok(export:isShowing())
            export:hide()
            ok(not export:isShowing())

            -- fail on proxies this time, quietly
            _, err = export:show(1, false, true, true, true)
            ok(err ~= nil)
            ok(eq(export:isShowing(), false))
            ok(eq(fcp:alert():isShowing(), false))

            -- reset proxies mode
            fcp:viewer():usingProxies(false)
        end
    ),
    test(
        "Media Importer",
        function()
            -- Media Importer
            ok(not fcp:mediaImport():isShowing())
            fcp:mediaImport():show()
            ok(fcp:mediaImport():isShowing())
            fcp:mediaImport():hide()
            -- The window takes a moment to close sometimes, give it a second.
            just.doWhile(
                function()
                    return fcp:mediaImport():isShowing()
                end,
                1.0
            )
            ok(not fcp:mediaImport():isShowing())
        end
    ),
    test(
        "Effects Browser",
        function()
            local browser = fcp:effects()
            browser:show()
            ok(browser:isShowing())
            ok(browser:sidebar():isShowing())
            ok(browser:contents():isShowing())
            browser:hide()
            ok(not browser:isShowing())
        end
    ),
    test(
        "Transitions Browser",
        function()
            local browser = fcp:transitions()
            browser:show()
            ok(browser:isShowing())
            ok(browser:sidebar():isShowing())
            ok(browser:contents():isShowing())
            browser:hide()
            ok(not browser:isShowing())
        end
    ),
    test(
        "Media Browser",
        function()
            local browser = fcp:media()
            browser:show()
            ok(browser:isShowing())
            ok(browser:sidebar():isShowing())
            browser:hide()
            ok(not browser:isShowing())
        end
    ),
    test(
        "Generators Browser",
        function()
            local browser = fcp:generators()
            browser:show()
            ok(browser:isShowing())
            ok(browser:sidebar():isShowing())
            ok(browser:contents():isShowing())
            browser:hide()
            ok(not browser:isShowing())
        end
    ),
    test(
        "Inspector",
        function()
            local inspector = fcp:inspector()
            inspector:show()
            just.doUntil(
                function()
                    return inspector:isShowing()
                end,
                1
            )
            ok(inspector:isShowing())
            inspector:hide()
            ok(not inspector:isShowing())
        end
    ),
    test(
        "Color Inspector",
        function()
            local tc = fcp:timeline():contents()
            -- get the set of clips (expand secondary storylines)
            local clips = tc:clipsUI(true)
            if #clips < 1 then
                error("Unable to find any clips to adjust color for.")
            end
            -- select the first clip.
            tc:selectClip(clips[1])

            local color = fcp:inspector():color()
            color:show()
            just.doUntil(function() return color:isShowing() end, 1)
            ok(color:isShowing())
            ok(color:corrections():isShowing())

            color:hide()
            ok(not color:isShowing())
        end
    ),
    test(
        "Color Inspector Corrections Selector",
        function()
            local tc = fcp:timeline():contents()
            -- get the set of clips (expand secondary storylines)
            local clips = tc:clipsUI(true)
            if #clips < 1 then
                error("Unable to find any clips to adjust color for.")
            end
            -- select the first clip.
            tc:selectClip(clips[1])

            -- activate the colour inspector
            local color = fcp:inspector():color()
            local corrections = color:corrections()
            corrections:show()

            ok(eq(corrections:activate("Color Board"), true))
            ok(eq(color:colorBoard():isShowing(), true))

            ok(eq(corrections:activate("Color Wheels"), true))
            ok(eq(color:colorWheels():isShowing(), true))
        end
    ),
    test(
        "Color Board",
        function()
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
            just.doUntil(function()return colorBoard:isShowing()end, 5)
            ok(colorBoard:isShowing())

            local testPuck = function(puck, hasAngle)
                -- check the pucks
                ok(eq(puck:select():isShowing(),true))
                ok(eq(puck:percent(15), 15), puck)
                ok(eq(puck:percent(), 15), puck)
                ok(eq(puck:percent(100), 100), puck)
                ok(eq(puck:percent(101), 100), puck)
                ok(eq(puck:percent(0), 0), puck)
                ok(eq(puck:percent(-101), -100), puck)
                ok(eq(puck:percent("50"), 50), puck)

                if hasAngle then
                    -- in 10.4+ the color board now cycles through the angle back to 0 after it hits 360, and vice versa for negative angles.
                    local cycleAngle = fcp:version() >= v("10.4")

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

                for _, otherAspect in ipairs(allAspects) do
                    ok(
                        eq(otherAspect:isShowing(), aspect:index() == otherAspect:index()),
                        string.format(
                            "Comparing '%s' to '%s' has an unexpected 'isShowing' status: %s",
                            otherAspect:id(),
                            aspect:id(),
                            aspect:isShowing()
                        )
                    )
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
        end
    ),
    test(
        "Libraries Browser",
        function()
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
        end
    ),
    test(
        "Libraries Filmstrip",
        function()
            local libraries = fcp:libraries()

            -- Check Filmstrip/List view
            libraries:filmstrip():show()
            ok(libraries:filmstrip():isShowing())
            ok(not libraries:list():isShowing())
        end
    ),
    test(
        "Libraries List",
        function()
            local libraries = fcp:libraries()
            local list = libraries:list()

            list:show()
            ok(list:isShowing())
            ok(not libraries:filmstrip():isShowing())

            -- Check the sub-components are available.
            ok(list:playerUI() ~= nil)
            ok(list:contents():isShowing())
            ok(list:clipsUI() ~= nil)
        end
    ),
    test(
        "Timeline",
        function()
            local timeline = fcp:timeline()

            ok(timeline:isShowing())
            timeline:hide()
            ok(not timeline:isShowing())
        end
    ),
    test(
        "Timeline Appearance",
        function()
            local appearance = fcp:timeline():toolbar():appearance()

            ok(appearance:toggle():isShowing())
            ok(not appearance:isShowing())
            ok(not appearance:clipHeight():isShowing())

            appearance:show()
            ok(
                just.doUntil(
                    function()
                        return appearance:isShowing()
                    end
                )
            )
            ok(appearance:clipHeight():isShowing())

            appearance:hide()
            ok(not appearance:isShowing())
            ok(not appearance:clipHeight():isShowing())
        end
    ),
    test(
        "Timeline Contents",
        function()
            local contents = fcp:timeline():contents()

            ok(contents:isShowing())
            ok(contents:scrollAreaUI() ~= nil)
        end
    ),
    test(
        "Timeline Toolbar",
        function()
            local toolbar = fcp:timeline():toolbar()

            local skimmingId, effectsGroup
            local version = fcp.version()

            ok(version and type(version) == "table")

            if version >= v("10.3.2") then
                skimmingId = "_NS:178"
                effectsGroup = "_NS:165"
            end

            if version >= v("10.3.3") then
                skimmingId = "_NS:179"
                effectsGroup = "_NS:166"
            end

            if version >= v("10.4.4") then
                skimmingId = "_NS:183"
                effectsGroup = "_NS:170"
            end

            ok(toolbar:isShowing())
            ok(toolbar:skimming():UI() ~= nil)
            ok(skimmingId and toolbar:skimming():UI():attributeValue("AXIdentifier") == skimmingId)

            ok(toolbar:effectsGroup():UI() ~= nil)
            ok(effectsGroup and toolbar:effectsGroup():UI():attributeValue("AXIdentifier") == effectsGroup)
        end
    ),
    test(
        "PreferencesWindow",
        function()
            local prefs = fcp:preferencesWindow()

            prefs:show()
            ok(prefs:isShowing())

            prefs:hide()
            ok(not prefs:isShowing())
        end
    ),
    test(
        "ImportPanel",
        function()
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
        end
    ),
    test(
        "PlaybackPanel",
        function()
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
        end
    )
):
onRun(
    -- custom run function, that loops through all locales (or locales provided)
    function(self, runTests, locales, path, ...)
        local wasRunning = fcp:isRunning()

        if path then
            if tools.doesDirectoryExist(path .. ".app") then
                log.df("Using specific Final Cut Pro path: %s", path)
                APP_PATH = path
            else
                error(string.format("Invalid application path: %s", path))
            end
        end

        -- Figure out which locales to test
        if type(locales) == "table" then
            locales = locales and #locales > 0 and locales
            for i=1,#locales do
                locales[i] = localeID(locales[i])
            end
        elseif type(locales) == "string" then
            locales = {localeID(locales)}
        elseif locales == nil or locales == true then
            locales = fcp.app:supportedLocales()
        else
            error(string.format("Unsupported 'locales' filter: %s", inspect(locales)))
        end

        -- remove any old copies of the library
        if attributes(TEST_DIRECTORY) ~= nil then
            local ok, err = rmdir(TEST_DIRECTORY, true)
            if not ok then
                error(format("Unable to remove the temporary directory: %s", err))
            end
        end

        -- set up the fresh test directory.
        if fs.pathToAbsolute(TEST_DIRECTORY) == nil then
            local ok, err = mkdir(TEST_DIRECTORY)
            if not ok then
                error(format("Unable to create '%s' directory: %s", TEST_DIRECTORY, err))
            end
        end

        -- Store the current locale:
        local originalLocale = fcp.app:currentLocale()
        local originalName = self.name

        for _, locale in ipairs(locales) do
            -- log.df("Testing FCPX in the '%s' language...", locale)
            self.name = originalName .. " > " .. locale.code
            if fcp.app:currentLocale(locale) then
                just.doUntil(fcp.isRunning, 10)

                -- run the actual tests
                runTests(self, ...)
            else
                log.ef("Unable to set FCPX to use the '%s' language.", locale.code)
            end
        end

        -- Reset to the current language
        if not wasRunning then
            fcp:quit()
        end
        fcp:currentLocale(originalLocale)
        self.name = originalName
    end
):beforeEach(
    function(testcase)
        local ok, err

        local targetLibrary = "Test - " .. testcase.name

        -- create the target directory.
        libraryCount = libraryCount + 1
        local targetDirectory = format("%s/%d", TEST_DIRECTORY, libraryCount)

        ok, err = mkdir(targetDirectory)
        if not ok then
            error(format("Unable to create the '%s' directory: %s", targetDirectory, err))
        end

        local version = fcp:version()
        if APP_PATH then
            local info = application.infoForBundlePath(APP_PATH .. ".app")
            if info and info.CFBundleShortVersionString then
                version = info.CFBundleShortVersionString
            end
        end

        -- copy the test library to the temporary directory
        local sourceLibraryPath = format("%s/cp/apple/finalcutpro/_libraries/%s/%s.fcpbundle", config.testsPath, version, TEST_LIBRARY)

        -- check it exists
        if fs.pathToAbsolute(sourceLibraryPath) == nil then
            error(format("Unable to find test library for FCP version: %s", fcp:version()))
        end


        local targetLibraryPath = format("%s/%s.fcpbundle", targetDirectory, targetLibrary)

        local output, status, type, rc = hs.execute(format([[cp -R "%s" "%s"]], sourceLibraryPath, targetLibraryPath))
        if not status then
            error(format("Unable to copy the Test Library to '%s': %s (%s: %s)", targetDirectory, output, type, rc))
        end

        -- check it copied ok.
        if not fs.attributes(targetLibraryPath) then
            error(format("Unable to find the Test Library in the copied destination: %s", targetLibraryPath))
        end

        -- give the OS a second to catch up.
        just.wait(1)

        if APP_PATH then
            fcp:launch(nil, APP_PATH)
        else
            fcp:launch()
        end

        just.doUntil(function() return fcp:isRunning() end, 10, 0.1)

        fcp:selectMenu({"Window", "Workspaces", "Default"})

        if not fcp:openLibrary(targetLibraryPath) then
            error(format("Unable to open the Test Library: %s", targetLibraryPath))
        end

        -- keep trying until the library loads successfully, waiting up to 5 seconds.
        if not just.doUntil(function() return fcp:libraries():selectLibrary(targetLibrary) ~= nil end, 10, 0.1) then
            error(format("Unable to open the '%s' Library.", targetLibrary))
        end

        if not just.doUntil(function() return fcp:libraries():openClipTitled("Test Project") end, 10, 0.1) then
            error(format("Unable to open the 'Test Project' clip."))
        end
    end
):afterEach(
    function(testcase)
        local targetLibrary = "Test - " .. testcase.name
        local targetDirectory = format("%s/%d", TEST_DIRECTORY, libraryCount)
        local targetLibraryPath = format("%s/%s.fcpbundle", targetDirectory, targetLibrary)

        -- do this after each test.
        if fcp:closeLibrary(targetLibrary) then
            -- wait until the library actually closes...
            just.doWhile(function() return fcp:selectLibrary(targetLibrary) end, 10, 0.1)

            doAfter(1, function()
                -- delete the temporary library copy.
                local ok, err = rmdir(targetLibraryPath, true)
                if not ok then
                    error(format("Unable to remove the temporary directory: %s", err))
                end
            end)
        else
            log.df("Unable to close '%s'", targetLibrary)
        end
    end
)
