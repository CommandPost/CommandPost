-- LANGUAGE: English
return {
	en = {

		--------------------------------------------------------------------------------
		-- SCRIPT NAME:
		--------------------------------------------------------------------------------
		scriptName								=			"CommandPost",

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
			six									=			"6",
			seven								=			"7",
			eight								=			"8",
			nine								=			"9",
			ten									=			"10",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			button								=			"Button",
			options								=			"Options",
			open								=			"Open",
			secs								=
			{
				one								=			"sec",
				other							=			"secs",
			},
			mins								=
			{
				one								=			"min",
				other							=			"mins",
			},
			version								=			"Version",
			unassigned							=			"Unassigned",
			enabled								=			"Enabled",
			disabled							=			"Disabled",
			show								=			"Show",
			clearList							=			"Clear List",
			feedback							=			"Feedback",

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
			continue							=			"Continue",
			quit								=			"Quit",
			send								=			"Send",
			skip								=			"Skip",
			close								=			"Close",

			--------------------------------------------------------------------------------
			-- Common Error Messages:
			--------------------------------------------------------------------------------
			unexpectedError						=			"I'm sorry, but an unexpected error has occurred and CommandPost must now close.\n\nWould you like to report this bug to the team?",
			commonErrorMessageStart				=			"I'm sorry, but the following error has occurred:",
			commonErrorMessageEnd				=			"Would you like to email this bug to Chris so that he can try and come up with a fix?",
			sendBugReport						=			"Send Bug Report",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			pleaseTryAgain						=			"Please try again.",
			doYouWantToContinue					=			"Do you want to continue?",

			--------------------------------------------------------------------------------
			-- Welcome Screen:
			--------------------------------------------------------------------------------
			welcomeTitle						=			"Welcome to CommandPost",
			welcomeTagLine						=			"Workflow Toolkit for Professional Editors",
			welcomeIntro						=			"Thank you for installing CommandPost. This guide will help you set things up.",
			scanFinalCutProText					=			"CommandPost now needs to open <strong>Final Cut Pro</strong>, and search for all the Effects, Transitions, Generators & Titles you have installed so that it can build a list of them for use later.<br /><br />This process takes about a minute to complete. If you need to update this list later, you can do so via the <strong>Scan Final Cut Pro</strong> option in the Preferences menubar.",
			scanFinalCutPro						=			"Scan Final Cut Pro",
			finalCutProMissingHeading			=			"CommandPost requires Final Cut Pro 10.3 or later.",
			finalCutProMissingText				=			"Unfortunately we couldn't detect a valid installation of Final Cut Pro installed.<br /><br />Please install the latest version of Final Cut Pro from the App Store<br />and try running CommandPost again.",
			completeHeading						=			"CommandPost is now setup and ready to go!",
			completeText						=			"You can access CommandPost via the satellite icon<br />in your system’s menubar at the top right corner of the screen.",
			commandSetText						=			"CommandPost has the ability to add handy new functions to Final Cut Pro’s Command Editor.<br /><br />This allows you to customise the shortcuts for CommandPost directly within Final Cut Pro.<br /><br />Using this feature requires your administrator password and requires Final Cut Pro to restart.",
			accessibilityNote 					=			"CommandPost makes use of the built-in macOS Accessibility Frameworks<br />to control other applications, such as Final Cut Pro.<br /><br />To continue, please press <strong>Enable Accessibility</strong> below and<br />follow the prompts to allow CommandPost accessibility access.",
			enableAccessibility					=			"Enable Accessibility",

			--------------------------------------------------------------------------------
			-- Feedback Module:
			--------------------------------------------------------------------------------
			bugReport							=			"Bug Report",
			featureRequest						=			"Feature Request",
			support								=			"Support",
			whatWentWrong						=			"What went wrong?",
			whatDidYouExpectToHappen			=			"What did you expect to happen?",
			whatStepsToRecreate					=			"What are the steps to recreate the problem?",
			whatFeatures						=			"What feature would you like to see implemented or improved?",
			howCanWeHelp						=			"How can we help you?",
			emailResponse						=			"If you want an email response you will need to enter your email address:",
			includeContactInfo					=			"Include contact info",
			attachLog							=			"Attach Error Log",
			attachScreenshot					=			"Attach Screenshot",
			fullName							=			"Full Name",
			emailAddress						=			"Email Address",

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
			customKeyboardShortcutsFailed		=			"Something went wrong when we were reading your custom keyboard shortcuts.\n\nAs a fail-safe, we are going back to use using the default keyboard shortcuts, sorry!",

			newKeyboardShortcuts				=			"This latest version of CommandPost may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password.",
			newKeyboardShortcutsRestart			=			"This latest version of CommandPost may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password and restart Final Cut Pro.",

			prowlError							=			"The Prowl API Key failed to validate due to the following error:",

			sharedClipboardRootFolder			=			"Shared Clipboard Root Folder",
			sharedClipboardFileNotFound			=			"The Shared Clipboard file could not be found.",
			sharedClipboardNotRead				=			"The Shared Clipboard file could not be read.",

			restartFinalCutProFailed			=			"We weren't able to restart Final Cut Pro.\n\nPlease restart Final Cut Pro manually.",

			keywordEditorAlreadyOpen			=			"This shortcut should only be used when the Keyword Editor is already open.\n\nPlease open the Keyword Editor and try again.",
			keywordShortcutsVisibleError		=			"Please make sure that the Keyboard Shortcuts are visible before using this feature.",
			noKeywordPresetsError				=			"It doesn't look like you've saved any keyword presets yet?",
			noKeywordPresetError				=			"It doesn't look like you've saved anything to this keyword preset yet?",

			noTransitionShortcut				=			"There is no Transition assigned to this shortcut.\n\nYou can assign Tranistions Shortcuts via the CommandPost menu bar.",
			noEffectShortcut					=			"There is no Effect assigned to this shortcut.\n\nYou can assign Effects Shortcuts via the CommandPost menu bar.",
			noTitleShortcut						=			"There is no Title assigned to this shortcut.\n\nYou can assign Titles Shortcuts via the CommandPost menu bar.",
			noGeneratorShortcut					=			"There is no Generator assigned to this shortcut.\n\nYou can assign Generator Shortcuts via the CommandPost menu bar.",

			touchBarError						=			"Virtual Touch Bar support requires macOS 10.12.1 (Build 16B2657) or later.\n\nPlease update macOS and try again.",

			item								=
			{
				one								=			"item",
				other							=			"items"
			},

			batchExportDestinationsNotFound		=			"We were unable to find the list of Share Destinations.",
			batchExportNoDestination			=			"It doesn't look like you have a Default Destination selected.\n\nYou can set a Default Destination by going to 'Preferences', clicking the 'Destinations' tab, right-clicking on the Destination you would like to use and then click 'Make Default'.\n\nYou can set a Batch Export Destination Preset via the CommandPost menubar.",
			batchExportEnableBrowser			=			"Please ensure that the browser is enabled before exporting.",
			batchExportCheckPath				=			"Final Cut Pro will export the%{count}selected %{item} to the following location:\n\n\t%{path}\n\nUsing the following preset:\n\n\t%{preset}\n\nIf the preset is adding the export to an iTunes Playlist, the Destination Folder will be ignored. %{replace}\n\nYou can change these settings via the CommandPost Menubar Preferences.\n\nPlease do not interrupt Final Cut Pro once you press the Continue button as it may break the automation.",
			batchExportCheckPathSidebar			=			"Final Cut Pro will export all items in the selected containers to the following location:\n\n\t%{path}\n\nUsing the following preset:\n\n\t%{preset}\n\nIf the preset is adding the export to an iTunes Playlist, the Destination Folder will be ignored. %{replace}\n\nYou can change these settings via the CommandPost Menubar Preferences.\n\nPlease do not interrupt Final Cut Pro once you press the Continue button as it may break the automation.",
			batchExportReplaceYes				=			"Exports with duplicate filenames will be replaced.",
			batchExportReplaceNo				=			"Exports with duplicate filenames will be incremented.",
			batchExportNoClipsSelected			=			"Please ensure that at least one clip is selected for export.",
			batchExportComplete					=			"Batch Export is now complete. The selected clips have been added to your render queue.",

			activeCommandSetError				= 			"Something went wrong whilst attempting to read the Active Command Set.",
			failedToWriteToPreferences			=			"Failed to write to the Final Cut Pro Preferences file.",
			failedToReadFCPPreferences			=			"Failed to read Final Cut Pro Preferences",
			failedToChangeLanguage				=			"Unable to change Final Cut Pro's language.",
			failedToRestart						=			"Failed to restart Final Cut Pro. You will need to restart manually.",

			backupIntervalFail 					=			"Failed to write Backup Interval to the Final Cut Pro Preferences file.",

			voiceCommandsError 					= 			"Voice Commands could not be activated.\n\nPlease try again.",

			--------------------------------------------------------------------------------
			-- Yes/No Dialog Boxes:
			--------------------------------------------------------------------------------
			changeFinalCutProLanguage 			=			"Changing Final Cut Pro's language requires Final Cut Pro to restart.",
			changeBackupIntervalMessage			=			"Changing the Backup Interval requires Final Cut Pro to restart.",
			changeSmartCollectionsLabel			=			"Changing the Smart Collections Label requires Final Cut Pro to restart.",

			hacksShortcutsRestart				=			"Hacks Shortcuts in Final Cut Pro requires your Administrator password and also needs Final Cut Pro to restart before it can take affect.",
			hacksShortcutAdminPassword			=			"Hacks Shortcuts in Final Cut Pro requires your Administrator password.",

			togglingMovingMarkersRestart		=			"Toggling Moving Markers requires Final Cut Pro to restart.",
			togglingBackgroundTasksRestart 		=			"Toggling the ability to perform Background Tasks during playback requires Final Cut Pro to restart.",
			togglingTimecodeOverlayRestart		=			"Toggling Timecode Overlays requires Final Cut Pro to restart.",


			trashFCPXHacksPreferences			=			"Are you sure you want to trash the CommandPost Preferences?",
			adminPasswordRequiredAndRestart		=			"This will require your Administrator password and require Final Cut Pro to restart.",
			adminPasswordRequired				=			"This will require your Administrator password.",

			--------------------------------------------------------------------------------
			-- Textbox Dialog Boxes:
			--------------------------------------------------------------------------------
			smartCollectionsLabelTextbox		=			"What would you like to set your Smart Collections Label to:",
			smartCollectionsLabelError			=			"The Smart Collections Label you entered is not valid.\n\nPlease only use standard characters and numbers.",

			changeBackupIntervalTextbox			=			"What would you like to set your Final Cut Pro Backup Interval to (in minutes)?",
			changeBackupIntervalError			=			"The backup interval you entered is not valid. Please enter a value in minutes.",

			selectDestinationPreset				=			"Please select a Destination Preset:",
			selectDestinationFolder				=			"Please select a Destination Folder:",

			--------------------------------------------------------------------------------
			-- Mobile Notifications
			--------------------------------------------------------------------------------
			iMessageTextBox						=			"Please enter the phone number or email address registered with iMessage to send the message to:",
			prowlTextbox						=			"Please enter your Prowl API key below.\n\nIf you don't have one you can register for free at prowlapp.com.",
			prowlTextboxError 					=			"The Prowl API Key you entered is not valid.",

			shareSuccessful 					=			"Share Successful\n%{info}",
			shareFailed							=			"Share Failed",
			shareUnknown						=			"Type: %{type}",
			shareDetails_export					=			"Type: Local Export\nLocation: %{result}",
			shareDetails_youtube				=			"Type: YouTube\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Vimeo					=			"Type: Vimeo\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Facebook				=			"Type: Facebook\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Youku					=			"Type: Youku\nLogin: %{login}\nTitle: %{title}",
			shareDetails_Tudou					=			"Type: Tudou\nLogin: %{login}\nTitle: %{title}",

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
			mediaImport							=			"Media Import",
			createOptimizedMedia				=			"Create Optimized Media",
			createMulticamOptimizedMedia 		= 			"Create Multicam Optimized Media",
			createProxyMedia					=			"Create Proxy Media",
			leaveFilesInPlaceOnImport			=			"Leave Files In Place On Import",
			enableBackgroundRender				=			{
				one								=			"Enable Background Render (%{count} sec)",
				other 							= 			"Enable Background Render (%{count} secs)",
			},

			--------------------------------------------------------------------------------
			-- Timeline:
			--------------------------------------------------------------------------------
			timeline							=			"Timeline",
			assignShortcuts						=			"Assign Shortcuts",
			assignEffectsShortcuts				=			"Effects Shortcuts",
			assignTransitionsShortcuts			=			"Transitions Shortcuts",
			assignTitlesShortcuts				=			"Titles Shortcuts",
			assignGeneratorsShortcuts			=			"Generators Shortcuts",

			highlightPlayhead					=			"Highlight Playhead",
			highlightPlayheadColour				=			"Colour",
			highlightPlayheadShape				=			"Shape",
			highlightPlayheadTime				=			"Time",

			unassignedTitle						=			"Unassigned",

				--------------------------------------------------------------------------------
				-- Effects Shortcuts:
				--------------------------------------------------------------------------------
				updateEffectsList				=			"Update Effects List",
				effectShortcut					=			"Effect Shortcut",
				effectShortcutTitle				=			"Effect Shortcut %{number} (%{title})",
				applyEffectsShortcut			=			"Apply Effects Shortcut %{count}",

				--------------------------------------------------------------------------------
				-- Transitions Shortcuts:
				--------------------------------------------------------------------------------
				updateTransitionsList			=			"Update Transitions List",
				transitionShortcut				=			"Transition Shortcut",
				transitionShortcutTitle			=			"Transition Shortcut %{number} (%{title})",
				applyTransitionsShortcut		=			"Apply Transitions Shortcut %{count}",

				--------------------------------------------------------------------------------
				-- Titles Shortcuts:
				--------------------------------------------------------------------------------
				updateTitlesList				=			"Update Titles List",
				titleShortcut					=			"Title Shortcut",
				titleShortcutTitle				=			"Title Shortcut %{number} (%{title})",
				applyTitlesShortcut				=			"Apply Titles Shortcut %{count}",

				--------------------------------------------------------------------------------
				-- Generators Shortcuts:
				--------------------------------------------------------------------------------
				updateGeneratorsList			=			"Update Generators List",
				generatorShortcut				=			"Generator Shortcut",
				generatorShortcutTitle			=			"Generator Shortcut %{number} (%{title})",
				applyGeneratorsShortcut			=			"Apply Generators Shortcut %{count}",

				--------------------------------------------------------------------------------
				-- Automation Options:
				--------------------------------------------------------------------------------
				enableScrollingTimeline			=			"Enable Scrolling Timeline",
				enableTimelinePlayheadLock		=			"Enable Timeline Playhead Lock",
				enableShortcutsDuringFullscreen =			"Enable Shortcuts During Fullscreen Playback",
				ignoreInsertedCameraCards		=			"Ignore Inserted Camera Cards",

			--------------------------------------------------------------------------------
			-- Clipboard:
			--------------------------------------------------------------------------------
			clipboard							=			"Clipboard",
			localClipboardHistory				=			"Local Clipboard History",
			sharedClipboardHistory				=			"Shared Clipboard History",

			--------------------------------------------------------------------------------
			-- Tools:
			--------------------------------------------------------------------------------
			tools								=			"Tools",
			mobileNotifications					=			"Mobile Notifications",
			sharedXMLFiles						=			"Shared XML Files",
			voiceCommands						=			"Voice Commands",
			finalCutProLanguage					=			"Final Cut Pro Language",
			assignHUDButtons					=			"Assign HUD Buttons",
			batchExport							=			"Batch Export",

			clearClipboardHistory				=			"Clear Clipboard History",
			emptyClipboardHistory				= 			"Empty",
			overrideClipNamePrompt				=			"Please enter a label for the clipboard item:",
			overrideFolderNamePrompt			=			"Please enter a folder for the clipboard item:",
			overrideValueInvalid				=			"The value you entered is not valid.\n\nPlease try again.",

			clearSharedClipboard				=			"Clear Shared Clipboard",
			emptySharedClipboard				=			"Empty",

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
				enableTouchBar					=			"Enable Virtual Touch Bar",
				enableHUD						=			"Enable HUD",
				enableClipboardHistory			=			"Enable Clipboard History",
				enableSharedClipboard			=			"Enable Shared Clipboard",
				enableXMLSharing				=			"Enable XML Sharing",
				enableVoiceCommands				=			"Enable Voice Commands",

		--------------------------------------------------------------------------------
    	-- ADMIN TOOLS:
    	--------------------------------------------------------------------------------
    	adminTools								=			"Administrator",
    	advancedFeatures						=			"Advanced Features",

			--------------------------------------------------------------------------------
			-- Advanced:
			--------------------------------------------------------------------------------
			enableHacksShortcuts				=			"Add CommandPost Shortcuts to Final Cut Pro",
			enableTimecodeOverlay				=			"Enable Timecode Overlay",
			enableMovingMarkers					=			"Enable Moving Markers",
			enableRenderingDuringPlayback		=			"Enable Rendering During Playback",
			changeBackupInterval				=			"Change Backup Interval",
			changeSmartCollectionLabel			=			"Change Smart Collections Label",

		--------------------------------------------------------------------------------
    	-- PREFERENCES:
    	--------------------------------------------------------------------------------
    	scanFinalCutPro							=			"Scan Final Cut Pro",
    	helpAndSupport							=			"Help & Support",
    	preferences								=			"Preferences",
    	credits									=			"Credits",
    	helpCentre								=			"Help Centre",
    	userGuide								=			"User Guide",

			--------------------------------------------------------------------------------
			-- Preferences:
			--------------------------------------------------------------------------------
			menubarOptions						=			"Menubar Options",
			hudOptions							=			"HUD Options",
			touchBar							=			"Virtual Touch Bar",
			touchBarLocation					=			"Location",
			language							=			"Language",
			enableDebugMode						=			"Enable Developer Mode",
			trashPreferences					=			"Trash Preferences",
			provideFeedback						=			"Provide Feedback...",
			createdBy							=			"Created by",
			scriptVersion						=			"Script Version",

			--------------------------------------------------------------------------------
			-- Notification Platform:
			--------------------------------------------------------------------------------
			iMessage							=			"iMessage",
			prowl								=			"Prowl",

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
			showAdminTools						=			"Show Administrator",
			displayProxyOriginalIcon			=			"Display Proxy/Original Icon",
			displayThisMenuAsIcon				=			"Display This Menu As Icon",

			--------------------------------------------------------------------------------
			-- HUD Options:
			--------------------------------------------------------------------------------
			showInspector						=			"Show Inspector",
			showDropTargets						=			"Show Drop Targets",
			showButtons							=			"Show Buttons",

			--------------------------------------------------------------------------------
			-- Voice Command Options:
			--------------------------------------------------------------------------------
			enableAnnouncements					=			"Enable Announcements",
			enableVisualAlerts					=			"Enable Visual Alerts",
			openDictationPreferences			=			"Open Dictation Preferences...",

			--------------------------------------------------------------------------------
			-- Touch Bar Location:
			--------------------------------------------------------------------------------
			draggable							=			"Draggable",
			mouseLocation						=			"Centre of Mouse Location",
			topCentreOfTimeline					=			"Top Centre of Timeline",
			touchBarTipOne						=			"You can drag by holding",
			touchBarTipTwo						=			"down the left OPTION key.",

			--------------------------------------------------------------------------------
			-- Highlight Colour:
			--------------------------------------------------------------------------------
			red									=			"Red",
			blue								=			"Blue",
			green								=			"Green",
			yellow								=			"Yellow",
			custom								=			"Custom",

			--------------------------------------------------------------------------------
			-- Highlight Shape:
			--------------------------------------------------------------------------------
			rectangle							= 			"Rectangle",
			circle								=			"Circle",
			diamond								=			"Diamond",

			--------------------------------------------------------------------------------
			-- Hammerspoon Settings:
			--------------------------------------------------------------------------------
			openConsole							=			"Open Error Console",
			showDockIcon						=			"Show Dock Icon",
			showMenuIcon						=			"Show Menu Icon",
			launchAtStartup						=			"Launch at Startup",
			checkForUpdates						=			"Check for Updates",

	--------------------------------------------------------------------------------
	-- HUD:
	--------------------------------------------------------------------------------
	hud									=			"HUD",
	media								=			"Media",
	quality								=			"Quality",
	backgroundRender					=			"Background Render",
	xmlSharing							=			"XML Sharing",
	originalOptimised					=			"Original/Optimised",
	betterQuality						=			"Better Quality",
	betterPerformance					=			"Better Performance",
	proxy								=			"Proxy",
	hudDropZoneText						=			"Drag from Browser to Here",
	hudDropZoneError					=			"Ah, I'm not sure what you dragged here, but it didn't look like FCPXML?",
	hudButtonError						=			"There is currently no action assigned to this button.\n\nYou can allocate a function to this button via the CommandPost menubar.",
	hudXMLNameDialog					=			"How would you like to label this XML file?",
	hudXMLNameError						=			"The label you entered has special characters that cannot be used.\n\nPlease try again.",
	hudXMLSharingDisabled				=			"XML Sharing is currently disabled.\n\nPlease enable it via the CommandPost menu and try again.",
	hudButtonItem						=			"Button %{count} (%{title})",

	menuChoiceSubText					=			"Menu: %{path}",

	--------------------------------------------------------------------------------
	-- CONSOLE:
	--------------------------------------------------------------------------------
	highlightedItem						=			"Highlighted Item",
	removeFromList						=			"Remove from List",
	mode								=			"Mode",
	normal								=			"Normal",
	removeFromList						=			"Remove from List",
	restoreToList						=			"Restore to List",
	displayOptions						=			"Display Options",
	showNone							=			"Show None",
	showAll								=			"Show All",
	showAutomation						=			"Show Automation",
	showHacks							=			"Show Hacks",
	showShortcuts						=			"Show Shortcuts",
	showVideoEffects					=			"Show Video Effects",
	showAudioEffects					=			"Show Audio Effects",
	showTransitions						=			"Show Transitions",
	showTitles							=			"Show Titles",
	showGenerators						=			"Show Generators",
	showMenuItems						=			"Show Menu Items",
	rememberLastQuery					=			"Remember Last Query",
	update								=			"Update",
	effectsShortcuts					=			"Effects Shortcuts",
	transitionsShortcuts				=			"Transitions Shortcuts",
	titlesShortcuts						=			"Titles Shortcuts",
	generatorsShortcuts					=			"Generators Shortcuts",
	menuItems							=			"Menu Items",

	--------------------------------------------------------------------------------
	-- Command URL Execution:
	--------------------------------------------------------------------------------

	actionMismatchError					=			"Expected '%{expected}' action type but got '%{actual}.",
	actionUndefinedError				=			"No action was specified to execute.",
	cmdIdMissingError					=			"A command ID is required to execute.",
	cmdDoesNotExistError				=			"No command with the ID of %{id} could be found.",
	cmdGroupNotActivated				=			"Unable to activate the '%{id}' command group.",

	--------------------------------------------------------------------------------
	-- Command Groups:
	--------------------------------------------------------------------------------

	timeline_group						=			"Timeline",
	browser_group						=			"Browser",
	colorboard_group					=			"Colour Board",
	mediaImport_group					=			"Media Import",
	hacks_group							=			"Advanced Features",
	videoEffect_group					=			"Video Effect",
	audioEffect_group					=			"Audio Effect",
	title_group							= 			"Title",
	transition_group					=			"Transition",
	generator_group						=			"Generator",

	--------------------------------------------------------------------------------
	-- COMMAND TITLES:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Global:
		--------------------------------------------------------------------------------
		cpLaunchFinalCutPro_title								=	"Open Final Cut Pro",

		--------------------------------------------------------------------------------
		-- Final Cut Pro:
		--------------------------------------------------------------------------------
		cpScrollingTimeline_title								=	"Toggle Scrolling Timeline",
		cpLockPlayhead_title									=	"Toggle Playhead Lock",

		cpEffectsOne_title										=	"Apply Effects Shortcut 1",
		cpEffectsTwo_title										=	"Apply Effects Shortcut 2",
		cpEffectsThree_title									=	"Apply Effects Shortcut 3",
		cpEffectsFour_title										=	"Apply Effects Shortcut 4",
		cpEffectsFive_title										=	"Apply Effects Shortcut 5",

		cpTransitionsOne_title									=	"Apply Transitions Shortcut 1",
		cpTransitionsTwo_title									=	"Apply Transitions Shortcut 2",
		cpTransitionsThree_title								=	"Apply Transitions Shortcut 3",
		cpTransitionsFour_title									=	"Apply Transitions Shortcut 4",
		cpTransitionsFive_title									=	"Apply Transitions Shortcut 5",

		cpGeneratorsOne_title									=	"Apply Generators Shortcut 1",
		cpGeneratorsTwo_title									=	"Apply Generators Shortcut 2",
		cpGeneratorsThree_title									=	"Apply Generators Shortcut 3",
		cpGeneratorsFour_title									=	"Apply Generators Shortcut 4",
		cpGeneratorsFive_title									=	"Apply Generators Shortcut 5",

		cpTitlesOne_title										=	"Apply Titles Shortcut 1",
		cpTitlesTwo_title										=	"Apply Titles Shortcut 2",
		cpTitlesThree_title										=	"Apply Titles Shortcut 3",
		cpTitlesFour_title										=	"Apply Titles Shortcut 4",
		cpTitlesFive_title										=	"Apply Titles Shortcut 5",

		cpHighlightBrowserPlayhead_title						=	"Highlight Playhead",
		cpRevealMulticamClipInBrowserAndHighlight_title			=	"Reveal Multicam Clip in Browser",
		cpRevealMulticamClipInAngleEditorAndHighlight_title		=	"Reveal Multicam Clip in Angle Editor",
		cpRevealInBrowserAndHighlight_title						= 	"Reveal in Browser and Highlight",

		cpSelectClipAtLane_customTitle							=	"Select Clip at Lane %{count}",

		cpSaveKeywordPreset_customTitle							=	"Save Keyword Preset %{count}",
		cpRestoreKeywordPreset_customTitle						=	"Restore Keyword Preset %{count}",

		cpSelectColorBoardPuck_customTitle						=	"Select Color Board Puck %{count}",
		cpPuckMouse_customTitle									=	"Mouse Control Puck %{count}",
		cpPuckMousePanel_customTitle							=	"Mouse Control %{panel} Puck %{count}",
		cpPuck_customTitle										=	"Select %{panel} Puck %{count}",
		cpPuckDirection_customTitle								=	"Select  %{panel} Puck %{count} & %{direction}",

		cpCutSwitchVideoAngle_customTitle						=	"Cut n Switch Video Angle %{count}",
		cpCutSwitchAudioAngle_customTitle						=	"Cut n Switch Audio Angle %{count}",
		cpCutSwitchBothAngle_customTitle						=	"Cut n Switch Both Angle %{count}",

		cpPlay_title											=	"Play",
		cpPause_title											=	"Pause",

		cpSelectForward_title									=	"Select Clips Forward",
		cpSelectBackwards_title									=	"Select Clips Backwards",

		cpAddNoteToSelectedClip_title							=	"Add Note to Selected Clip",

		cpMoveToPlayhead_title									=	"Move to Playhead",

		cpChangeTimelineClipHeightUp_title						=	"Timeline Clip Height Increase",
		cpChangeTimelineClipHeightDown_title					=	"Timeline Clip Height Decrease",

		cpChangeBackupInterval_title							=	"Change Backup Interval",
		cpToggleMovingMarkers_title								=	"Toggle Moving Markers",
		cpAllowTasksDuringPlayback_title						=	"Allow Tasks During Playback",
		cpShowListOfShortcutKeys_title							=	"Show Keyboard Shortcuts",
		cpOpenCommandEditor_title								=	"Open Command Editor",

		cpCreateOptimizedMediaOn_title							=	"Enable Create Optimized Media",
		cpCreateOptimizedMediaOff_title							=	"Disable Create Optimized Media",

		cpCreateMulticamOptimizedMediaOn_title					=	"Enable Multicam Optimized Media",
		cpCreateMulticamOptimizedMediaOff_title					=	"Disable Multicam Optimized Media",

		cpCreateProxyMediaOn_title								=	"Enable Create Proxy Media",
		cpCreateProxyMediaOff_title								=	"Disable Create Proxy Media",

		cpLeaveInPlaceOn_title									=	"Enable Leave In Place on Import",
		cpLeaveInPlaceOff_title									=	"Disable Leave In Place on Import",

		cpBackgroundRenderOn_title								=	"Enable Background Render",
		cpBackgroundRenderOff_title								=	"Disable Background Render",

		cpChangeBackupInterval_title							=	"Change Backup Interval...",
		cpToggleTimecodeOverlays_title							=	"Toggle Timecode Overlay",
		cpToggleMovingMarkers_title								=	"Toggle Moving Markers",
		cpAllowTasksDuringPlayback_title						=	"Toggle Rendering During Playback",

	--------------------------------------------------------------------------------
	-- SHORTCUTS HELP:
	--------------------------------------------------------------------------------

	defaultShortcutsDescription			=

[[The default CommandPost Shortcut Keys are:

---------------------------------
CONTROL+OPTION+COMMAND:
---------------------------------
L = Launch Final Cut Pro (System Wide)

A = Toggle HUD
Z = Toggle Touch Bar

W = Toggle Scrolling Timeline

H = Highlight Browser Playhead
F = Reveal in Browser & Highlight
S = Single Match Frame & Highlight

D = Reveal Multicam in Browser & Highlight
G = Reveal Multicam in Angle Editor & Highlight

E = Batch Export from Browser

B = Change Backup Interval

T = Toggle Timecode Overlays
Y = Toggle Moving Markers
P = Toggle Rendering During Playback

M = Select Color Board Puck 1
, = Select Color Board Puck 2
. = Select Color Board Puck 3
/ = Select Color Board Puck 4

1-9 = Restore Keyword Preset

+ = Increase Timeline Clip Height
- = Decrease Timeline Clip Height

Left Arrow = Select All Clips to Left
Right Arrow = Select All Clips to Right

-----------------------------------------
CONTROL+OPTION+COMMAND+SHIFT:
-----------------------------------------
1-9 = Save Keyword Preset

-----------------------------------------
CONTROL+SHIFT:
-----------------------------------------
1-5 = Apply Effect]],

	}
}