-- LANGUAGE: English
return {
	en = {

		--------------------------------------------------------------------------------
		-- APP NAME:
		--------------------------------------------------------------------------------
		appName								=			"CommandPost",

		--------------------------------------------------------------------------------
		-- GENERIC:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Apps:
			--------------------------------------------------------------------------------
			finalCutPro							=			"Final Cut Pro",

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
			commonErrorMessageEnd				=			"Would you like to submit a bug report?",
			sendBugReport						=			"Send Bug Report",

			--------------------------------------------------------------------------------
			-- Common Strings:
			--------------------------------------------------------------------------------
			pleaseTryAgain						=			"Please try again.",
			doYouWantToContinue					=			"Do you want to continue?",

			--------------------------------------------------------------------------------
			-- Welcome Screen:
			--------------------------------------------------------------------------------
			setupTitle							=			"CommandPost Setup",
			introTagLine						=			"Workflow Toolkit for Professional Editors",
			introText							=			"Thank you for installing CommandPost. This guide will help you set things up.",
			scanFinalCutProText					=			"CommandPost now needs to open <strong>Final Cut Pro</strong>, and search for all the Effects, Transitions, Generators & Titles you have installed so that it can build a list of them for use later.<br /><br />This process takes about a minute to complete. If you need to update this list later, you can do so via the <strong>Scan Final Cut Pro</strong> button in the Preferences.",
			scanFinalCutPro						=			"Scan Final Cut Pro",
			finalcutproUnsupportedVersionTitle	=			"Unsupported Version",
			finalcutproUnsupportedVersionText	=			"CommandPost requires Final Cut Pro <strong>%{minVersion}</strong> or later, but you have version <strong>%{thisVersion}</strong>.<br /><br />Most Final Cut Pro functionality will be disabled or unreliable. Please upgrade to get best results.",
			outroTitle							=			"CommandPost is now setup and ready to go!",
			outroText							=			"You can access CommandPost via the satellite icon<br />in your system’s menubar at the top right corner of the screen.",
			commandSetText						=			"CommandPost has the <strong>optional</strong> ability to let you to manage and control its shortcuts through the Final Cut Pro Command Editor, instead of its built-in Shortcut Manager.<br /><br />Using this feature requires your administrator password and requires Final Cut Pro to restart.<br /><br />",
			commandSetUseFCPX					=			"Use Final Cut Pro",
			commandSetUseCP						=			"Use CommandPost",
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
			feedbackSuccess						=			"Your feedback was submitted successfully.\n\nThank you!",
			feedbackError						=			"An error occurred trying to communicate with the CommandPost servers.\n\nUnfortunately your feedback was not submitted.\n\nPlease try again.",

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
			-- Error Log:
			--------------------------------------------------------------------------------
			clearLog							=			"Clear Log",
			alwaysOnTop							=			"Always On Top",
			reload								=			"Reload",

			--------------------------------------------------------------------------------
			-- Scan Final Cut Pro:
			--------------------------------------------------------------------------------
			scanFinalCutProWarning				=			"Depending on how many Effects, Transitions, Generators, and Titles you have installed this might take quite a few seconds.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.",
			scanFinalCutProDone					=			"Final Cut Pro was scanned successfully.",

			updateEffectsListFailed				=			"Unfortunately the Effects List was not successfully updated.",
			updateTransitionsListFailed			=			"Unfortunately the Transitions List was not successfully updated.",
			updateTitlesListFailed				=			"Unfortunately the Titles List was not successfully updated.",
			updateGeneratorsListFailed			=			"Unfortunately the Generators List was not successfully updated.",

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
			sharedClipboardPathMissing			=			"The Shared Clipboard path no longer exists. Would you like to select a new location?",

			restartFinalCutProFailed			=			"We weren't able to restart Final Cut Pro.\n\nPlease restart Final Cut Pro manually.",
			loadFinalCutProFailed				=			"Failed to load Final Cut Pro. Please try again.",

			keywordEditorAlreadyOpen			=			"This shortcut should only be used when the Keyword Editor is already open.\n\nPlease open the Keyword Editor and try again.",
			keywordShortcutsVisibleError		=			"Please make sure that the Keyboard Shortcuts are visible before using this feature.",
			noKeywordPresetsError				=			"It doesn't look like you've saved any keyword presets yet?",
			noKeywordPresetError				=			"It doesn't look like you've saved anything to this keyword preset yet?",

			noTransitionShortcut				=			"There is no Transition assigned to this shortcut.\n\nYou can assign Transitions Shortcuts via the CommandPost menu bar.",
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
			batchExportFinalCutProClosed		=			"Final Cut Pro needs to be running to set a destination preset.\n\nPlease open Final Cut Pro and try again.",
			activeCommandSetError				= 			"Something went wrong whilst attempting to read the Active Command Set.",
			failedToWriteToPreferences			=			"Failed to write to the Final Cut Pro Preferences file.",
			failedToReadFCPPreferences			=			"Failed to read Final Cut Pro Preferences",
			failedToChangeLanguage				=			"Unable to change Final Cut Pro's language.",
			failedToRestart						=			"Failed to restart Final Cut Pro. You will need to restart manually.",

			backupIntervalFail 					=			"Failed to write Backup Interval to the Final Cut Pro Preferences file.",

			voiceCommandsError 					= 			"Voice Commands could not be activated.\n\nPlease try again.",

			sharedXMLError						=			"Something went wrong when attempting to translate the XML data you dropped. Please try again.",

			--------------------------------------------------------------------------------
			-- Yes/No Dialog Boxes:
			--------------------------------------------------------------------------------
			changeFinalCutProLanguage 			=			"Changing Final Cut Pro's language requires Final Cut Pro to restart.",
			changeBackupIntervalMessage			=			"Changing the Backup Interval requires Final Cut Pro to restart.",
			changeSmartCollectionsLabel			=			"Changing the Smart Collections Label requires Final Cut Pro to restart.",

			hacksEnabling						=			"Enabling",
			hacksDisabling						=			"Disabling",
			hacksShortcutsEditorText			=			"Please use the Final Cut Pro <strong>Command Editor</strong> to edit these shortcuts.",
			hacksShortcutsRestart				=			"CommandPost Shortcuts in Final Cut Pro requires your Administrator password and also needs Final Cut Pro to restart before it can take affect.",
			hacksShortcutAdminPassword			=			"CommandPost Shortcuts in Final Cut Pro requires your Administrator password.",

			togglingMovingMarkersRestart		=			"Toggling Moving Markers requires Final Cut Pro to restart.",
			togglingBackgroundTasksRestart 		=			"Toggling the ability to perform Background Tasks during playback requires Final Cut Pro to restart.",
			togglingTimecodeOverlayRestart		=			"Toggling Timecode Overlays requires Final Cut Pro to restart.",


			trashPreferencesConfirmation		=			"Are you sure you want to trash the CommandPost Preferences?",

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
			keyboardShortcuts					=			"Keyboard Shortcuts",
			enableHacksShortcuts				=			"Control CommandPost Shortcuts within Final Cut Pro",
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
    	developerGuide							=			"Developer Guide",

			--------------------------------------------------------------------------------
			-- Advanced:
			--------------------------------------------------------------------------------
			advanced							=			"Advanced",
			install								=			"Install",
			uninstall							=			"Uninstall",
			developer							=			"Developer",
			commandLineTool						=			"Command Line Tool",
			enableDeveloperMode					=			"Enable Developer Mode",
			openErrorLogOnDockClick				=			"Open Error Log on Dock Icon Click",
			togglingDeveloperMode				=			"Toggling Developer Mode will require CommandPost to reload.\n\nDo you want to continue?",
			trashPreferences					=			"Trash Preferences",
			cliUninstallError					=			"I'm sorry, but we failed to Uninstall the Command Line Tool. Please try again.",
			cliInstallError						=			"I'm sorry, but we failed to Install the Command Line Tool. Please try again.",
			commandLineToolDescription			=			"When the Command Line Tool is installed, you can use <strong>cmdpost</strong> in Terminal to trigger Lua code. Please refer to the User Guide for more information.",
			trashPreferencesDescription			=			"You can also trash the CommandPost Preferences by holding down OPTION+COMMAND when you launch CommandPost from the dock.",

			--------------------------------------------------------------------------------
			-- General:
			--------------------------------------------------------------------------------
	    	sendCrashData						=			"Send Crash Data (requires restart)",
	    	general								=			"General",
			privacy								=			"Privacy",
			appearance							=			"Appearance",
			sections							=			"Sections",
			openPrivacyPolicy					=			"Open Privacy Policy",

			--------------------------------------------------------------------------------
			-- Preferences:
			--------------------------------------------------------------------------------
			menubarOptions						=			"Menubar Options",
			hudOptions							=			"HUD Options",
			touchBar							=			"Virtual Touch Bar",
			touchBarLocation					=			"Location",
			language							=			"Language",
			provideFeedback						=			"Provide Feedback",
			feedback							=			"Feedback",
			createdBy							=			"Created by",
			appVersion							=			"Version",

			--------------------------------------------------------------------------------
			-- Notification Platform:
			--------------------------------------------------------------------------------
			iMessage							=			"iMessage",
			prowl								=			"Prowl",

			--------------------------------------------------------------------------------
			-- Batch Export Options:
			--------------------------------------------------------------------------------
			performBatchExport					=			"Perform Batch Export",
			setDestinationPreset	 			=			"Set Destination Preset",
			setDestinationFolder				=			"Set Destination Folder",
			replaceExistingFiles				=			"Replace Existing Files",
			sendToCompressor					=			"Send to Compressor",

			--------------------------------------------------------------------------------
			-- Menubar Options:
			--------------------------------------------------------------------------------
			showShortcuts						=			"Show Shortcuts",
			showAutomation						=			"Show Automation",
			showTools							=			"Show Tools",
			showAdminTools						=			"Show Administrator",
			displayProxyOriginalIcon			=			"Display Proxy/Original Icon in Menubar",
			displayThisMenuAsIcon				=			"Display Menubar As Icon",

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
			-- Preference Panels:
			--------------------------------------------------------------------------------
			generalPanelLabel					=			"General",
			generalPanelTooltip					=			"General Preferences",

			menubarPanelLabel					=			"Menubar",
			menubarPanelTooltip					=			"Menubar Preferences",

			advancedPanelLabel					=			"Advanced",
			advancedPanelTooltip				=			"Advanced Preferences",

			finalCutProPanelLabel				=			"Final Cut Pro",
			finalCutProPanelTooltip				=			"Final Cut Pro Preferences",

			pluginsPanelLabel					=			"Plugins",
			pluginsPanelTooltip					=			"Plugins Preferences",

			pluginsManagerLabel					=			"Plugins Manager",
			pluginCategory						=			"Category",
			pluginName							=			"Plugin Name",
			pluginStatus						=			"Status",
			pluginAction						=			"Action",
			pluginRequired						=			"Required",

			pluginsCustomFolderDetails			=			[[<strong>Custom Plugins</strong> can also be saved in the Plugins Folder.]],
			pluginsOpenPluginsFolder			=			"Open Plugins Folder",
			
			pluginsDisableCheck					=			"Are you sure you want to disable this plugin?\n\nIf you continue, CommandPost will need to restart.",
			pluginsEnableCheck					=			"Are you sure you want to enable this plugin?\n\nIf you continue, CommandPost will need to restart.",
			
			pluginsUnableToDisable				=			"Unable to disable the '%{pluginName}' plugin.",
			pluginsUnableToEnsable				=			"Unable to enable the '%{pluginName}' plugin.",

			setupHeading						=			"Setup",
			menubarHeading						=			"Menubar",

			languageHeading						=			"Language",
			commandPostLanguage					=			"CommandPost Language",

			shortcutsPanelLabel					=			"Shortcuts",
			shortcutsPanelTooltip				=			"Keyboard Shortcuts",
			shortcutsControl					=			"Shortcuts are currently being controlled by",

			webappPanelLabel					=			"WebApp",
			webappPanelTooltip					=			"WebApp Preferences",

			webappIntroduction					=			"Introduction",

			webappInstructions					=			[[
			The <strong>WebApp</strong> is a very easy way to control CommandPost via your mobile phone or tablet.<br /><br />
			All you need to do is connect your device to the same network as this machine, enable the WebApp below, then access the WebApp via your devices browser by entering URL below.
			]],

			webappSettings						=			"Settings",
			webappEnable						=			"Enable WebApp",
			webappHostname						=			"Hostname",
			webappUnresolvedHostname			=			"Failed to Resolve Hostname!",

			--------------------------------------------------------------------------------
			-- Hammerspoon Settings:
			--------------------------------------------------------------------------------
			openErrorLog						=			"Open Error Log",
			showDockIcon						=			"Show Dock Icon",
			showMenuIcon						=			"Show Menu Icon",
			launchAtStartup						=			"Launch at Startup",
			checkForUpdates						=			"Check for Updates",

	--------------------------------------------------------------------------------
	-- FINAL CUT PRO MEDIA WATCH FOLDER PLUGIN:
	--------------------------------------------------------------------------------
	addWatchFolder						=			"Add Watch Folder",
	watchFolders						=			"Watch Folders",
	setupWatchFolders					=			"Setup Watch Folders",
	selectFolderToWatch					=			"Please select a folder to watch:",
	alreadyWatched						=			"This folder is already being watched.",
	watchFolderFCPMediaHelp				=			"This feature allows you to recieve macOS notfications whenever supported files are added into any of the below watch folders. From the notification you can then <b>Import</b> these files directly to your current Final Cut Pro timeline. If you hold down <b>SHIFT</b> when pressing <b>Import</b>, it will import all the outstanding files.",
	description							=			"Description",
	automaticallyImport					=			"Automatically Import without Notification",
	importToTimeline					=			"Import directly into Timeline",
	newFileForFinalCutPro				=			"New Media for Final Cut Pro",
	import								=			"Import",
	skip								=			"Skip",
	finalCutProNotRunning				=			"Opps! Final Cut Pro is not currently running.\n\nThis notification will be reinstated.",
	deleteAfterImport					=			"Delete file from Watch Folder (5 seconds after Import)",
	deleteNote							=			"Make sure <strong>Copy to library storage location</strong> is selected in Final Cut Pro's Preferences.",
	addFinderTagsOnImport				=			"Add Finder Tags on Import",
	enterVideoTag						=			"Enter a Video Tag Here",
	enterAudioTag						=			"Enter a Audio Tag Here",
	enterImageTag						=			"Enter a Image Tag Here",
	watchFolderFCPMediaTooltip			=			"Final Cut Pro Media Watch Folder Preferences",
	incomingFile						=			"Incoming File...",

	--------------------------------------------------------------------------------
	-- FCPXML WATCH FOLDER PLUGIN:
	--------------------------------------------------------------------------------
	xml									=			"XML",
	newFCPXMLForFinalCutPro				=			"New Media for Final Cut Pro",
	watchFolderFCPXMLTooltip			=			"Final Cut Pro XML Watch Folder Preferences",
	watchFolderXMLHelp					=			"This feature allows you to recieve macOS notfications whenever a FCPXML file is added into any of the below watch folders. From the notification you can then <b>Import</b> these files directly to your current Final Cut Pro timeline. If you hold down <b>SHIFT</b> when pressing <b>Import</b>, it will import all the outstanding files.",

	--------------------------------------------------------------------------------
	-- COMPRESSOR WATCH FOLDER PLUGIN:
	--------------------------------------------------------------------------------
	compressor							=			"Compressor",
	watchFolderCompressorTooltip		=			"Compressor Watch Folder Preferences",
	watchFolderCompressorHelp			=			"This feature allows you to automatically transcode files with Compressor when they're added to any of the below Watch Folders.",
	selectCompressorSettingsFile		=			"Select a Compressor Settings File:",
	selectCompressorDestination			=			"Select a Destination Folder:",
	compressorError						=			"Something went wrong when sending to Compressor.",
	addedToCompressor					=			"Added to Compressor:",
	monitor								=			"Monitor",
	renderComplete						=			"Render Complete!",

	--------------------------------------------------------------------------------
	-- TEXT TO SPEECH PLUGIN:
	--------------------------------------------------------------------------------
	clearHistory						=			"Clear History",
	changeDestinationFolder				=			"Change Destination Folder",
	selectVoice							=			"Select Voice",
	textToSpeechDestination				=			"Please select where you want to save your audio files:",
	customiseFinderTag					=			"Customise Finder Tag",
	enterFinderTag						=			"Please enter the Finder Tag you want to use:",
	enterFinderTagError					=			"This Finder Tag looks invalid.\n\nPlease try again.",
	insertIntoTimeline					=			"Insert into Timeline",
	openEmbeddedSpeechCommandsHelp 		=			"Speech Commands Help",
	openVoiceOverUtility				=			"Open Voice Over Utility",
	createRoleForVoice					=			"Assign Voice Role",

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
	console								=			"Console",
	enableConsole						=			"Enable Console",
	highlightedItem						=			"Highlighted Item",
	consoleChoiceUnfavorite				=			"Unfavourite",
	consoleChoiceFavorite				=			"Favourite",
	consoleChoiceHide					=			"Hide",
	consoleChoiceUnhide					=			"Unhide",
	consoleHideUnhide					=			"Manage Hidden Items...",

	actionHiddenText					=			"%{text} [Hidden]",

	consoleSections						=			"Sections",
	consoleSectionsShowAll				=			"Show All",
	consoleSectionsHideAll				=			"Hide All",
	fcpx_action							=			"Commands",
	menu_action							=			"Menu Items",
	video_action						=			"Video Effects",
	audio_action						=			"Audio Effects",
	generator_action					=			"Generators",
	title_action						=			"Titles",
	transition_action					=			"Transitions",

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
	searchSubtext						=			"Search Subtext",
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
	commandPost_group					=			"CommandPost",

	--------------------------------------------------------------------------------
	-- PLUGIN STATUSES:
	--------------------------------------------------------------------------------
	plugin_status_loaded				=			"Loaded",
	plugin_status_initialized			=			"Initialised",
	plugin_status_active				=			"Active",
	plugin_status_disabled				=			"Disabled",
	plugin_status_error					=			"Failed",

	plugin_action_disable				=			"Disable",
	plugin_action_enable				=			"Enable",
	plugin_action_errorLog				=			"Error Log",

	--------------------------------------------------------------------------------
	-- SHORTCUT PANEL:
	--------------------------------------------------------------------------------
	shortcut_group_global				=			"Global",
	shortcut_group_fcpx					=			"Final Cut Pro X",

	customiseShortcuts					=			"Customise Shortcuts",
	shortcutsGroup						=			"Group",
	shortcutsLabel						=			"Label",
	shortcutsModifier					=			"Modifier",
	shortcutsKey						=			"Key",
	resetShortcuts						=			"Reset to Default Shortcuts",
	shortcutsResetConfirmation			=			"This will reset all modified shortcuts to the default values. Continue?",
	shortcutsResetComplete				=			"Shortcuts reset. Restarting CommandPost.",

	--------------------------------------------------------------------------------
	-- PLUGIN GROUPS:
	--------------------------------------------------------------------------------
	plugin_group_compressor				=			"Compressor",
	plugin_group_core					=			"Core",
	plugin_group_finalcutpro			=			"Final Cut Pro",
	plugin_group_plugin					=			"Plugin",

	--------------------------------------------------------------------------------
	-- PLUGIN LABELS:
	--------------------------------------------------------------------------------
	compressor_watchfolders_panels_media_label				=	"Watch Folders: Compressor",
	core_accessibility_label								=	"Accessibility Permissions",
	finalcutpro_action_manager_label								=	"Action Manager",
	finalcutpro_commands_action_label						=	"Command Action",
	core_commands_global_label								=	"Global Commands",
	core_helpandsupport_credits_label						=	"Help & Support: Credits",
	core_helpandsupport_developerguide_label				=	"Help & Support: Developer Guide",
	core_helpandsupport_feedback_label						=	"Help & Support: Feedback",
	core_helpandsupport_userguide_label						=	"Help & Support: User Guide",
	core_language_label										=	"Language Module",
	core_menu_bottom_label									=	"Menubar: Bottom Section",
	core_menu_helpandsupport_label							=	"Menubar: Help & Support Section",
	core_menu_manager_label									=	"Menubar: Manager",
	core_menu_top_label										=	"Menubar: Top Section",
	core_preferences_advanced_label							=	"Preferences: Advanced",
	core_preferences_general_label							=	"Preferences: General",
	core_preferences_generate_label							=	"Preferences: Generate",
	core_preferences_manager_label							=	"Preferences: Manager",
	core_preferences_menuitem_label							=   "Preferences: Menu Item",
	core_preferences_panels_advanced_label					=	"Preferences Panel: Advanced",
	core_preferences_panels_general_label					=	"Preferences Panel: General",
	core_preferences_panels_menubar_label					=	"Preferences Panel: Menubar",
	core_preferences_panels_plugins_label					=	"Preferences Panel: Plugins",
	core_preferences_panels_shortcuts_label					=	"Preferences Panel: Shortcuts",
	core_preferences_panels_webapp_label					=	"Preferences Panel: WebApp",
	core_preferences_updates_label							=	"Preferences: Updates",
	core_quit_label											=	"Quit Command",
	core_setup_label										= 	"Setup Manager",
	core_watchfolders_manager_label							= 	"Watch Folder Manager",
	core_watchfolders_menuitem_label						=   "Watch Folder Menu Item",
	core_webapp_label										=	"WebApp",
	finalcutpro_browser_addnote_label						=	"Browser: Add Note",
	finalcutpro_browser_keywords_label						=	"Browser: Keyword Features",
	finalcutpro_browser_playhead_label						=	"Browser: Playhead Features",
	finalcutpro_clipboard_history_label						=	"Clipboard History",
	finalcutpro_clipboard_manager_label						=	"Clipboard History Manager",
	finalcutpro_clipboard_shared_label						=	"Shared Clipboard",
	finalcutpro_commands_label								=	"Final Cut Pro Keyboard Commands",
	finalcutpro_console_label								=	"Console",
	finalcutpro_export_batch_label							=	"Batch Export",
	finalcutpro_fullscreen_shortcuts_label					=	"Fullscreen Shortcuts",
	finalcutpro_hacks_backupinterval_label					=	"Backup Interval",
	finalcutpro_hacks_movingmarkers_label					=	"Moving Makers",
	finalcutpro_hacks_playbackrendering_label				=	"Playback Rendering Controls",
	finalcutpro_hacks_shortcuts_label						=	"Hacks Shortcuts",
	finalcutpro_hacks_smartcollectionslabel_label			=	"Smart Collections Label",
	finalcutpro_hacks_timecodeoverlay_label					=	"Timecode Overlay",
	finalcutpro_hud_label									=	"HUD",
	finalcutpro_import_ignorecard_label						=	"Ignore Cards",
	finalcutpro_import_preferences_label					=	"Import Preferences",
	finalcutpro_language_label								=	"Final Cut Pro Languages",
	finalcutpro_menu_administrator_advancedfeatures_label	=	"Menubar: Advanced Features",
	finalcutpro_menu_administrator_label					=	"Menubar: Administrator",
	finalcutpro_menu_clipboard_label						=	"Menubar: Clipboard",
	finalcutpro_menu_mediaimport_label						=	"Menubar: Media Import",
	finalcutpro_menu_menuaction_label						=	"Menubar: Menu Action",
	finalcutpro_menu_proxyicon_label						=	"Proxy Icon",
	finalcutpro_menu_timeline_assignshortcuts_label			=	"Menubar: Timeline Assign Shortcuts",
	finalcutpro_menu_timeline_highlightplayhead_label		=	"Menubar: Highlight Playhead",
	finalcutpro_menu_timeline_label							=	"Menubar: Timeline",
	finalcutpro_menu_tools_label							=	"Menubar: Tools",
	finalcutpro_menu_tools_notifications_label				=	"Menubar: Notifications",
	finalcutpro_notifications_imessage_label				=	"Notifications: iMessage",
	finalcutpro_notifications_manager_label					=	"Notifications: Manager",
	finalcutpro_notifications_prowl_label					=	"Notifications: Prowl",
	finalcutpro_open_label									=	"Open Final Cut Pro",
	finalcutpro_os_touchbar_label							=	"Virtual Touch Bar",
	finalcutpro_os_voice_label								=	"Voice Commands",
	finalcutpro_preferences_app_label						=	"Preferences: Panel",
	finalcutpro_preferences_scanfinalcutpro_label			=	"Preferences: Scan Final Cut Pro",
	finalcutpro_setup_unsupportedversion_label				=	"Setup: Unsupported Version Check",
	finalcutpro_sharing_xml_label							=	"XML Sharing",
	finalcutpro_text2speech_label							=	"Text to Speech",
	finalcutpro_timeline_colorboard_label					=	"Timeline: Color Board",
	finalcutpro_timeline_effects_label						=	"Timeline: Effects",
	finalcutpro_timeline_generators_label					=	"Timeline: Generators",
	finalcutpro_timeline_height_label						=	"Timeline: Height",
	finalcutpro_timeline_lanes_label						=	"Timeline: Lanes",
	finalcutpro_timeline_matchframe_label					=	"Timeline: Match Frame",
	finalcutpro_timeline_movetoplayhead_label				=	"Timeline: Move to Playhead",
	finalcutpro_timeline_multicam_label						=	"Timeline: Multicam",
	finalcutpro_timeline_playback_label						=	"Timeline: Playback",
	finalcutpro_timeline_playhead_label						=	"Timeline: Playhead",
	finalcutpro_timeline_preferences_label					=	"Timeline: Preferences",
	finalcutpro_timeline_selectalltimelineclips_label		=	"Timeline: Select All Timeline Clips",
	finalcutpro_timeline_titles_label						=	"Timeline: Titles",
	finalcutpro_timeline_transitions_label					=	"Timeline: Transitions",
	finalcutpro_timeline_zoomtoselection_label				=	"Timeline: Zoom to Selection",
	finalcutpro_watchers_preferences_label					=	"Watchers: Preferences",
	finalcutpro_watchers_version_label						=	"Watchers: Version",
	finalcutpro_watchfolders_panels_fcpxml_label			=	"Watch Folders: XML",
	finalcutpro_watchfolders_panels_media_label				=	"Watch Folders: Media",

	--------------------------------------------------------------------------------
	-- COMMAND TITLES:
	--------------------------------------------------------------------------------
	fcpx_command_group										=	"FCPX",
	global_command_group									=	"Global",

		--------------------------------------------------------------------------------
		-- Global:
		--------------------------------------------------------------------------------
		cpLaunchFinalCutPro_title								=	"Open Final Cut Pro",

		--------------------------------------------------------------------------------
		-- Final Cut Pro:
		--------------------------------------------------------------------------------
		cpText2Speech_title										=	"Activate Text to Speech Tool",

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

		cpZoomToSelection_title									=	"Zoom to Selection",

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

		cpBatchExportFromBrowser_title							=	"Batch Export from Browser",
		cpChangeSmartCollectionsLabel_title						=	"Change Smart Collections Label",
		cpConsole_title											=	"Activate Console",
		cpCopyWithCustomLabel_title								=	"Copy with Custom Label",
		cpCopyWithCustomLabelAndFolder_title					=	"Copy with Custom Label and Folder",
		cpHUD_title												=	"Toggle HUD",
		cpSingleMatchFrameAndHighlight_title					=	"Single Match Frame and Highlight",
		cpToggleTouchBar_title									=	"Toggle TouchBar",
		cpToggleVoiceCommands_title								=	"Toggle Voice Commands",

	}
}
