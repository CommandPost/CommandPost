local log				= require("hs.logger").new("MediaFolder")

local fnutils			= require("hs.fnutils")
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

local Do, Done          = go.Do, go.Done
local Throw             = go.Throw
local unpack            = table.unpack

local fileExists        = tools.doesFileExist

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
        notify.register("import:" .. path, function(notification)
            self:handleImport(notification)
        end)

        self:updateIncomingNotification()
        self:updateReadyNotification()

        self:importNext():Now()
    end
    return self
end

function MediaFolder.mt:tagFiles(files)
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
            if videoTag and fnutils.contains(videoExtensions, ext) and fileExists(file) then
                if not fs.tagsAdd(file, {videoTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", videoTag, file)
                end
            end
            if audioTag and fnutils.contains(audioExtensions, ext) and fileExists(file) then
                if not fs.tagsAdd(file, {audioTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", audioTag, file)
                end
            end
            if imageTag and fnutils.contains(imageExtensions, ext) and fileExists(file) then
                if not fs.tagsAdd(file, {imageTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", imageTag, file)
                end
            end
        end
    end
end

local function isFile(flags)
    return flags and flags.itemIsFile
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

function MediaFolder.mt:processFiles(files, fileFlags)
    for i = 1, #files do
        local file = files[i]
        local flags = fileFlags[i]

        if isRemoved(file, flags) then
            self:removeFile(file)
        elseif isCopying(file, flags) then
            self:addIncoming(file)
        elseif isCopied(file, flags) or isRenamed(file, flags) then
            self:addReady(file)
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
        self:updateReadyNotification()
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
    self:updateIncomingNotification()
    self:save()
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
    self:updateReadyNotification()
    self:save()
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
    -- Show Temporary Notification:
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

-- MediaFolder:updateReadyNotification() -> nil
-- Method
-- Updates the 'ready' notification based on the current set of files in the `ready` queue.
function MediaFolder.mt:updateReadyNotification()
    if self.readyNotification then
        self.readyNotification:withdraw()
        self.readyNotification = nil
    end

    if #self.ready > 0 then
        local subTitle = i18n("fcpMediaFolderReadySubTitle", {
            file=tools.getFilenameFromPath(self.ready:peekLeft()),
            count=#self.ready - 1,
        })

        self.readyNotification = notify.new("import:"..self.path)
            :title(i18n("fcpMediaWatchFolderTitle"))
            :subTitle(subTitle)
            :hasActionButton(true)
            :otherButtonTitle(i18n("fcpMediaFolderSkip"))
            :actionButtonTitle(i18n("fcpMediaFolderImportAll"))
            :additionalActions({
                i18n("fcpMediaFolderImportAll"),
                i18n("fcpMediaFolderImportIndividually")
            })
            :alwaysShowAdditionalActions(true)
            :send()
    end
end

function MediaFolder.mt:handleImport(notification)
    local activation = notification:activationType()
    if activation == notify.activationTypes.actionButtonClicked then
        self:importAll()
    elseif activation == notify.activationTypes.additionalActionClicked then
        local action = notification:additionalActivationAction()
        if action == i18n("fcpMediaFolderImportAll") then
            self:importAll()
        elseif action == i18n("fcpMediaFolderImportIndividually") then
            self:importIndividually()
        end
    end
end

-- MediaFolder:importAll() -> nil
-- Method
-- Begins importing all `ready` files, removing them from the `ready` queue.
function MediaFolder.mt:importAll()
    if #self.ready > 0 then
        self:importFiles({unpack(self.ready)})
        self.ready = Queue()
    end
    self:updateReadyNotification()
end

-- MediaFolder:importFirst() -> nil
-- Method
-- Begins importing the first `ready` file, removing it from the `ready` queue.
function MediaFolder.mt:importFirst()
    if #self.ready > 0 then
        self:importFiles({self.ready:popLeft()})
    end
    self:updateReadyNotification()
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
    self:importNext():TimeoutAfter(30000, "Import Next took too long"):Debug("importNext"):Now()
end

function MediaFolder.mt:importNext()
    if not self.importingNow and #self.importing > 0 then
        self.importingNow = true
        local files = self.importing:popLeft()
        self:save()

        return Do(function()
            self:tagFiles(files)

            --------------------------------------------------------------------------------
            -- Temporarily stop the Pasteboard Watcher:
            --------------------------------------------------------------------------------
            if self.mod.pasteboardManager then
                self.mod.pasteboardManager.stopWatching()
            end

            --------------------------------------------------------------------------------
            -- Save current Pasteboard Content:
            --------------------------------------------------------------------------------
            local originalPasteboard = pasteboard.readAllData()

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

            local timeline = fcp:timeline()

            --------------------------------------------------------------------------------
            -- Make sure Final Cut Pro is Active:
            --------------------------------------------------------------------------------
            return Do(fcp:doLaunch())

            --------------------------------------------------------------------------------
            -- Check if Timeline can be enabled:
            --------------------------------------------------------------------------------
            :Then(
                timeline:doShow()
                :TimeoutAfter(1000, "Unable to show the Timeline")
            )

            --------------------------------------------------------------------------------
            -- Perform Paste:
            --------------------------------------------------------------------------------
            :Then(
                fcp:doSelectMenu({"Edit", "Paste as Connected Clip"})
                :TimeoutAfter(10000, "Timed out while pasting.")
            )

            --------------------------------------------------------------------------------
            -- Remove from Timeline if appropriate:
            --------------------------------------------------------------------------------
            :Then(function()
                if not self.mod.insertIntoTimeline() then
                    return fcp:doSelectMenu({"Edit", "Undo Paste"}, {pressAll = true}):Debug("Undo Paste")
                end
            end)

            :Then(function()
                --------------------------------------------------------------------------------
                -- Restore original Pasteboard Content:
                --------------------------------------------------------------------------------
                Do(function()
                    pasteboard.writeAllData(originalPasteboard)
                    if self.mod.pasteboardManager then
                        self.mod.pasteboardManager.startWatching()
                    end
                end)
                :After(2000)

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
        end)
        :Then(function()
            self.importingNow = false
            return self:importNext()
        end)
        :Catch(function(message)
            self.importingNow = false
            log.ef("Error during `importNext`: %s", message)
            dialog.displayMessage(message)
            return self:importNext()
        end)
    else
        return Done()
    end
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

return MediaFolder