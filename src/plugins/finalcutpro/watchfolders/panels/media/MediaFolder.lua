local log				= require("hs.logger").new("MediaFolder")

local fs				= require("hs.fs")
local http				= require("hs.http")
local notify			= require("hs.notify")
local pasteboard		= require("hs.pasteboard")
local pathwatcher		= require("hs.pathwatcher")


local fcp				= require("cp.apple.finalcutpro")
local Queue             = require("cp.collect.Queue")
local dialog			= require("cp.dialog")
local go                = require("cp.rx.go")
local tools             = require("cp.tools")

local Do, Done, If      = go.Do, go.Done, go.If
local Throw             = go.Throw
local unpack            = table.unpack

local fileExists        = tools.doesFileExist
local insert            = table.insert

local MediaFolder = {}
MediaFolder.mt = {}
MediaFolder.mt.__index = MediaFolder.mt

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

-- MediaFolder.thaw(details) -> MediaFolder
-- Constructor
-- Creates a new MediaFolder based on the details provided.
-- The details have typically come from a call to `MediaFolder.freeze(...)`
--
-- Parameters:
--  * details   - The table with details of the media folder when it was frozen.
--
-- Returns:
--  * A new MediaFolder instance with the specified details.
function MediaFolder.thaw(mod, details)
    local mf = MediaFolder.new(mod, details.path)
    mf.tags = details.tags
    mf.incoming:pushRight(unpack(details.incoming))
    mf.ready:pushRight(unpack(details.ready))
    mf.importing:pushRight(unpack(details.importing))
    return mf
end

-- MediaFolder.freeze(mediaFolder) -> table
-- Function
-- Returns a table with the details of the `MediaFolder`, ready to be stored.
-- It can be brought back via the `MediaFolder.thaw(...)` function.
--
-- Parameters:
--  * mediaFolder   - The `MediaFolder` to freeze.
--
-- Returns:
--  * A table of details.
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

-- MediaFolder:init() -> nil
-- Method
-- Initialises the folder, getting any watchers, notifications, etc. running.
--
--- Parameters:
--  * None
--
-- Returns:
--  * Nothing
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

        -- re-link live notifications
        for _,n in ipairs(notify.deliveredNotifications()) do
            local tag = n:getFunctionTag()
            if tag == self:importTag() then
                self.importNotification = n
            end
        end

        self:updateIncomingNotification()
        self:updateImportNotification()

        self:doImportNext():Now()
    end
    return self
end

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
    return isFile(flags) and flags.itemRenamed and fileExists(file)
end

local function isCopying(file, flags)
    return isFile(flags) and flags.itemCreated and not flags.itemChangeOwner and fileExists(file)
end

local function isCopied(file, flags)
    return isFile(flags) and flags.itemCreated and flags.itemChangeOwner and fileExists(file)
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

function MediaFolder.mt:checkNotifications()
    if self.importNotification and not notificationDelivered(self.importNotification) then
        -- it's been closed
        self.ready = Queue()
        self:save()
    end
end

function MediaFolder.mt:processFiles(files, fileFlags)
    self:checkNotifications()
    for i = 1, #files do
        local file = files[i]
        local flags = fileFlags[i]

        if isSupported(file, flags) then
            -- log.df("processFiles: file: %s; flags: %s", file, inspect(flags))
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

-- MediaFolder:removeFile(file) -> MediaFolder
-- Method
-- Removes the file from any queues it might be in, updating relevant notifications.
--
-- Parameters:
--  * file  - the full path to the file.
--
-- Returns:
--  * The MediaFolder instance
function MediaFolder.mt:removeFile(file)
    if self.incoming:removeItem(file) then
        self:updateIncomingNotification()
    end
    if self.ready:removeItem(file) then
        self:updateImportNotification()
    end
    self.importing:removeItem(file)

    self:save()
    return self
end

-- MediaFolder:addIncoming(file) -> nil
-- Method
-- Adds the file to the 'incoming' list and updates the notification.
--
-- Parameters:
--  * file      - The file to add.
--
-- Returns:
--  * nil
function MediaFolder.mt:addIncoming(file)
    self.incoming:pushRight(file)
    self:save()
    self:updateIncomingNotification()
end

-- MediaFolder:addReady(file) -> nil
-- Method
-- Adds the file to the 'ready' list and updates the notifications.
--
-- Parameters:
--  * file      - The file to add.
--
-- Returns:
--  * nil
function MediaFolder.mt:addReady(file)
    if self.incoming:removeItem(file) then
        self:updateIncomingNotification()
    end
    self.ready:pushRight(file)
    self:save()
    self:updateImportNotification()
end

-- MediaFolder:updateIncomingNotification() -> nil
-- Method
-- Updates the 'incoming' notification based on the current set of files in the `incoming` queue.
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
            :send()
    end
end

function MediaFolder.mt:importTag()
    return "import:"..self.path
end

-- MediaFolder:updateImportNotification() -> nil
-- Method
-- Updates the 'ready' notification based on the current set of files in the `ready` queue.
function MediaFolder.mt:updateImportNotification()
    if self.importNotification then
        self.importNotification:withdraw()
        self.importNotification = nil
    end

    local count = #self.ready
    if count > 0 then
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

        self.importNotification = notify.new(self:importTag())
            :title(i18n("appName"))
            :subTitle(subTitle)
            :hasActionButton(true)
            :otherButtonTitle(i18n("fcpMediaFolderCancel"))
            :actionButtonTitle(i18n("fcpMediaFolderImport"))
            :additionalActions(actions)
            :alwaysShowAdditionalActions(true)

        self.importNotification:send()
    end
end

function MediaFolder.mt:handleImport(notification)
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
                self:revealInFinder()
            else
                for _,filePath in ipairs(self.ready) do
                    local fileName = tools.getFilenameFromPath(filePath)
                    if action == fileName then
                        self.ready:removeItem(fileName)
                        self:save()
                        self:importFiles({fileName})
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

-- MediaFolder:importAll() -> nil
-- Method
-- Begins importing all `ready` files, removing them from the `ready` queue.
function MediaFolder.mt:importAll()
    if #self.ready > 0 then
        self:importFiles({unpack(self.ready)})
        self.ready = Queue()
        self:save()
    end
    self:updateImportNotification()
end

-- MediaFolder:importFirst() -> nil
-- Method
-- Begins importing the first `ready` file, removing it from the `ready` queue.
function MediaFolder.mt:importFirst()
    if #self.ready > 0 then
        self:importFiles({self.ready:popLeft()})
        self:save()
    end
    self:updateImportNotification()
end

function MediaFolder.mt:skipAll()
    self.ready = Queue()
    self:save()
    self:updateImportNotification()
end

function MediaFolder.mt:skipOne()
    if #self.ready > 0 then
        self.ready:popLeft()
        self:save()
        self:updateImportNotification()
    end
end

-- MediaFolder:importFiles(files) -> nil
-- Method
-- Requests for the files to be imported.
--
-- Parameters:
--  * files     - a table/list of files to be imported.
--
-- Returns:
--  * Nothing
function MediaFolder.mt:importFiles(files)
    self.importing:pushRight(files)
    -- we save before importing so that we can pick up again later if CP restarts.
    self:save()
    self:doImportNext():TimeoutAfter(30000, "Import Next took too long"):Now()
end

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
            return Throw("The URL could not be written to the Pasteboard.")
        end
    end)
end

function MediaFolder.mt:doRestoreOriginalPasteboard(context)
    return Do(function()
        Do(function()
            if context.originalPasteboard then
                pasteboard.writeAllData(context.originalPasteboard)
                if self.mod.pasteboardManager then
                    self.mod.pasteboardManager.startWatching()
                end
                context.originalPasteboard = nil
            end
        end)
        :After(2000)
    end)
end

-- Checks if we are deleting after import, and if so schedules them to be deleted.
function MediaFolder.mt:doDeleteImportedFiles(files)
    return Do(function()
        --------------------------------------------------------------------------------
        -- Delete After Import:
        --------------------------------------------------------------------------------
        if self.mod.deleteAfterImport() then
            Do(function()
                for _, file in pairs(files) do
                    os.remove(file)
                end
            end)
            :After(self.mod.SECONDS_UNTIL_DELETE * 1000)
        end
        return true
    end)
end

function MediaFolder.mt:doImportNext()
    local timeline = fcp:timeline()
    local context = {}

    return If(function() return not self.importingNow and #self.importing > 0 end):Then(function()
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
        :Then(fcp:doLaunch():ThenDelay(100):Debug("fcp launch"))

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        :Then(self:doWriteFilesToPasteboard(files, context):ThenDelay(100):Debug("pasteboard"))

        --------------------------------------------------------------------------------
        -- Check if Timeline can be enabled:
        --------------------------------------------------------------------------------
        :Then(
            timeline:doShow()
            :TimeoutAfter(1000, "Unable to show the Timeline"):Debug("timeline show")
        )

        --------------------------------------------------------------------------------
        -- Perform Paste:
        --------------------------------------------------------------------------------
        -- :Then(
        --     fcp:doSelectMenu({"Edit", "Paste as Connected Clip"})
        --     :TimeoutAfter(10000, "Timed out while pasting."):Debug("Paste")
        -- )
        :Then(function()
            fcp:performShortcut("PasteAsConnected")
        end)

        --------------------------------------------------------------------------------
        -- Remove from Timeline if appropriate:
        --------------------------------------------------------------------------------
        :Then(function()
            if not self.mod.insertIntoTimeline() then
                return fcp:doSelectMenu({"Edit", "Undo Paste"}, {pressAll = true})
            end
        end)

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
            -- return self:doImportNext()
        end)
        :Catch(function(message)
            self.importingNow = false
            log.ef("Error during `doImportNext`: %s", message)
            dialog.displayMessage(message)
            return self:doImportNext()
        end)
    end)
    :Otherwise(Done())
end


-- MediaFolder:save()
-- Method
-- Ensures the MediaFolder is saved.
function MediaFolder.mt:save()
    self.mod.saveMediaFolders()
end

-- MediaFolder:destroy()
-- Method
-- Destroys the MediaFolder. It should not be used after this is called.
function MediaFolder.mt:destroy()
    if self.pathWatcher then
        self.pathWatcher:stop()
        self.pathWatcher = nil
    end

    self.mod = nil
    self.path = nil
    self.tags = nil
    self.incoming = nil
    self.ready = nil
    self.importing = nil
end

function MediaFolder.mt:revealInFinder()
    os.execute("open "..self.path)
end

function MediaFolder.mt:__tostring()
    return "MediaFolder: "..self.path
end

return MediaFolder