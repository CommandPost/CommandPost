--- === plugins.finalcutpro.watchfolders.media.MediaFolder ===
---
--- Final Cut Pro Media Watch Folder Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("MediaFolder")
-- local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs				= require("hs.fs")
local http				= require("hs.http")
local notify			= require("hs.notify")
local pasteboard		= require("hs.pasteboard")
local pathwatcher		= require("hs.pathwatcher")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp				= require("cp.apple.finalcutpro")
local Queue             = require("cp.collect.Queue")
local dialog			= require("cp.dialog")
local go                = require("cp.rx.go")
local tools             = require("cp.tools")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local Do, If            = go.Do, go.If
local Throw             = go.Throw
local Require           = go.Require
local unpack            = table.unpack

local fileExists        = tools.doesFileExist
local insert            = table.insert

-- the FCP copy/leave in place preference
local copyMedia = fcp.app.preferences:prop("FFImportCopyToMediaFolder", true)

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MediaFolder = {}
MediaFolder.mt = {}
MediaFolder.mt.__index = MediaFolder.mt

--- plugins.finalcutpro.watchfolders.media.MediaFolder.new() -> MediaFolder
--- Constructor
--- Creates a new Media Folder.
---
--- Parameters:
---  * mod - The module.
---  * path - Path to the Media Folder.
---  * videoTag - Video Tag as String
---  * audioTag - Audio Tag as String
---  * imageTag - Image Tag as String
---
--- Returns:
---  * A new MediaFolder object.
function MediaFolder.new(mod, path, videoTag, audioTag, imageTag)
    return setmetatable({
        mod = mod,
        path = path,
        tags = {
            video = videoTag,
            audio = audioTag,
            image = imageTag,
        },
        incoming = Queue(),
        ready = Queue(),
        importing = Queue(),
    }, MediaFolder.mt)
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder.thaw(details) -> MediaFolder
--- Constructor
--- Creates a new MediaFolder based on the details provided.
--- The details have typically come from a call to `MediaFolder.freeze(...)`
---
--- Parameters:
---  * details   - The table with details of the media folder when it was frozen.
---
--- Returns:
---  * A new MediaFolder instance with the specified details.
function MediaFolder.thaw(mod, details)
    local mf = MediaFolder.new(mod, details.path)
    mf.tags = details.tags
    mf.incoming:pushRight(unpack(details.incoming))
    mf.ready:pushRight(unpack(details.ready))
    mf.importing:pushRight(unpack(details.importing))
    return mf
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder.freeze(mediaFolder) -> table
--- Function
--- Returns a table with the details of the `MediaFolder`, ready to be stored.
--- It can be brought back via the `MediaFolder.thaw(...)` function.
---
--- Parameters:
---  * mediaFolder   - The `MediaFolder` to freeze.
---
--- Returns:
---  * A table of details.
function MediaFolder.freeze(mediaFolder)
    return {
        path = mediaFolder.path,
        tags = mediaFolder.tags,
        incoming = {unpack(mediaFolder.incoming)},
        ready = {unpack(mediaFolder.ready)},
        importing = {unpack(mediaFolder.importing)},
    }
end
MediaFolder.mt.freeze = MediaFolder.freeze

--- plugins.finalcutpro.watchfolders.media.MediaFolder:init() -> nil
--- Method
--- Initialises the folder, getting any watchers, notifications, etc. running.
---
---- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:init()
    local path = self.path
    if path then
        self.volumeFormat = tools.volumeFormat(path)
        if not self.pathWatcher then
            self.pathWatcher = pathwatcher.new(path, function(files, flags)
                self:processFiles(files, flags)
            end):start()
        end

        -- register the import notification handler
        notify.register(self:importTag(), function(notification)
            self:handleImport(notification)
        end)

        -- clear old notifications
        local importTag = self:importTag()
        for _,n in ipairs(notify.deliveredNotifications()) do
            local tag = n:getFunctionTag()
            if tag == importTag then
                n:withdraw()
            end
        end

        self:updateIncomingNotification()

        self:doImportNext():After(0)
    end
    return self
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doTagFiles(files) -> nil
--- Method
--- Tags a table of files.
---
---- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:doTagFiles(files)
    return Do(function()
        --------------------------------------------------------------------------------
        -- Add Tags:
        --------------------------------------------------------------------------------
        local videoExtensions = fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS
        local audioExtensions = fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS
        local imageExtensions = fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS

        local videoTag = self.tags.video
        local audioTag = self.tags.audio
        local imageTag = self.tags.image

        for _, file in pairs(files) do
            local ext = file:match("%.([^%.]+)$")

            if ext then
                if videoTag and videoExtensions:has(ext) and fileExists(file) then
                    if not fs.tagsAdd(file, {videoTag}) then
                        log.ef("Failed to add Finder Tag (%s) to: %s", videoTag, file)
                    end
                end
                if audioTag and audioExtensions:has(ext) and fileExists(file) then
                    if not fs.tagsAdd(file, {audioTag}) then
                        log.ef("Failed to add Finder Tag (%s) to: %s", audioTag, file)
                    end
                end
                if imageTag and imageExtensions:has(ext) and fileExists(file) then
                    if not fs.tagsAdd(file, {imageTag}) then
                        log.ef("Failed to add Finder Tag (%s) to: %s", imageTag, file)
                    end
                end
            end
        end
    end)
    :Label("MediaFolder:doTagFiles")
end

local function isFile(flags)
    return flags and flags.itemIsFile
end

local function isSupported(file, flags)
    if isFile(flags) then
        local supported = fcp.ALLOWED_IMPORT_ALL_EXTENSIONS
        local ext = file:match("%.([^%.]+)$")
        return supported:has(ext)
    end
    return false
end

local function isRemoved(file, flags)
    return isFile(flags) and flags.isRemoved or (flags.itemRenamed and not fileExists(file))
end

local function isRenamed(file, flags)
    return isFile(flags) and not flags.itemXattrMod and flags.itemRenamed and fileExists(file)
end

local function isCopying(file, flags)
    return isFile(flags) and flags.itemCreated and not flags.itemChangeOwner and fileExists(file)
end

local function isCopied(file, flags)
    return isFile(flags) and not flags.itemXattrMod and flags.itemCreated and flags.itemChangeOwner and fileExists(file)
end

local function notificationDelivered(notification)
    if notification then
        for _,delivered in ipairs(notify.deliveredNotifications()) do
            if delivered == notification then
                return true
            end
        end
    end
    return false
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:checkNotifications() -> none
--- Method
--- Checks Notifications.
---
---- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:checkNotifications()
    if self.readyNotification and not notificationDelivered(self.readyNotification) then
        -- it's been closed
        self.ready = Queue()
        self:save()
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:processFiles() -> none
--- Method
--- Process files.
---
--- Parameters:
---  * files - A table of files to process.
---  * fileFlags - A table of file flags.
---
--- Returns:
---  * None
function MediaFolder.mt:processFiles(files, fileFlags)
    self:checkNotifications()
    for i = 1, #files do
        local file = files[i]
        local flags = fileFlags[i]

        if isSupported(file, flags) then
            if isRemoved(file, flags) then
                self:removeFile(file)
            elseif isCopying(file, flags) then
                self:addIncoming(file)
            elseif isCopied(file, flags) or isRenamed(file, flags) then
                self:addReady(file)
            end
        end
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:removeFile(file) -> MediaFolder
--- Method
--- Removes the file from any queues it might be in, updating relevant notifications.
---
--- Parameters:
---  * file  - the full path to the file.
---
--- Returns:
---  * The MediaFolder instance
function MediaFolder.mt:removeFile(file)
    if self.incoming:removeItem(file) then
        self:updateIncomingNotification()
    end
    if self.ready:removeItem(file) then
        self:updateReadyNotification()
    end
    self.importing:removeItem(file)

    self:save()
    return self
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:addIncoming(file) -> nil
--- Method
--- Adds the file to the 'incoming' list and updates the notification.
---
--- Parameters:
---  * file - The file to add.
---
--- Returns:
---  * nil
function MediaFolder.mt:addIncoming(file)
    self.incoming:pushRight(file)
    self:save()
    self:updateIncomingNotification()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:addReady(file) -> nil
--- Method
--- Adds the file to the 'ready' list and updates the notifications.
---
--- Parameters:
---  * file      - The file to add.
---
--- Returns:
---  * nil
function MediaFolder.mt:addReady(file)
    if self.incoming:removeItem(file) then
        self:updateIncomingNotification()
    end
    if not self.ready:contains(file) then
        self.ready:pushRight(file)
        self:save()
        self:updateReadyNotification()
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:updateIncomingNotification() -> nil
--- Method
--- Updates the 'incoming' notification based on the current set of files in the `incoming` queue.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:updateIncomingNotification()
    if self.incomingNotification then
        self.incomingNotification:withdraw()
        self.incomingNotification = nil
    end
    -------------------------------------------------------------------------------
    -- Show Notification:
    -------------------------------------------------------------------------------
    if #self.incoming > 0 then
        local subTitle = i18n("fcpMediaFolderIncomingSubTitle", {
            file=tools.getFilenameFromPath(self.incoming:peekLeft()),
            count=#self.incoming - 1,
        })

        self.incomingNotification = notify.new()
            :title(i18n("fcpMediaWatchFolderTitle"))
            :subTitle(subTitle)
            :hasActionButton(false)
            :withdrawAfter(0)
            :send()
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:importTag() -> string
--- Method
--- Returns the import tag.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The import tag as a string.
function MediaFolder.mt:importTag()
    return "import:"..self.path
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:updateReadyNotification() -> nil
--- Method
--- Updates the 'ready' notification based on the current set of files in the `ready` queue.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:updateReadyNotification()
    if self.readyNotification then
        self.readyNotification:withdraw()
        self.readyNotification = nil
    end

    local count = #self.ready
    if count > 0 then
        if self.mod.automaticallyImport() then
            self:importAll()
        else
            local actions
            local subTitle = i18n("fcpMediaFolderReadySubTitle", {
                count=count,
            })
            if count > 1 then
                actions = {
                    i18n("fcpMediaFolderRevealInFinder"),
                    i18n("fcpMediaFolderImportAll", {count = count}),
                }

                for _,file in ipairs(self.ready) do
                    insert(actions, tools.getFilenameFromPath(file))
                end
            else
                actions = {
                    i18n("fcpMediaFolderRevealInFinder"),
                    tools.getFilenameFromPath(self.ready:peekLeft()),
                }
            end

            self.readyNotification = notify.new(self:importTag())
                :title(i18n("appName"))
                :subTitle(subTitle)
                :hasActionButton(true)
                :otherButtonTitle(i18n("fcpMediaFolderCancel"))
                :actionButtonTitle(i18n("fcpMediaFolderImport"))
                :additionalActions(actions)
                :alwaysShowAdditionalActions(true)
                :withdrawAfter(0)

            self.readyNotification:send()
        end
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:handleImport(notification) -> nil
--- Method
--- Handles the importing of a file.
---
--- Parameters:
---  * notification - The notification object.
---
--- Returns:
---  * None
function MediaFolder.mt:handleImport(notification)
    -- notification cleared
    if self.readyNotification and not notificationDelivered(self.readyNotification) then
        self.readyNotification = nil
    end

    -- process it.
    local count = #self.ready
    if count > 0 then
        local activation = notification:activationType()
        if activation == notify.activationTypes.actionButtonClicked then
            self:importFirst()
        elseif activation == notify.activationTypes.additionalActionClicked then
            local action = notification:additionalActivationAction()
            if action == i18n("fcpMediaFolderImportAll", {count = count}) then
                self:importAll()
            elseif action == i18n("fcpMediaFolderRevealInFinder") then
                self:doRevealInFinder():After(0)
            else
                for _,filePath in ipairs(self.ready) do
                    local fileName = tools.getFilenameFromPath(filePath)
                    if action == fileName then
                        self:importFiles({filePath})
                        self.ready:removeItem(filePath)
                        self:save()
                        return
                    end
                end
                log.ef("%s: unrecognised notification action: %s", self, action)
            end
        else
            log.ef("%s: unexpected notification activation type: %s", self, activation)
        end
    else
        log.ef("%s: import requested when no files are ready to be imported. ", self)
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:importAll() -> nil
--- Method
--- Begins importing all `ready` files, removing them from the `ready` queue.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:importAll()
    if #self.ready > 0 then
        self:importFiles({unpack(self.ready)})
        self.ready = Queue()
        self:save()
    end
    self:updateReadyNotification()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:importFirst() -> nil
--- Method
--- Begins importing the first `ready` file, removing it from the `ready` queue.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:importFirst()
    if #self.ready > 0 then
        self:importFiles({self.ready:peekLeft()})
        self.ready:popLeft()
        self:save()
    end
    self:updateReadyNotification()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:skipAll() -> nil
--- Method
--- Skip all files in the Media Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:skipAll()
    self.ready = Queue()
    self:save()
    self:updateReadyNotification()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:skipOne() -> nil
--- Method
--- Skip one file in the Media Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:skipOne()
    if #self.ready > 0 then
        self.ready:popLeft()
        self:save()
        self:updateReadyNotification()
    end
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:importFiles(files) -> nil
--- Method
--- Requests for the files to be imported.
---
--- Parameters:
---  * files - a table/list of files to be imported.
---
--- Returns:
---  * None
function MediaFolder.mt:importFiles(files)
    self.importing:pushRight(files)
    -- we save before importing so that we can pick up again later if CP restarts.
    self:save()
    self:doImportNext():TimeoutAfter(30000, "Import Next took too long"):Now()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doWriteFilesToPasteboard(files, context) -> nil
--- Method
--- Write files to the Pasteboard.
---
--- Parameters:
---  * files - a table/list of files to be imported.
---  * context - The context.
---
--- Returns:
---  * A `Statement` to execute.
function MediaFolder.mt:doWriteFilesToPasteboard(files, context)
    return Do(function()
        --------------------------------------------------------------------------------
        -- Temporarily stop the Pasteboard Watcher:
        --------------------------------------------------------------------------------
        if self.mod.pasteboardManager then
            self.mod.pasteboardManager.stopWatching()
        end

        --------------------------------------------------------------------------------
        -- Save current Pasteboard Content:
        --------------------------------------------------------------------------------
        context.originalPasteboard = pasteboard.readAllData()

        --------------------------------------------------------------------------------
        -- Write URL to Pasteboard:
        --------------------------------------------------------------------------------
        local objects = {}
        for _, v in pairs(files) do
            objects[#objects + 1] = { url = "file://" .. http.encodeForQuery(v) }
        end
        local result = pasteboard.writeObjects(objects)
        if not result then
            return Throw(i18n("fcpMediaFolder_Error_UnableToPaste", {file = v}))
        end
    end)
    :ThenYield()
    :Label("MediaFolder:doWriteFilesToPasteboard")
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doRestoreOriginalPasteboard(context) -> nil
--- Method
--- Restore original Pasteboard contents after 2 seconds.
---
--- Parameters:
---  * context - The context.
---
--- Returns:
---  * None
function MediaFolder.mt:doRestoreOriginalPasteboard(context)
    return Do(function()
        if context.originalPasteboard then
            pasteboard.writeAllData(context.originalPasteboard)
            if self.mod.pasteboardManager then
                self.mod.pasteboardManager.startWatching()
            end
            context.originalPasteboard = nil
        end
    end)
    :ThenYield()
    :Label("MediaFolder:doRestoreOriginalPasteboard")
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doDeleteImportedFiles(context) -> nil
--- Method
--- Checks if we are deleting after import, and if so schedules them to be deleted.
---
--- Parameters:
---  * files - a table of file paths.
---
--- Returns:
---  * None
function MediaFolder.mt:doDeleteImportedFiles(files)
    return Do(function()
        --------------------------------------------------------------------------------
        -- Delete After Import:
        --------------------------------------------------------------------------------
        if self.mod.deleteAfterImport() then
            if copyMedia() then
                Do(function()
                    for _, file in pairs(files) do
                        os.remove(file)
                    end
                end)
                :After(self.mod.SECONDS_UNTIL_DELETE * 1000)
                return true
            else
                log.wf("Not automatically deleting imported files because FCP is set to 'Leave files in place' .")
            end
        end
        return false
    end)
    :Label("MediaFolder:doDeleteImportedFiles")
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doImportNext() -> nil
--- Method
--- Imports the next file in the Media Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:doImportNext()
    local timeline = fcp:timeline()
    local context = {}

    return If(function() return self.importingNow ~= true and #self.importing > 0 end):Then(function()
        self.importingNow = true
        local files = self.importing:popLeft()
        self:save()

        --------------------------------------------------------------------------------
        -- Tag the files:
        --------------------------------------------------------------------------------
        return Do(self:doTagFiles(files))

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        :Then(fcp:doLaunch())

        --------------------------------------------------------------------------------
        -- Check if Timeline can be enabled:
        --------------------------------------------------------------------------------
        :Then(
            timeline:doShow()
            :TimeoutAfter(1000, i18n("fcpMediaFolder_Error_ShowTimeline"))
        )

        :Then(
            Require(timeline.isLoaded):OrThrow(i18n("fcpMediaFolder_Error_ProjectRequired"))
        )

        --------------------------------------------------------------------------------
        -- Put the media onto the pasteboard:
        --------------------------------------------------------------------------------
        :Then(self:doWriteFilesToPasteboard(files, context))

        --------------------------------------------------------------------------------
        -- Perform Paste:
        --------------------------------------------------------------------------------
        -- TODO: Figure out bug where FCP menus are not working correctly after writing to the pasteboard
        -- :Then(
        --     fcp:doSelectMenu({"Edit", "Paste as Connected Clip"})
        --     :TimeoutAfter(10000, "Timed out while pasting.")
        -- )
        :Then(fcp:doShortcut("PasteAsConnected"))

        --------------------------------------------------------------------------------
        -- Remove from Timeline if appropriate:
        --------------------------------------------------------------------------------
        :Then(
            If(self.mod.insertIntoTimeline):Is(false):Then(
                fcp:doShortcut("UndoChanges")
            )
        )

        --------------------------------------------------------------------------------
        -- Restore original Pasteboard Content:
        --------------------------------------------------------------------------------
        :Then(self:doRestoreOriginalPasteboard(context))

        --------------------------------------------------------------------------------
        -- Delete the imported files (if configured):
        --------------------------------------------------------------------------------
        :Then(self:doDeleteImportedFiles(files))

        --------------------------------------------------------------------------------
        -- Try importing the next set of files in the queue:
        --------------------------------------------------------------------------------
        :Then(function()
            self.importingNow = false
            return self:doImportNext()
        end)
        :Catch(function(message)
            self.importingNow = false
            log.ef("Error during `doImportNext`: %s", message)
            dialog.displayMessage(message)
            return self:doImportNext()
        end)
    end)
    :Otherwise(function()
        self.importingNow = false
        self:updateReadyNotification()
    end)
    :Label("MediaFolder:doImportNext")
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:save()
--- Method
--- Ensures the MediaFolder is saved.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:save()
    self.mod.saveMediaFolders()
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:destroy()
--- Method
--- Destroys the MediaFolder. It should not be used after this is called.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function MediaFolder.mt:destroy()
    if self.pathWatcher then
        self.pathWatcher:stop()
        self.pathWatcher = nil
    end

    if self.readyNotification then
        self.readyNotification:withdraw()
        self.readyNotification = nil
    end
    if self.incomingNotification then
        self.incomingNotification:withdraw()
        self.incomingNotification = nil
    end

    self.mod = nil
    self.path = nil
    self.tags = nil
    self.incoming = nil
    self.ready = nil
    self.importing = nil
end

--- plugins.finalcutpro.watchfolders.media.MediaFolder:doRevealInFinder() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will reveal the MediaFolder path in the Finder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Statement
function MediaFolder.mt:doRevealInFinder()
    return Do(
        self:doImportNext(),
        function()
            local path = self.ready:peekLeft() or self.path
            os.execute(string.format('open -R %q', path))
        end
    )
end

function MediaFolder.mt:__tostring()
    return "MediaFolder: "..self.path
end

function MediaFolder.mt:__gc()
    self:destroy()
end

return MediaFolder
