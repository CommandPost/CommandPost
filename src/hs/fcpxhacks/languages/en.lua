-- LANGUAGE: English
return {
	en = {

		--------------------------------------------------------------------------------
		-- GENERIC:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Numbers:
			--------------------------------------------------------------------------------
			one									=			"1",
			two									=			"2",
			three								=			"3",
			four								=			"4",
			five								=			"5",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			button								=			"Button",
			options								=			"Options",
			open								=			"Open",
			secs								=			"secs",
			mins								=			"mins",
			version								=			"Version",

		--------------------------------------------------------------------------------
		-- DIALOG BOXES:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Buttons:
			--------------------------------------------------------------------------------
			ok									=			"OK",
			yes									=			"Yes",
			no									=			"No",
			done								=			"Done",
			cancel								=			"Cancel",
			buttonContinueBatchExport			=			"Continue Batch Export",

			--------------------------------------------------------------------------------
			-- Common Error Messages:
			--------------------------------------------------------------------------------
			commonErrorMessageStart				=			"I'm sorry, but the following error has occurred:",
			commonErrorMessageEnd				=			"Would you like to email this bug to Chris so that he can try and come up with a fix?",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			pleaseTryAgain						=			"Please try again.",
			doYouWantToContinue					=			"Do you want to continue?",

			--------------------------------------------------------------------------------
			-- Notifications:
			--------------------------------------------------------------------------------
			hasLoaded							=			"has loaded",
			keyboardShortcutsUpdated			=			"Keyboard Shortcuts Updated",
			keywordPresetsSaved					=			"Your Keywords have been saved to Preset",
			keywordPresetsRestored				=			"Your Keywords have been restored to Preset",
			scrollingTimelineDeactivated		=			"Scrolling Timeline Deactivated",
			scrollingTimelineActivated			=			"Scrolling Timeline Activated",
			playheadLockActivated				=			"Playhead Lock Activated",
			playheadLockDeactivated				=			"Playhead Lock Deactivated",
			pleaseSelectSingleClipInTimeline	=			"Please select a single clip in the Timeline.",

			--------------------------------------------------------------------------------
			-- Update Effects List:
			--------------------------------------------------------------------------------
			updateEffectsListWarning			=			"Depending on how many Effects you have installed this might take quite a few seconds.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.",
			updateEffectsListFailed				=			"Unfortunately the Effects List was not successfully updated.",
			updateEffectsListDone				=			"Effects List updated successfully.",

			--------------------------------------------------------------------------------
			-- Update Transitions List:
			--------------------------------------------------------------------------------
			updateTransitionsListWarning		=			"Depending on how many Transitions you have installed this might take quite a few seconds.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.",
			updateTransitionsListFailed			=			"Unfortunately the Transitions List was not successfully updated.",
			updateTransitionsListDone			=			"Transitions List updated successfully.",

			--------------------------------------------------------------------------------
			-- Update Titles List:
			--------------------------------------------------------------------------------
			updateTitlesListWarning				=			"Depending on how many Titles you have installed this might take quite a few seconds.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.",
			updateTitlesListFailed				=			"Unfortunately the Titles List was not successfully updated.",
			updateTitlesListDone				=			"Titles List updated successfully.",

			--------------------------------------------------------------------------------
			-- Update Generators List:
			--------------------------------------------------------------------------------
			updateGeneratorsListWarning			=			"Depending on how many Generators you have installed this might take quite a few seconds.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.",
			updateGeneratorsListFailed			=			"Unfortunately the Generators List was not successfully updated.",
			updateGeneratorsListDone			=			"Generators List updated successfully.",

			--------------------------------------------------------------------------------
			-- Assign Shortcut Errors:
			--------------------------------------------------------------------------------
			assignEffectsShortcutError			=			"The Effects List doesn't appear to be up-to-date.\n\nPlease update the Effects List and try again.",
			assignTransitionsShortcutError		=			"The Transitions List doesn't appear to be up-to-date.\n\nPlease update the Transitions List and try again.",
			assignTitlesShortcutError			=			"The Titles List doesn't appear to be up-to-date.\n\nPlease update the Titles List and try again.",
			assignGeneratorsShortcutError		=			"The Generators List doesn't appear to be up-to-date.\n\nPlease update the Generators List and try again.",

			--------------------------------------------------------------------------------
			-- Error Messages:
			--------------------------------------------------------------------------------
			wrongHammerspoonVersionError		=			"FCPX Hacks requires Hammerspoon %{version} or later.\n\nPlease download the latest version of Hammerspoon and try again.",

			noValidFinalCutPro 					= 			"FCPX Hacks couldn't find a compatible version of Final Cut Pro installed on this system.\n\nPlease make sure Final Cut Pro 10.2.3, 10.3 or later is installed in the root of the Applications folder and hasn't been renamed to something other than 'Final Cut Pro'.\n\nHammerspoon will now quit.",
			missingFiles						=			"FCPX Hacks is missing some of its required files.\n\nPlease try re-downloading the latest version from the website, and make sure you follow the installation instructions.\n\nHammerspoon will now quit.",

			customKeyboardShortcutsFailed		=			"Something went wrong when we were reading your custom keyboard shortcuts.\n\nAs a fail-safe, we are going back to use using the default keyboard shortcuts, sorry!",

			newKeyboardShortcuts				=			"This latest version of FCPX Hacks may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password.",
			newKeyboardShortcutsRestart			=			"This latest version of FCPX Hacks may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password and restart Final Cut Pro.",

			prowlError							=			"The Prowl API Key failed to validate due to the following error:",

			sharedClipboardFileNotFound			=			"The Shared Clipboard file could not be found.",
			sharedClipboardNotRead				=			"The Shared Clipboard file could not be read.",

			restartFinalCutProFailed			=			"We weren't able to restart Final Cut Pro.\n\nPlease restart Final Cut Pro manually.",

			keywordEditorAlreadyOpen			=			"This shortcut should only be used when the Keyword Editor is already open.\n\nPlease open the Keyword Editor and try again.",
			keywordShortcutsVisibleError		=			"Please make sure that the Keyboard Shortcuts are visible before using this feature.",
			noKeywordPresetsError				=			"It doesn't look like you've saved any keyword presets yet?",
			noKeywordPresetError				=			"It doesn't look like you've saved anything to this keyword preset yet?",

			noTransitionShortcut				=			"There is no Transition assigned to this shortcut.\n\nYou can assign Tranistions Shortcuts via the FCPX Hacks menu bar.",
			noEffectShortcut					=			"There is no Effect assigned to this shortcut.\n\nYou can assign Effects Shortcuts via the FCPX Hacks menu bar.",
			noTitleShortcut						=			"There is no Title assigned to this shortcut.\n\nYou can assign Titles Shortcuts via the FCPX Hacks menu bar.",
			noGeneratorShortcut					=			"There is no Generator assigned to this shortcut.\n\nYou can assign Generator Shortcuts via the FCPX Hacks menu bar.",

			touchBarError						=			"Touch Bar support requires macOS 10.12.1 (Build 16B2657) or later.\n\nPlease update macOS and try again.",

			item								=
			{
				one								=			"item",
				other							=			"items"
			},

			batchExportNoDestination			=			"It doesn't look like you have a Default Destination selected.\n\nYou can set a Default Destination by going to 'Preferences', clicking the 'Destinations' tab, right-clicking on the Destination you would like to use and then click 'Make Default'.",
			batchExportEnableBrowser			=			"Please ensure that the browser is enabled before exporting.",
			batchExportCheckPath				=			"Final Cut Pro will export the %{count} selected %{item} using your default export settings to the following location:\n\n\t%{path}\n\nIf you wish to change this location, export something else with your preferred destination first.\n\nPlease do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation.\n\nIf there's already a file with the same name in the export destination then that clip will be skipped.",
			batchExportCheckPathSidebar			=			"Final Cut Pro will export all items in the selected containers using your default export settings to the following location:\n\n\t%{path}\n\nIf you wish to change this location, export something else with your preferred destination first.\n\nPlease do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation.\n\nIf there's already a file with the same name in the export destination then that clip will be skipped.",
			batchExportNoClipsSelected			=			"Please ensure that at least one clip is selected for export.",
			batchExportNoShortcut				=			"Please assign the 'Export using Default Share Destination' to a shortcut key.",
			batchExportComplete					=			"Batch Export is now complete. The selected clips have been added to your render queue.",
			batchExportSkipped					=
			{
				one								=			"One clip was skipped as a file with the same name already existed.",
				other							=			"%{count} clips were skipped as files with the same names already existed."
			},

			activeCommandSetError				= 			"Something went wrong whilst attempting to read the Active Command Set.",
			activeCommandSetResetError			=			"Failed to set the Active Command Set to the default value.",

			movingMarkersError					=			"Failed to write to the Event Descriptions Preferences file.",

			failedToWriteToPreferences			=			"Failed to write to the Final Cut Pro Preferences file.",
			failedToReplaceFile					=			"Failed to replace the following file:",
			failedToWriteToFile					=			"Failed to write to the following file:",
			failedToReadFCPPreferences			=			"Failed to read Final Cut Pro Preferences",
			failedToChangeLanguage				=			"Unable to change Final Cut Pro's language.",
			failedToRestart						=			"Failed to restart Final Cut Pro. You will need to restart manually.",

			backupIntervalFail 					=			"Failed to write Backup Interval to the Final Cut Pro Preferences file.",

			--------------------------------------------------------------------------------
			-- Yes/No Dialog Boxes:
			--------------------------------------------------------------------------------
			changeFinalCutProLanguage 			=			"Changing Final Cut Pro's language requires Final Cut Pro to restart.",
			changeBackupInterval				=			"Changing the Backup Interval requires Final Cut Pro to restart.",
			changeSmartCollectionsLabel			=			"Changing the Smart Collections Label requires Final Cut Pro to restart.",

			hacksShortcutsRestart				=			"Hacks Shortcuts in Final Cut Pro requires your Administrator password and also needs Final Cut Pro to restart before it can take affect.",
			hacksShortcutAdminPassword			=			"Hacks Shortcuts in Final Cut Pro requires your Administrator password.",

			togglingMovingMarkersRestart		=			"Toggling Moving Markers requires Final Cut Pro to restart.",
			togglingBackgroundTasksRestart 		=			"Toggling the ability to perform Background Tasks during playback requires Final Cut Pro to restart.",
			togglingTimecodeOverlayRestart		=			"Toggling Timecode Overlays requires Final Cut Pro to restart.",


			trashFCPXHacksPreferences			=			"Are you sure you want to trash the FCPX Hacks Preferences?",
			adminPasswordRequiredAndRestart		=			"This will require your Administrator password and require Final Cut Pro to restart.",
			adminPasswordRequired				=			"This will require your Administrator password.",

			--------------------------------------------------------------------------------
			-- Textbox Dialog Boxes:
			--------------------------------------------------------------------------------
			smartCollectionsLabelTextbox		=			"What would you like to set your Smart Collections Label to:",
			smartCollectionsLabelError			=			"The Smart Collections Label you entered is not valid.\n\nPlease only use standard characters and numbers.",

			mobileNotificationsTextbox			=			"Please enter your Prowl API key below.\n\nIf you don't have one you can register for free at prowlapp.com.",
			mobileNotificationsError 			=			"The Prowl API Key you entered is not valid.",

			changeBackupIntervalTextbox			=			"What would you like to set your Final Cut Pro Backup Interval to (in minutes)?",
			changeBackupIntervalError			=			"The backup interval you entered is not valid. Please enter a value in minutes.",

			selectDestinationPreset				=			"Please select a Destination Preset:",
			selectDestinationFolder				=			"Please select a Destination Folder:",

		--------------------------------------------------------------------------------
		-- MENUBAR:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Update:
			--------------------------------------------------------------------------------
			updateAvailable						=			"Update Available",

			--------------------------------------------------------------------------------
			-- Keyboard Shortcuts:
			--------------------------------------------------------------------------------
			displayKeyboardShortcuts			=			"Display Keyboard Shortcuts",
			openCommandEditor					=			"Open Command Editor",

			--------------------------------------------------------------------------------
			-- Shortcuts:
			--------------------------------------------------------------------------------
			shortcuts							=			"Shortcuts",
			createOptimizedMedia				=			"Create Optimized Media",
			createMulticamOptimizedMedia 		= 			"Create Multicam Optimized Media",
			createProxyMedia					=			"Create Proxy Media",
			leaveFilesInPlaceOnImport			=			"Leave Files In Place On Import",
			enableBackgroundRender				=			"Enable Background Render",

			--------------------------------------------------------------------------------
			-- Automation:
			--------------------------------------------------------------------------------
			automation							=			"Automation",
			assignEffectsShortcuts				=			"Assign Effects Shortcuts",
			assignTransitionsShortcuts			=			"Assign Transitions Shortcuts",
			assignTitlesShortcuts				=			"Assign Titles Shortcuts",
			assignGeneratorsShortcuts			=			"Assign Generators Shortcuts",

				--------------------------------------------------------------------------------
				-- Effects Shortcuts:
				--------------------------------------------------------------------------------
				updateEffectsList				=			"Update Effects List",
				effectShortcut					=			"Effect Shortcut",

				--------------------------------------------------------------------------------
				-- Transitions Shortcuts:
				--------------------------------------------------------------------------------
				updateTransitionsList			=			"Update Transitions List",
				transitionShortcut				=			"Transition Shortcut",

				--------------------------------------------------------------------------------
				-- Titles Shortcuts:
				--------------------------------------------------------------------------------
				updateTitlesList				=			"Update Titles List",
				titleShortcut					=			"Title Shortcut",

				--------------------------------------------------------------------------------
				-- Generators Shortcuts:
				--------------------------------------------------------------------------------
				updateGeneratorsList			=			"Update Generators List",
				generatorShortcut				=			"Generator Shortcut",

				--------------------------------------------------------------------------------
				-- Automation Options:
				--------------------------------------------------------------------------------
				enableScrollingTimeline			=			"Enable Scrolling Timeline",
				enableTimelinePlayheadLock		=			"Enable Timeline Playhead Lock",
				enableShortcutsDuringFullscreen =			"Enable Shortcuts During Fullscreen Playback",
				closeMediaImport				=			"Close Media Import When Card Inserted",

			--------------------------------------------------------------------------------
			-- Tools:
			--------------------------------------------------------------------------------
			tools								=			"Tools",
			importSharedXMLFile					=			"Import Shared XML File",
			pasteFromClipboardHistory			=			"Paste from Clipboard History",
			pasteFromSharedClipboard			=			"Paste from Shared Clipboard",
			finalCutProLanguage					=			"Final Cut Pro Language",
			assignHUDButtons					=			"Assign HUD Buttons",

				--------------------------------------------------------------------------------
				-- Languages:
				--------------------------------------------------------------------------------
				german							=			"German",
				english							=			"English",
				spanish							=			"Spanish",
				french							=			"French",
				japanese						=			"Japanese",
				chineseChina					=			"Chinese (China)",

				--------------------------------------------------------------------------------
				-- Tools Options:
				--------------------------------------------------------------------------------
				enableTouchBar					=			"Enable Touch Bar",
				enableHacksHUD					=			"Enable Hacks HUD",
				enableMobileNotifications		=			"Enable Mobile Notifications",
				enableClipboardHistory			=			"Enable Clipboard History",
				enableSharedClipboard			=			"Enable Shared Clipboard",
				enableXMLSharing				=			"Enable XML Sharing",

		--------------------------------------------------------------------------------
    	-- Hacks:
    	--------------------------------------------------------------------------------
    	hacks									=			"Hacks",
    	advancedFeatures						=			"Advanced Features",

			--------------------------------------------------------------------------------
			-- Advanced:
			--------------------------------------------------------------------------------
			enableHacksShortcuts				=			"Enable Hacks Shortcuts in Final Cut Pro",
			enableTimecodeOverlay				=			"Enable Timecode Overlay",
			enableMovingMarkers					=			"Enable Moving Markers",
			enableRenderingDuringPlayback		=			"Enable Rendering During Playback",
			changeBackupInterval				=			"Change Backup Interval",
			changeSmartCollectionLabel			=			"Change Smart Collections Label",

		--------------------------------------------------------------------------------
    	-- Preferences:
    	--------------------------------------------------------------------------------
    	preferences								=			"Preferences",
    	quit									=			"Quit",

			--------------------------------------------------------------------------------
			-- Preferences:
			--------------------------------------------------------------------------------
			batchExportOptions					=			"Batch Export Options",
			menubarOptions						=			"Menubar Options",
			hudOptions							=			"HUD Options",
			touchBarLocation					=			"Touch Bar Location",
			highlightPlayheadColour				=			"Highlight Playhead Colour",
			highlightPlayheadShape				=			"Highlight Playhead Shape",
			language							=			"Language",
			enableDebugMode						=			"Enable Debug Mode",
			trachFCPXHacksPreferences			=			"Trash FCPX Hacks Preferences",
			provideFeedback						=			"Provide Feedback...",
			createdBy							=			"Created by",
			scriptVersion						=			"Script Version",

			--------------------------------------------------------------------------------
			-- Batch Export Options:
			--------------------------------------------------------------------------------
			setDestinationPreset	 			=			"Set Destination Preset",
			setDestinationFolder				=			"Set Destination Folder",
			replaceExistingFiles				=			"Replace Existing Files",

			--------------------------------------------------------------------------------
			-- Menubar Options:
			--------------------------------------------------------------------------------
			showShortcuts						=			"Show Shortcuts",
			showAutomation						=			"Show Automation",
			showTools							=			"Show Tools",
			showHacks							=			"Show Hacks",
			displayProxyOriginalIcon			=			"Display Proxy/Original Icon",
			displayThisMenuAsIcon				=			"Display This Menu As Icon",

			--------------------------------------------------------------------------------
			-- HUD Options:
			--------------------------------------------------------------------------------
			showInspector						=			"Show Inspector",
			showDropTargets						=			"Show Drop Targets",
			showButtons							=			"Show Buttons",

			--------------------------------------------------------------------------------
			-- Touch Bar Location:
			--------------------------------------------------------------------------------
			mouseLocation						=			"Mouse Location",
			topCentreOfTimeline					=			"Top Centre of Timeline",
			touchBarTipOne						=			"TIP: Hold down left OPTION",
			touchBarTipTwo						=			"key & drag to move Touch Bar.",

			--------------------------------------------------------------------------------
			-- Highlight Colour:
			--------------------------------------------------------------------------------
			red									=			"Red",
			blue								=			"Blue",
			green								=			"Green",
			yellow								=			"Yellow",

			--------------------------------------------------------------------------------
			-- Highlight Shape:
			--------------------------------------------------------------------------------
			rectangle							= 			"Rectangle",
			circle								=			"Circle",
			diamond								=			"Diamond",

			--------------------------------------------------------------------------------
			-- Hammerspoon Settings:
			--------------------------------------------------------------------------------
			console								=			"Console",
			showDockIcon						=			"Show Dock Icon",
			showMenuIcon						=			"Show Menu Icon",
			launchAtStartup						=			"Launch at Startup",
			checkForUpdates						=			"Check for Updates",

	}
}