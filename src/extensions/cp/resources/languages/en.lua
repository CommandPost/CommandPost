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
			apple								=			"Apple",
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
			settings							=			"Settings",
			launch								=			"Launch",
			location							=			"Location",
			visibility							=			"Visibility",
			always								=			"Always",
			none								=			"None",
			icon								=			"Icon",
			action								=			"Action",
			application							=			"Application",
			tip									=			"Tip",
			device								=			"Device",
			select								=			"Select",
			clear								=			"Clear",
			number								=			"Number",
			validate							=			"Validate",
			success								=			"Success",
			unknownError						=			"Unknown Error",
			color                               =           "Color",

			--------------------------------------------------------------------------------
			-- Generic Final Cut Pro Strings:
			--------------------------------------------------------------------------------
			colorBoard							=			"Color Board",
			percentage							=			"Percentage",
			angle								=			"Angle",
			puck								=			"Puck",
			color								=			"Color",
			saturation							=			"Saturation",
			exposure							=			"Exposure",

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
			commonErrorMessageStart				=			"The following error has occurred:",
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
			keywordPresetsSaved					=			"Your Keywords have been saved to Preset",
			keywordPresetsRestored				=			"Your Keywords have been restored to Preset",
			scrollingTimelineDeactivated		=			"Scrolling Timeline Deactivated",
			scrollingTimelineActivated			=			"Scrolling Timeline Activated",
			playheadLockActivated				=			"Playhead Lock Activated",
			playheadLockDeactivated				=			"Playhead Lock Deactivated",
			pleaseSelectSingleClipInTimeline	=			"Please select a single clip in the Timeline.",
			colorBoardCouldNotBeActivated		=			"The Color Board could not be activated. Please make sure a single clip in the timeline is selected and try again.",

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

			--------------------------------------------------------------------------------
			-- Error Messages:
			--------------------------------------------------------------------------------
			noSupportedVersionsOfFCPX			= 			"No supported versions of Final Cut Pro were detected.",

			sharedClipboardRootFolder			=			"Shared Clipboard Root Folder",
			sharedClipboardPathMissing			=			"The Shared Clipboard path no longer exists. Would you like to select a new location?",

			loadFinalCutProFailed				=			"Failed to load Final Cut Pro. Please try again.",

			keywordEditorAlreadyOpen			=			"This shortcut should only be used when the Keyword Editor is already open.\n\nPlease open the Keyword Editor and try again.",
			keywordShortcutsVisibleError		=			"Please make sure that the Keyboard Shortcuts are visible before using this feature.",
			noKeywordPresetsError				=			"It doesn't look like you've saved any keyword presets yet?",
			noKeywordPresetError				=			"It doesn't look like you've saved anything to this keyword preset yet?",

			noPluginFound						=			"Unable to find a ${plugin} called '${name}'.",
			noPluginShortcut					=			"There is no ${plugin} assigned to this shortcut.\n\nYou can assign Shortcuts via the CommandPost menu bar.",

			noTitleShortcut						=			"There is no Title assigned to this shortcut.\n\nYou can assign Shortcuts via the CommandPost menu bar.",
			noGeneratorShortcut					=			"There is no Generator assigned to this shortcut.\n\nYou can assign Shortcuts via the CommandPost menu bar.",

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
			batchExportReplaceYes				=			"Exports with duplicate filenames will be replaced.",
			batchExportReplaceNo				=			"Exports with duplicate filenames will be incremented.",
			batchExportNoClipsSelected			=			"Please ensure that at least one clip is selected for export.",
			batchExportComplete					=			"Batch Export is now complete. The selected clips have been added to your render queue.",
			batchExportFinalCutProClosed		=			"Final Cut Pro needs to be running to set a destination preset.\n\nPlease open Final Cut Pro and try again.",
			failedToWriteToPreferences			=			"Failed to write to the Final Cut Pro Preferences file.",
			failedToChangeLanguage				=			"Unable to change Final Cut Pro's language.",
			failedToRestart						=			"Failed to restart Final Cut Pro. You will need to restart manually.",

			backupIntervalFail 					=			"Failed to write Backup Interval to the Final Cut Pro Preferences file.",

			voiceCommandsError 					= 			"Voice Commands could not be activated.\n\nPlease try again.",

			sharedXMLError						=			"Something went wrong when attempting to translate the XML data you dropped. Please try again.",

			shortcutCouldNotBeTriggered 		= 			"This shortcut could not be triggered.\n\nPlease check that you valid shortcut keys assigned to command you've tried to trigger in the Final Cut Pro Command Editor and try again.",

			--------------------------------------------------------------------------------
			-- Yes/No Dialog Boxes:
			--------------------------------------------------------------------------------
			changeFinalCutProLanguage 			=			"Changing Final Cut Pro's language requires Final Cut Pro to restart.",
			changeSmartCollectionsLabel			=			"Changing the Smart Collections Label requires Final Cut Pro to restart.",

			hacksEnabling						=			"Enabling",
			hacksDisabling						=			"Disabling",
			hacksShortcutsEditorText			=			[[Please use the Final Cut Pro <strong>Command Editor</strong> to edit these shortcuts.<br />
															<br />
															This feature can be disabled by unchecking the <strong>Control CommandPost Shortcuts within Final Cut Pro</strong><br/>
															option in the Final Cut Pro tab.
															]],
			hacksShortcutsRestart				=			"CommandPost Shortcuts in Final Cut Pro requires your Administrator password and also needs Final Cut Pro to restart before it can take affect.",
			hacksShortcutAdminPassword			=			"CommandPost Shortcuts in Final Cut Pro requires your Administrator password.",

			togglingMovingMarkersRestart		=			"Toggling Moving Markers requires Final Cut Pro to restart.",
			togglingWaveformsRestart			=			"Toggling Waveform Drawings requires Final Cut Pro to restart.",
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
		-- NOTIFICATIONS:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- iMessage:
			--------------------------------------------------------------------------------
			iMessageNotifications				=			"iMessage Notifications",
			enableiMessageNotifications			=			"Enable iMessage Notifications",
			iMessageDestination					=			"Mobile/Apple ID",
			iMessageMissingDestination			=			"Phone Number or Apple ID Required",
			iMessageMissingMessage				=			"You must enter a valid phone number or Apple ID before enabling iMessage Notifications.",
			openMessages						=			"Open Messages",
			openContacts						=			"Open Contacts",

			--------------------------------------------------------------------------------
			-- Prowl:
			--------------------------------------------------------------------------------
			prowlNotifications					=			"Prowl Notifications",
			enableProwlNotifications			=			"Enable Prowl Notifications",
			prowlAPIKey							=			"Prowl API Key",
			prowlMissingAPIKey					=			"Missing Prowl API Key",
			prowlMissingAPIKeyMessage			=			"You must enter a valid Prowl API Key to enable Prowl Notifications.",
			invalidProwlAPIKey					=			"Invalid Prowl API Key",
			notValidProwlAPIKeyError			=			"The Prowl API Key failed to validate due to the following error:",
			getProwlAccount						=			"Signup for a Prowl Account",

			--------------------------------------------------------------------------------
			-- Pushover:
			--------------------------------------------------------------------------------
			pushover							=			"Pushover",
			enablePushoverNotifications			=			"Enable Pushover Notifications",
			pushoverNotifications				=			"Pushover Notifications",
			userAPIKey							=			"User API Key",
			applicationAPIKey					=			"Application API Key",
			needUserAndAppAPIKey				=			"You must supply both a User & Application API key to continue.",
			apiKeysValidated					=			"Your API keys you entered have been successfully validated.",
			invalidAPIKeysSupplied				=			"Invalid API Keys Supplied",
			notValidKeysAndError				=			"The supplied API keys are not valid.\n\nThe following error(s) occurred:\n",
			pushoverSignup						=			"Signup for a Pushover Account",
			getCommandPostPushoverAPIKey		=			"Create Application API Key",
			pushoverTestFailed 					=			"You must enter both a User and Application API key and then press the 'Validate' button before you can test Pushover Notifications.",
			pushoverValidateFailed				=			"You must enter both a User and Application API key and then press the 'Validate' button before you can enable Pushover Notifications.",
			pushoverServerFailed				=			"Could not communicate with the Pushover server.",

			--------------------------------------------------------------------------------
			-- Common:
			--------------------------------------------------------------------------------
			areYouConnectedToTheInternet		=			"Are you actually connected to the Internet?",
			testTitle							=			"CommandPost Test",
			thisIsATest							=			"This is a test",
			notificationTestFailed				=			"Notification Test Failed",
			notificationTestFailedMessage		=			"The test failed with the following errors:",
			sendTestNotification				=			"Send Test Notification",
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
			-- Viewer:
			--------------------------------------------------------------------------------
			viewer								=			"Viewer",
			showTimecode						=			"Show Timecode",

			showProjectTimecodeTop 				= 			"Show Project Timecode Top",
			showProjectTimecodeBottom			=			"Show Project Timecode Bottom",
			showSourceTimecodeTop				=			"Show Source Timecode Top",
			showSourceTimecodeBottom			= 			"Show Source Timecode Bottom",

			--------------------------------------------------------------------------------
			-- Timeline:
			--------------------------------------------------------------------------------
			timeline							=			"Timeline",
			pluginShortcuts						=			"Plugin Shortcuts",

			highlightPlayhead					=			"Highlight Playhead",
			highlightPlayheadColour				=			"Colour",
			highlightPlayheadShape				=			"Shape",
			highlightPlayheadTime				=			"Time",

			unassignedTitle						=			"(Unassigned)",

			pluginShortcutTitle					=			"%{number}: %{title}",

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
			showTimelineInPlayer				=			"Show Timeline in Player",
			enableMovingMarkers					=			"Enable Moving Markers",
			enableRenderingDuringPlayback		=			"Enable Rendering During Playback",
			changeBackupInterval				=			"Change Backup Interval",
			changeSmartCollectionLabel			=			"Change Smart Collections Label",
			enableWaveformDrawing				=			"Enable Waveform Drawing",

		--------------------------------------------------------------------------------
    	-- PREFERENCES:
    	--------------------------------------------------------------------------------
    	helpAndSupport							=			"Help & Support",
    	preferences								=			"Preferences",
    	credits									=			"Credits",
    	userGuide								=			"User Guide",
    	developerGuide							=			"Developer Guide",

			--------------------------------------------------------------------------------
			-- Advanced:
			--------------------------------------------------------------------------------
	    	scanFinalCutProDescription			=			"This will scan Final Cut Pro using GUI Scripting Techniques for debugging purposes.",
			advanced							=			"Advanced",
			install								=			"Install",
			uninstall							=			"Uninstall",
			developer							=			"Developer Tools",
			commandLineTool						=			"Command Line Tool",
			enableDeveloperMode					=			"Enable Developer Mode",
			enableAutomaticScriptReloading		=			"Enable Automatic Script Reloading",
			toggleAutomaticScriptReloading		=			"Auto Reload",
			openErrorLogOnDockClick				=			"Open Error Log on Dock Icon Click",
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
			hudOptions							=			"HUD Options",
			language							=			"Language",
			provideFeedback						=			"Provide Feedback",
			appVersion							=			"Version",

			--------------------------------------------------------------------------------
			-- Batch Export Options:
			--------------------------------------------------------------------------------
			performBatchExport					=			"Perform Batch Export",
			setDestinationPreset	 			=			"Set Destination Preset",
			setDestinationFolder				=			"Set Destination Folder",
			replaceExistingFiles				=			"Replace Existing Files",
			ignoreMissingEffects				=			"Ignore Missing & Offline Files",
			sendToCompressor					=			"Send to Compressor",

			--------------------------------------------------------------------------------
			-- Menubar Options:
			--------------------------------------------------------------------------------
			showTools							=			"Show Tools",
			showAdminTools						=			"Show Administrator",
			displayProxyOriginalIcon			=			"Display Proxy/Original Icon in Menubar",
			displayThisMenuAsIcon				=			"Display Menubar As Icon",

			--------------------------------------------------------------------------------
			-- Final Cut Pro:
			--------------------------------------------------------------------------------
			allowZoomingWithOptionKey			=			"Enable Timeline Zooming with Mouse Scroll & OPTION key",

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

			notificationsPanelLabel				=			"Notifications",
			notificationsPanelTooltip			=			"Notifications Preferences",

			tangentPanelLabel					=			"Tangent",
			tangentPanelTooltip					=			"Tangent Preferences",

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

			pluginsDisableCheck					=			"Are you sure you want to disable this plugin?",
			pluginsEnableCheck					=			"Are you sure you want to enable this plugin?",
			pluginsRestart						=			"If you continue, CommandPost will need to restart.",

			pluginsUnableToDisable				=			"Unable to disable the '%{pluginName}' plugin.",
			pluginsUnableToEnable				=			"Unable to enable the '%{pluginName}' plugin.",

			menubarHeading						=			"Menubar",

			languageHeading						=			"Language",
			commandPostLanguage					=			"CommandPost Language",

			shortcutsPanelLabel					=			"Shortcuts",
			shortcutsPanelTooltip				=			"Keyboard Shortcuts",

			touchbarPanelLabel					=			"Touch Bar",
			touchbarPanelTooltip				=			"Touch Bar Preferences",

			streamdeckPanelLabel				=			"Stream Deck",
			streamdeckPanelTooltip				=			"Stream Deck Preferences",

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
			errorLog							=			"Error Log",
			openErrorLog						=			"Open Error Log",
			launchAtStartup						=			"Launch at Startup",
			checkForUpdates						=			"Check for Updates",

	--------------------------------------------------------------------------------
	-- BUG REPORT
	--------------------------------------------------------------------------------
	reportBugToApple					=		"Report Final Cut Pro Bug to Apple",
	suggestFeatureToApple				=		"Suggest Final Cut Pro Feature to Apple",

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
	enableFilenamePrefix                =           "Enable Filename Prefix",
	setFilenamePrefix                   =           "Set Filename Prefix",
	pleaseEnterAPrefix                  =           "Please enter a prefix",
	useUnderscore                       =           "Use Underscore",

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
	hudXMLNameDialog					=			"How would you like to label this XML file?",
	hudXMLNameError						=			"The label you entered has special characters that cannot be used.\n\nPlease try again.",
	hudXMLSharingDisabled				=			"XML Sharing is currently disabled.\n\nPlease enable it via the CommandPost menu and try again.",
	hudButtonItem						=			"Button %{count} (%{title})",

	menuChoiceSubText					=			"Menu: %{path}",

	--------------------------------------------------------------------------------
	-- ACTIVATORS:
	--------------------------------------------------------------------------------
	activatorUnfavoriteAction			=			"Unfavourite",
	activatorFavoriteAction				=			"Favourite",
	activatorHideAction					=			"Hide",
	activatorUnhideAction				=			"Unhide",
	activatorShowHidden					=			"Show Hidden",

	--------------------------------------------------------------------------------
	-- CONSOLE:
	--------------------------------------------------------------------------------
	console								=			"Console",
	highlightedItem						=			"Highlighted Item",

	actionHiddenText					=			"%{text} [Hidden]",

	consoleSections						=			"Sections",
	consoleSectionsShowAll				=			"Show All",
	consoleSectionsHideAll				=			"Hide All",

	removeFromList						=			"Remove from List",
	mode								=			"Mode",
	normal								=			"Normal",


	showAll								=			"Show All",


	showTransitions						=			"Show Transitions",
	showTitles							=			"Show Titles",
	showGenerators						=			"Show Generators",
	rememberLastQuery					=			"Remember Last Query",
	searchSubtext						=			"Search Subtext",
	update								=			"Update",
	commandEditorShortcut				= 			"Command Editor Shortcut",

	--------------------------------------------------------------------------------
	-- ACTIONS:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Global:
		--------------------------------------------------------------------------------
		global_cmds_action					=			"Global Commands",
		global_widgets_action				=			"Global Touch Bar Widgets",

		--------------------------------------------------------------------------------
		-- Final Cut Pro:
		--------------------------------------------------------------------------------
		fcpx_audioEffect_action				=			"Audio Effects",
		fcpx_cmds_action					=			"Commands",
		fcpx_colorInspector_action			=			"Color Inspector",
		fcpx_timeline_action				=			"Timeline",
		fcpx_generator_action				=			"Generators",
		fcpx_menu_action					=			"Menu Items",
		fcpx_midicontrols_action			=			"MIDI Controls",
		fcpx_shortcuts_action				=			"Command Editor Shortcuts",
		fcpx_title_action					=			"Titles",
		fcpx_transition_action				=			"Transitions",
		fcpx_videoEffect_action				=			"Video Effects",
		fcpx_widgets_action					=			"Touch Bar Widgets",

	--------------------------------------------------------------------------------
	-- COMMAND URL EXECUTION:
	--------------------------------------------------------------------------------
	actionMismatchError					=			"Expected '%{expected}' action type but got '%{actual}.",
	actionUndefinedError				=			"No action was specified to execute.",
	cmdIdMissingError					=			"A command ID is required to execute.",
	cmdDoesNotExistError				=			"No command with the ID of %{id} could be found.",
	cmdGroupNotActivated				=			"Unable to activate the '%{id}' command group.",

	--------------------------------------------------------------------------------
	-- COMMAND GROUPS:
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
	finalCutPro_group					=			"Final Cut Pro",
	helpandsupport_group				=			"Help & Support",

	commandChoiceSubText				=			"Command: %{group}",

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
	shortcut_group_fcpx					=			"Final Cut Pro",

	customiseShortcuts					=			"Customise Shortcuts",
	shortcutsGroup						=			"Group",
	shortcutsLabel						=			"Label",
	shortcutsModifier					=			"Modifier",
	shortcutsKey						=			"Key",
	resetShortcuts						=			"Reset to Default Shortcuts",
	shortcutsResetConfirmation			=			"This will reset all modified shortcuts to the default values.",
	resetShortcutsAllToNone				=			"Set All Shortcuts to None",
	shortcutsSetNoneConfirmation		=			"This will reset all of the shortcuts to None.",
	shortcutAlreadyInUse				= 			"This shortcut is already in use.",
	shortcutDuplicateError				=			"You cannot use the same shortcut for multiple commands.",
	shortcutAlreadyInUseByMacOS			=			"This shortcut combination is currently in use by macOS (i.e. it could be used by Screen Capture, Universal Access, and Keyboard Navigation keys).",
	shortcutPleaseTryAgain				=			"Please select a new key and/or modifier combination and try again.",

	--------------------------------------------------------------------------------
	-- TOUCH BAR PANEL:
	--------------------------------------------------------------------------------
	virtualTouchBar						=			"Virtual Touch Bar",
	layoutEditor						=			"Layout Editor",
	customTouchBar						=			"Custom Touch Bar",
	touchBarReset						=			"Reset All Touch Bar Items",
	touchBarResetConfirmation			=			"This will reset all modified Touch Bar items to the default values.",
	buttonLabel							=			"Button Label",
	pleaseSelectAnIcon					=			"Please select an icon:",
	fileCouldNotBeRead					=			"The selected file could not be read.",
	badTouchBarIcon						=			"Only supported image files (JPEG, PNG, TIFF, GIF or BMP) are supported as Touch Bar icons.",
	enableCustomisedTouchBar			=			"Enable Customised Touch Bar",
	enableVirtualTouchBar				=			"Enable Virtual Touch Bar",
	draggable							=			"Draggable",
	mouseLocation						=			"Centre of Mouse Location",
	topCentreOfTimeline					=			"Top Centre of Timeline",
	touchBarDragTip						=			"If Draggable is selected, you can hold down the left OPTION key to drag.",
	touchBarSetupTip					=			[[Make sure "App Controls with Control Strip" is selected within the "Touch Bar shows" Keyboard System Preferences to see the CommandPost icon. You can then tap this icon to toggle through the different Touch Bar groups.]],
	actionOrWidget						=			"Action / Widget",
	touchBarWidget						=			"Touch Bar Widget",

	--------------------------------------------------------------------------------
	-- STREAM DECK PANEL:
	--------------------------------------------------------------------------------
	streamDeck							=			"Stream Deck",
	streamDeckReset						=			"Reset All Stream Deck Items",
	streamDeckResetConfirmation			=			"This will reset all modified Stream Deck items to the default values.",
	enableStreamDeck					=			"Enable Stream Deck",
	streamDeckAppRunning				=			"Stream Deck App is running.",
	streamDeckAppRunningMessage			=			"This must be closed to activate Stream Deck support in CommandPost.",
	streamDeckAppTip					=			[[You MUST have "Stream Deck.app" closed when using Stream Deck with CommandPost. ]],
	badStreamDeckIcon					=			"Only supported image files (JPEG, PNG, TIFF, GIF or BMP) are supported as Stream Deck icons.",

	--------------------------------------------------------------------------------
	-- MIDI PANEL:
	--------------------------------------------------------------------------------
	midi								=			"MIDI",
	midiEditor							=			"MIDI Editor",
	midiControls						=			"MIDI Controls",
	midiResetAll						=			"Reset All Groups",
	midiResetGroup                      =           "Reset Selected Group",
	refreshMidi							=			"Refresh MIDI Devices",
	applyTopDeviceToAll                 =           "Apply Top Device to All",
	midiResetAllConfirmation			=			"This will reset all MIDI items across all groups to the default values.",
	midiResetGroupConfirmation			=			"This will reset all MIDI items with the current group to the default values.",
	midiTopDeviceToAll                  =           "This will apply the MIDI device on the top of the list to all the subsequent lines for the current group.",
	enableMIDI							=			"Enable MIDI Controls",
	channel								=			"Channel",
	value								=			"Value",
	learn								=			"Learn",
	noteOn								=			"Note On",
	noteOff								=			"Note Off",
	controlChange						=			"Control Change",
	learnMIDIMessage					=			"If you press the 'Yes' button below you'll have 3 seconds to trigger any button or controller on any of your connected MIDI devices.",
	openAudioMIDISetup					=			"Open Audio MIDI Setup",

	--------------------------------------------------------------------------------
	-- MIDI CONTROLS:
	--------------------------------------------------------------------------------
	midiTimelineZoom					=			"MIDI Timeline Zoom",
	midiTimelineZoomDescription			=			"Allows you to control timeline zoom via MIDI controls.",
	midiColorBoardDescription			=			"Controls the Color Board via MIDI Controls",
	midiColorWheelDescription			=			"Controls the Color Wheels via MIDI Controls",

	--------------------------------------------------------------------------------
	-- TANGENT SUPPORT:
	--------------------------------------------------------------------------------
	tangentPanelSupport					=			"Tangent Panel Support",
	tangentPreferencesInfo				=			[[CommandPost offers native support of the entire range of Tangent's panels, including the <strong>Element</strong>, <strong>Wave</strong>, <strong>Ripple</strong>, the <strong>Element-Vs iPad app</strong>, and any future panels.<br />
													<br />
													All actions within CommandPost can be assigned to any Tangent panel button/wheel using <strong>Tangent's Mapper</strong> application. This allows you to create your own layouts and modes.<br />
													<br />
													If you add a new effect or plugin in Final Cut Pro, or change Languages, you can use the <strong>Rebuild Control Map</strong> button below to make these new items appear in <strong>Tangent Mapper</strong>. Please be aware that when you rebuild the Control Map this may affect your custom layouts in Tangent Mapper as plugins/effects may have been added, removed or renamed.<br />
													<br />]],
	enableTangentPanelSupport			=			"Enable Tangent Panel Support",
	mustInstallTangentMapper			=			"You must install the Tangent Mapper & Hub to enable Tangent Panel support.",
	enablingTangentPanelSupport			=			"Enabling Tangent Panel Support",
	rebuildControlMap					=			"Rebuild Control Map",
	rebuildControlMapMessage			=			"Just a heads up, it can take a few minutes to re-build the Control Map once you click OK.",
	openTangentMapper					=			"Open Tangent Mapper",
	tangentMapperNotFound				=			"Tangent Mapper Not Found",
	tangentMapperNotFoundMessage		=			"The Tangent Mapper application could not be found.\n\nPlease download the latest version from the Tangent website and try again.",
	downloadTangentHub					=			"Download Tangent Hub",
	visitTangentWebsite					=			"Visit Tangent Website",

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

		--------------------------------------------------------------------------------
		-- Compressor:
		--------------------------------------------------------------------------------
		compressor_watchfolders_panels_media_label				=	"Watch Folders: Compressor",

		--------------------------------------------------------------------------------
		-- Core:
		--------------------------------------------------------------------------------
		core_accessibility_label								=	"Accessibility Permissions",
		core_action_manager_label								=	"Manager: Actions",
		core_commands_actions_label								=	"Commands Actions",
		core_commands_global_label								=	"Global Commands",
		core_console_label										=	"Console",
		core_helpandsupport_credits_label						=	"Help & Support: Credits",
		core_helpandsupport_developerguide_label				=	"Help & Support: Developer Guide",
		core_helpandsupport_feedback_label						=	"Help & Support: Feedback",
		core_helpandsupport_userguide_label						=	"Help & Support: User Guide",
		core_language_label										=	"Language Module",
		core_menu_bottom_label									=	"Menubar: Bottom Section",
		core_menu_helpandsupport_commandpost_label				=	"Menubar: CommandPost Help & Support",
		core_menu_helpandsupport_label							=	"Menubar: Help & Support Section",
		core_menu_manager_label									=	"Manager: Menubar",
		core_menu_top_label										=	"Menubar: Top Section",
		core_midi_manager_label									=	"Manager: MIDI",
		core_preferences_advanced_label							=	"Preferences: Advanced",
		core_preferences_general_label							=	"Preferences: General",
		core_preferences_generate_label							=	"Preferences: Generate",
		core_preferences_manager_label							=	"Manager: Preferences",
		core_preferences_menuitem_label							=   "Preferences: Menu Item",
		core_preferences_panels_advanced_label					=	"Preferences Panel: Advanced",
		core_preferences_panels_general_label					=	"Preferences Panel: General",
		core_preferences_panels_menubar_label					=	"Preferences Panel: Menubar",
		core_preferences_panels_midi_label 						=	"Preferences Panel: MIDI",
		core_preferences_panels_notifications_label				=	"Preferences: Notifications",
		core_preferences_panels_plugins_label					=	"Preferences Panel: Plugins",
		core_preferences_panels_shortcuts_label					=	"Preferences Panel: Shortcuts",
		core_preferences_panels_streamdeck_label				=	"Preferences Panel: Stream Deck",
		core_preferences_panels_tangent_label					=	"Preferences Panel: Tangent",
		core_preferences_panels_touchbar_label					=	"Preferences: Touch Bar",
		core_preferences_panels_webapp_label					=	"Preferences Panel: WebApp",
		core_preferences_updates_label							=	"Preferences: Updates",
		core_quit_label											=	"Quit Command",
		core_setup_label										= 	"Manager: Setup",
		core_streamdeck_manager_label							=	"Manger: Stream Deck",
		core_touchbar_manager_label								=	"Manager: Touch Bar",
		core_touchbar_widgets_volume_label						=	"Widget: Volume Slider",
		core_touchbar_widgets_windowslide_label					=	"Widget: Window Slider",
		core_watchfolders_manager_label							= 	"Manger: Watch Folders",
		core_watchfolders_menuitem_label						=   "Watch Folder Menu Item",
		core_webapp_label										=	"WebApp",

		--------------------------------------------------------------------------------
		-- Final Cut Pro:
		--------------------------------------------------------------------------------
		finalcutpro_browser_addnote_label						=	"Browser: Add Note",
		finalcutpro_browser_keywords_label						=	"Browser: Keyword Features",
		finalcutpro_browser_playhead_label						=	"Browser: Playhead Features",
		finalcutpro_clipboard_history_label						=	"Clipboard History",
		finalcutpro_clipboard_manager_label						=	"Manager: Clipboard",
		finalcutpro_clipboard_shared_label						=	"Shared Clipboard",
		finalcutpro_commands_actions_label						=	"Commands Actions",
		finalcutpro_commands_label								=	"Final Cut Pro Keyboard Commands",
		finalcutpro_console_label								=	"Console",
		finalcutpro_export_batch_label							=	"Batch Export",
		finalcutpro_feedback_bugreport_label					=	"Help & Support: Report Bug to Apple",
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
		finalcutpro_menu_finalcutpro_label						=	"Menubar: Final Cut Pro",
		finalcutpro_menu_helpandsupport_finalcutpro_label		=	"Menubar: Final Cut Pro Help & Support",
		finalcutpro_menu_mediaimport_label						=	"Menubar: Media Import",
		finalcutpro_menu_menuaction_label						=	"Menubar: Menu Action",
		finalcutpro_menu_proxyicon_label						=	"Proxy Icon",
		finalcutpro_menu_support_label							=	"Menubar: Support",
		finalcutpro_menu_timeline_assignshortcuts_label			=	"Menubar: Timeline Assign Shortcuts",
		finalcutpro_menu_timeline_highlightplayhead_label		=	"Menubar: Highlight Playhead",
		finalcutpro_menu_timeline_label							=	"Menubar: Timeline",
		finalcutpro_menu_tools_label							=	"Menubar: Tools",
		finalcutpro_menu_tools_notifications_label				=	"Menubar: Notifications",
		finalcutpro_menu_top_label								=	"Menubar: Final Cut Pro Top Menu",
		finalcutpro_menu_viewer_label							=	"Menubar: Viewer",
		finalcutpro_menu_viewer_showtimecode_label				=	"Menubar: Viewer > Show Timecode",
		finalcutpro_midi_controls_color_label					=	"MIDI Controls: Color Board",
		finalcutpro_midi_controls_zoom_label					=	"MIDI Controls: Timeline Zoom",
		finalcutpro_midi_manager_label							=	"Manager: MIDI",
		finalcutpro_notifications_imessage_label				=	"Notifications: iMessage",
		finalcutpro_notifications_manager_label					=	"Manager: Notifications",
		finalcutpro_notifications_prowl_label					=	"Notifications: Prowl",
		finalcutpro_notifications_pushover_label				=	"Notifications: Pushover",
		finalcutpro_open_label									=	"Open Final Cut Pro",
		finalcutpro_os_voice_label								=	"Voice Commands",
		finalcutpro_preferences_app_label						=	"Preferences: Panel",
		finalcutpro_preferences_scanfinalcutpro_label			=	"Preferences: Scan Final Cut Pro",
		finalcutpro_setup_unsupportedversion_label				=	"Setup: Unsupported Version Check",
		finalcutpro_sharing_xml_label							=	"XML Sharing",
		finalcutpro_streamdeck_label							=	"Stream Deck",
		finalcutpro_tangent_manager_label						=	"Manager: Tangent",
		finalcutpro_text2speech_label							=	"Text to Speech",
		finalcutpro_timeline_audioeffects_label					=	"Timeline: Audio Effects",
		finalcutpro_timeline_colorboard_label					=	"Timeline: Color Board",
		finalcutpro_timeline_commandsetactions_label			=	"Command Set Actions",
		finalcutpro_timeline_disablewaveforms_label				=	"Timeline: Waveform Drawing",
		finalcutpro_timeline_effects_label						=	"Timeline: Effects",
		finalcutpro_timeline_generators_label					=	"Timeline: Generators",
		finalcutpro_timeline_height_label						=	"Timeline: Height",
		finalcutpro_timeline_lanes_label						=	"Timeline: Lanes",
		finalcutpro_timeline_matchframe_label					=	"Timeline: Match Frame",
		finalcutpro_timeline_mousezoom_label					=	"Timeline: Mouse Zoom",
		finalcutpro_timeline_movetoplayhead_label				=	"Timeline: Move to Playhead",
		finalcutpro_timeline_multicam_label						=	"Timeline: Multicam",
		finalcutpro_timeline_playback_label						=	"Timeline: Playback",
		finalcutpro_timeline_playhead_label						=	"Timeline: Playhead",
		finalcutpro_timeline_pluginactions_label				=	"Timeline: Plugin Actions",
		finalcutpro_timeline_pluginshortcuts_label				=	"Timeline: Plugin Shortcuts",
		finalcutpro_timeline_preferences_label					=	"Timeline: Preferences",
		finalcutpro_timeline_selectalltimelineclips_label		=	"Timeline: Select All Timeline Clips",
		finalcutpro_timeline_stabilization_label				=	"Inspector: Stablization",
		finalcutpro_timeline_titles_label						=	"Timeline: Titles",
		finalcutpro_timeline_transitions_label					=	"Timeline: Transitions",
		finalcutpro_timeline_videoeffects_label					=	"Timeline: Video Effects",
		finalcutpro_timeline_zoomtoselection_label				=	"Timeline: Zoom to Selection",
		finalcutpro_touchbar_virtual_label						=	"Virtual Touch Bar",
		finalcutpro_touchbar_widgets_colorboard_label			=	"Widget: Color Board",
		finalcutpro_touchbar_widgets_zoom_label					= 	"Widget: Timeline Zoom",
		finalcutpro_viewer_showtimecode_label					=	"Viewer: Show Timecode",
		finalcutpro_viewer_showtimelineinplayer_label			=	"Viewer: Show Timeline in Player",
		finalcutpro_viewer_timecodeoverlay_label				=	"Viewer: Timecode Overlay",
		finalcutpro_watchers_preferences_label					=	"Watchers: Preferences",
		finalcutpro_watchers_version_label						=	"Watchers: Version",
		finalcutpro_watchfolders_panels_fcpxml_label			=	"Watch Folders: XML",
		finalcutpro_watchfolders_panels_media_label				=	"Watch Folders: Media",

	--------------------------------------------------------------------------------
	-- COMMAND TITLES:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Groups:
		--------------------------------------------------------------------------------
		fcpx_command_group										=	"FCPX",
		global_command_group									=	"Global",

		--------------------------------------------------------------------------------
		-- Global:
		--------------------------------------------------------------------------------
		cpLaunchFinalCutPro_title								=	"Launch Final Cut Pro",
		cpSetupWatchFolders_title								= 	"Setup Watch Folders",
		cpPreferences_title										=	"Preferences",
		cpOpenErrorLog_title									=	"Open Error Log",
		cpTrashPreferences_title								=	"Trash Preferences",
		cpOpenPluginsFolder_title								= 	"Open Plugins Folder",
		cpUserGuide_title										=	"User Guide",
		cpFeedback_title										=	"Provide Feedback",
		cpDeveloperGuide_title									=	"Developer Guide",
		cpTouchBar_title										=	"Toggle Touch Bar",
		cpStreamDeck_title										=	"Toggle Stream Deck",
		cpMIDI_title											=	"Toggle MIDI Controls",
		cpCredits_title											=	"Credits",
		cpGlobalConsole_title									=	"Activate Global Console",

		--------------------------------------------------------------------------------
		-- Final Cut Pro:
		--------------------------------------------------------------------------------
		cpStabilizationToggle_title								=	"Toggle Stabilization",
		cpStabilizationEnable_title								=	"Enable Stabilization",
		cpStabilizationDisable_title							=	"Disable Stabilization",

		cpText2Speech_title										=	"Activate Text to Speech Tool",

		cpScrollingTimeline_title								=	"Toggle Scrolling Timeline",
		cpLockPlayhead_title									=	"Toggle Playhead Lock",

		cpAudioEffect1_title									=	"Apply Audio Effect 1",
		cpAudioEffect2_title									=	"Apply Audio Effect 2",
		cpAudioEffect3_title									=	"Apply Audio Effect 3",
		cpAudioEffect4_title									=	"Apply Audio Effect 4",
		cpAudioEffect5_title									=	"Apply Audio Effect 5",
		cpAudioEffect6_title									=	"Apply Audio Effect 6",
		cpAudioEffect7_title									=	"Apply Audio Effect 7",
		cpAudioEffect8_title									=	"Apply Audio Effect 8",
		cpAudioEffect9_title									=	"Apply Audio Effect 9",

		cpVideoEffect1_title									=	"Apply Video Effect 1",
		cpVideoEffect2_title									=	"Apply Video Effect 2",
		cpVideoEffect3_title									=	"Apply Video Effect 3",
		cpVideoEffect4_title									=	"Apply Video Effect 4",
		cpVideoEffect5_title									=	"Apply Video Effect 5",
		cpVideoEffect6_title									=	"Apply Video Effect 6",
		cpVideoEffect7_title									=	"Apply Video Effect 7",
		cpVideoEffect8_title									=	"Apply Video Effect 8",
		cpVideoEffect9_title									=	"Apply Video Effect 9",

		cpTransition1_title										=	"Apply Transition 1",
		cpTransition2_title										=	"Apply Transition 2",
		cpTransition3_title										=	"Apply Transition 3",
		cpTransition4_title										=	"Apply Transition 4",
		cpTransition5_title										=	"Apply Transition 5",
		cpTransition6_title										=	"Apply Transition 6",
		cpTransition7_title										=	"Apply Transition 7",
		cpTransition8_title										=	"Apply Transition 8",
		cpTransition9_title										=	"Apply Transition 9",

		cpGenerator1_title										=	"Apply Generator 1",
		cpGenerator2_title										=	"Apply Generator 2",
		cpGenerator3_title										=	"Apply Generator 3",
		cpGenerator4_title										=	"Apply Generator 4",
		cpGenerator5_title										=	"Apply Generator 5",
		cpGenerator6_title										=	"Apply Generator 6",
		cpGenerator7_title										=	"Apply Generator 7",
		cpGenerator8_title										=	"Apply Generator 8",
		cpGenerator9_title										=	"Apply Generator 9",

		cpTitle1_title											=	"Apply Title 1",
		cpTitle2_title											=	"Apply Title 2",
		cpTitle3_title											=	"Apply Title 3",
		cpTitle4_title											=	"Apply Title 4",
		cpTitle5_title											=	"Apply Title 5",
		cpTitle6_title											=	"Apply Title 6",
		cpTitle7_title											=	"Apply Title 7",
		cpTitle8_title											=	"Apply Title 8",
		cpTitle9_title											=	"Apply Title 9",

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
		cpPuckDirection_customTitle								=	"Select %{panel} Puck %{count} & %{direction}",

		cpToggleColorBoard_title								=	"Toggle Color Board Panel",

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

		cpToggleTimecodeOverlays_title							=	"Toggle Timecode Overlay",
		cpShowTimelineInPlayer_title							=	"Show Timeline in Player",
		cpAllowTasksDuringPlayback_title						=	"Toggle Rendering During Playback",

		cpShowProjectTimecodeTop_title 							= 	"Show Project Timecode Top",
		cpShowProjectTimecodeBottom_title						=	"Show Project Timecode Bottom",
		cpShowSourceTimecodeTop_title							=	"Show Source Timecode Top",
		cpShowSourceTimecodeBottom_title						= 	"Show Source Timecode Bottom",

		cpBatchExportFromBrowser_title							=	"Batch Export from Browser",
		cpChangeSmartCollectionsLabel_title						=	"Change Smart Collections Label",
		cpConsole_title											=	"Activate Console",
		cpCopyWithCustomLabel_title								=	"Copy with Custom Label",
		cpCopyWithCustomLabelAndFolder_title					=	"Copy with Custom Label and Folder",
		cpHUD_title												=	"Toggle HUD",
		cpSingleMatchFrameAndHighlight_title					=	"Single Match Frame and Highlight",
		cpToggleTouchBar_title									=	"Toggle Virtual Touch Bar (FCPX)",
		cpGlobalToggleTouchBar_title							=	"Toggle Virtual Touch Bar (Global)",
		cpToggleVoiceCommands_title								=	"Toggle Voice Commands",

		cpDisableWaveforms_title								=	"Toggle Waveform Drawing",

		cpBugReport_title										=	"Report Final Cut Pro Bug to Apple",
		cpFeatureRequest_title									=	"Suggest Final Cut Pro Feature to Apple",

	}
}