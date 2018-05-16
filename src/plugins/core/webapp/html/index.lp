<%
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  C O M M A N D P O S T    W E B A P P                      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- The CommandPost Web App.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log 			= hsminweb.log

local eventtap 		= require("hs.eventtap")
local inspect 		= require("hs.inspect")
local pasteboard	= require("hs.pasteboard")
local uuid			= require("hs.host").uuid

local fcp 			= require("cp.apple.finalcutpro")
local commands 		= require("cp.commands")
local config 		= require("cp.config")

local ARRAY_DELIM = "||"
local UNDEFINED = "_undefined"

--------------------------------------------------------------------------------
--
-- FUNCTIONS:
--
--------------------------------------------------------------------------------

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local function isNumberString(value)
	return value:match("^[0-9\\.\\-]$") ~= nil
end

local function thawParams(params)
	-- defrost any arrays
	local thawed = {}
	for key,value in pairs(params) do
		if value:find(ARRAY_DELIM) then
			value = split(value, ARRAY_DELIM)
		elseif isNumberString(value) then
			value = tonumber(value)
		end
		thawed[key] = value
	end
	return thawed
end

--------------------------------------------------------------------------------
-- GET COMMANDS:
--------------------------------------------------------------------------------
local function getCommands()

	local result = {}

	for _,groupId in ipairs(commands.groupIds()) do

		local group = commands.group(groupId)
		local cmds = group:getAll()

		for id,cmd in pairs(cmds) do
			if cmd:getTitle() then
				result[#result+1] = {
					id = cmd:id(),
					group = groupId,
					text = cmd:getTitle()
				}
			end
		end

	end

	table.sort(result, function(a, b) return a.text < b.text end)

	return result
end

local queryString = {}
cgilua.urlcode.parsequery(hsminweb["CGIVariables"]["QUERY_STRING"], queryString)

if next(queryString) ~= nil then
	if queryString["action"] and queryString["group"] then

		hsminweb.log.df("Action Recieved: %s %s", queryString["group"], queryString["action"])
		commands.group(queryString["group"]):get(queryString["action"]):pressed()

	elseif queryString["custom_marker"] then
		local markerString = queryString["custom_marker"]

		if fcp:isShowing() then

			log.df("Adding Marker: %s", markerString)

			fcp:selectMenu({"Mark", "Markers", "Add Marker"})
			fcp:selectMenu({"Mark", "Markers", "Add Marker"})
			local originalPasteboard = pasteboard.getContents()
			pasteboard.setContents(markerString)
			fcp:selectMenu({"Edit", "Paste"})
			eventtap.keyStroke({}, "return")
			pasteboard.setContents(originalPasteboard)

		else
			log.df("Final Cut Pro is not active.")
		end
	elseif queryString["menupath"] then
		local menupath = queryString["menupath"]
		if fcp:isShowing() then
			log.df("Triggering Menu Item: %s", menupath)
			fcp:selectMenu(thawParams({menupath})[1])
		else
			log.df("Final Cut Pro is not active.")
		end
	elseif queryString["keyword"] then
		local keyword = queryString["keyword"]
		log.df("Adding Keyword: %s", keyword)

		local keywordEditorOpen = fcp:menu():isEnabled({"Mark", "Hide Keyword Editor"})

		if not keywordEditorOpen then
			fcp:selectMenu({"Mark", "Show Keyword Editor"})
		end

		local originalPasteboard = pasteboard.getContents()
		pasteboard.setContents(keyword)
		fcp:selectMenu({"Edit", "Paste"})
		eventtap.keyStroke({}, "return")
		pasteboard.setContents(originalPasteboard)

	else
		log.df("Unknown Query String: %s", queryString)
	end
end

%>
<!DOCTYPE html>
<html>
	<head>

		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, minimal-ui">
		<meta name="apple-mobile-web-app-title" content="CommandPost"> <meta name="apple-mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-status-bar-style" content="black"> <link rel="apple-touch-icon" href="images/CommandPost.png">

		<title>CommandPost</title>

		<!-- Path to Framework7 Library CSS -->
		<link rel="stylesheet" href="css/framework7.ios.min.css"> <link rel="stylesheet" href="css/framework7-icons.css">

		<!-- CommandPost Style Sheet -->
		<link rel="stylesheet" href="css/commandpost.css">

	</head>
	<body>

		<!-- Status bar overlay for fullscreen mode-->
		<div class="statusbar-overlay"></div>

		<!-- Panels overlay-->
		<div class="panel-overlay"></div>

		<!-- Views, and they are tabs-->
		<!-- We need to set "toolbar-through" class on it to keep space for our tab bar-->
		<div class="views tabs toolbar-through">

			<!-- COMMANDS VIEW: -->
			<div id="view-1" class="view view-main tab active">

				<div class="navbar">
					<div class="navbar-inner">
						<div class="center sliding">Commands</div>
					</div>
				</div>

				<!-- Pages-->
				<div class="pages navbar-through">

					<!-- Page, data-page contains page name-->
					<div data-page="index-1" class="page">

						<!-- Search Bar -->
						<form data-search-list=".list-block-search" data-search-in=".item-title" class="searchbar searchbar-init">
							<div class="searchbar-input">
								<input type="search" placeholder="Search">
								<a href="#" class="searchbar-clear"></a>
							</div>
							<a href="#" class="searchbar-cancel">Cancel</a>
						</form>

						<!-- Search Bar overlay -->
						<div class="searchbar-overlay"></div>
						<div class="page-content">
							<!-- This block will be displayed if nothing found -->
							<div class="content-block searchbar-not-found">
								<div class="content-block-inner">Nothing found</div>
							</div>

							<!-- This block will be displayed if anything found, and this list block is used a searbar target -->
							<div class="list-block list-block-search searchbar-found">

								<%

									local allCommands = getCommands()

									for _, v in ipairs(allCommands) do

										local id 		= v["id"]
										local group 	= v["group"]
										local text 		= v["text"]

								%>
								<ul>
									<a href="#" class="item-link" onclick="action_<%= id %>()">
										<li class="item-content">
											<div class="item-inner">
												<div class="item-title"><%= text %></div>
											</div>
										</li>
									</a>
								</ul>
								<script>
									function action_<%= id %>() {
										var xhttp = new XMLHttpRequest();
										xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?group=<%= group %>&action=<%= id %>", true);
										xhttp.send();
									}
								</script>
								<%
									end
								%>

							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- CONTROLS VIEW: -->
			<div id="view-2" class="view tab">
				<!-- We can make with view with navigation, let's add Top Navbar-->
				<div class="navbar">
					<div class="navbar-inner">
						<div class="center sliding">Controls</div>
					</div>
				</div>
				<div class="pages navbar-through">
					<div data-page="index-2" class="page">
						<div class="page-content">

							<div class="content-block-title">Playback</div>
							<div class="list-block">
								<%
								local controls = {
									["Play"]					= "View||Playback||Play",
									["Play Around"] 			= "View||Playback||Play%20Around",
									["Play from Beginning"]		= "View||Playback||Play%20from%20Beginning",
									["Play to End"]				= "View||Playback||Play%20to%20End",
									["Play Full Screen"]			= "View||Playback||Play%20Full%20Screen",
									["Loop Playback"]			= "View||Playback||Loop%20Playback",
								}

						    	for i, v in pairs(controls) do
						    		local id = string.gsub(uuid(), "-", "")
								%>
								<ul>
									<li>
										<a href="#" class="item-link" onclick="c<%= id %>()">
											<div class="item-content">
												<div class="item-inner">
													<div class="item-title"><%= i %></div>
												</div>
											</div>
										</a>
										<script>
											function c<%= id %>() {
												var xhttp = new XMLHttpRequest();
												xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?menupath=<%= v %>", true);
												xhttp.send();
											}
										</script>
									</li>
								</ul>
								<% end %>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- MARKERS VIEW: -->
			<div id="view-3" class="view tab">

				<!-- We can make with view with navigation, let's add Top Navbar-->
				<div class="navbar">
					<div class="navbar-inner">
						<div class="left"><a href="#" class="link addMarkerButton">Add</a></div>
						<div class="center sliding">Markers</div>
				        <div class="right"><a href="#" class="link toggle-sortable icon-only">Sort</a></div>
					</div>
				</div>

				<div class="pages navbar-through">
					<div data-page="index-3" class="page">
						<div class="page-content pull-to-refresh-content" data-ptr-distance="55">
							<!-- Default pull to refresh layer-->
							<div class="pull-to-refresh-layer">
								<div class="preloader"></div>
								<div class="pull-to-refresh-arrow"></div>
							</div>
							<div class="content-block-title">Markers</div>

							<!-- Sortable list  -->
							<div class="list-block sortable">
								<ul>
									<%
									local customMarkers = config.get("customMarkers", {"Good Take", "Interior", "Exterior"})
									table.sort(customMarkers, function(a, b) return a < b end)

									for i, v in pairs(customMarkers) do
									%>

								  	<li class="swipeout">
										<a href="#" class="item-link" onclick="markers_<%= tostring(i) %>()">
											<div class="swipeout-content item-content">
												<div class="item-inner">
													<div class="item-title"><%= v %></div>
												</div>
											</div>
											<div class="swipeout-actions-right">
												<a href="#" class="action1">Rename</a>
												<a href="#" class="swipeout-delete" data-confirm="Are you sure want to delete this item?" data-confirm-title="Delete?" data-close-on-cancel="true">Delete</a>
											</div>
										</a>
										<script>
											function markers_<%= tostring(i) %>() {
												var xhttp = new XMLHttpRequest();
												xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?custom_marker=<%= cgilua.urlcode.escape(v) %>", true);
												xhttp.send();
											}
										</script>

										<!-- Sortable handler  -->
										<div class="sortable-handler"></div>
									</li>
									<%
									end
									%>
								</ul>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- KEYWORDS VIEW: -->
			<div id="view-4" class="view tab">

				<!-- We can make with view with navigation, let's add Top Navbar-->
				<div class="navbar">
					<div class="navbar-inner">
						<div class="left"><a href="#" class="link addMarkerButton">Add</a></div>
						<div class="center sliding">Keywords</div>
				        <div class="right"><a href="#" class="link toggle-sortable icon-only">Sort</a></div>
					</div>
				</div>

				<div class="pages navbar-through">
					<div data-page="index-4" class="page">
						<div class="page-content pull-to-refresh-content" data-ptr-distance="55">
							<!-- Default pull to refresh layer-->
							<div class="pull-to-refresh-layer">
								<div class="preloader"></div>
								<div class="pull-to-refresh-arrow"></div>
							</div>
							<div class="content-block-title">Keywords</div>

							<!-- Sortable list  -->
							<div class="list-block sortable">
								<ul>
									<%
									local customKeywords = config.get("customKeywords", {"Good Take", "Interior", "Exterior"})
									table.sort(customKeywords, function(a, b) return a < b end)

									for i, v in pairs(customKeywords) do
									%>

								  	<li class="swipeout">
										<a href="#" class="item-link" onclick="keywords_<%= tostring(i) %>()">
											<div class="swipeout-content item-content">
												<div class="item-inner">
													<div class="item-title"><%= v %></div>
												</div>
											</div>
											<div class="swipeout-actions-right">
												<a href="#" class="action1">Rename</a>
												<a href="#" class="swipeout-delete" data-confirm="Are you sure want to delete this item?" data-confirm-title="Delete?" data-close-on-cancel="true">Delete</a>
											</div>
										</a>
										<script>
											function keywords_<%= tostring(i) %>() {
												var xhttp = new XMLHttpRequest();
												xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?keyword=<%= cgilua.urlcode.escape(v) %>", true);
												xhttp.send();
											}
										</script>

										<!-- Sortable handler  -->
										<div class="sortable-handler"></div>
									</li>
									<%
									end
									%>
								</ul>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- SETTINGS VIEW: -->
			<div id="view-5" class="view tab">
				<div class="pages navbar-fixed">
					<div data-page="index-5" class="page">
						<div class="navbar">
							<div class="navbar-inner">
								<div class="center">Settings</div>
							</div>
						</div>
						<div class="page-content">
							<div class="content-block">
								<p>WebApp currently has no settings... yet.</p>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- BOTTOM TABBAR: -->
			<div class="toolbar tabbar tabbar-labels">
				<div class="toolbar-inner">
					<a href="#view-1" class="tab-link active">
						<i class="f7-icons">play_round</i>
						<span class="tabbar-label">Commands</span>
					</a>
					<a href="#view-2" class="tab-link">
						<i class="f7-icons">filter-fill</i>
						<span class="tabbar-label">Controls</span>
					</a>
					<a href="#view-3" class="tab-link">
						<i class="f7-icons">bookmark</i>
						<span class="tabbar-label">Markers</span>
					</a>
					<a href="#view-4" class="tab-link">
						<i class="f7-icons">tags</i>
						<span class="tabbar-label">Keywords</span>
					</a>
					<!-- DISABLING SETTINGS UNTIL WE ACTUALLY NEED THEM:
					<!--
					<a href="#view-5" class="tab-link">
						<i class="f7-icons">gear_fill</i>
						<span class="tabbar-label">Settings</span>
					</a>
					-->
				</div>
			</div>

		</div>

		<!-- Framework7 Library: -->
		<script type="text/javascript" src="js/framework7.min.js"></script>

		<script type="text/javascript">

			// Initialise WebApp:
			var myApp = new Framework7();

			// Export selectors engine:
			var $$ = Dom7;

			// Pull to refresh content
			var ptrContent = $$('.pull-to-refresh-content');

			// Add 'refresh' listener on it
			ptrContent.on('ptr:refresh', function (e) {
				location.reload();
			});

			// Add views
			var view1 = myApp.addView('#view-1');
			var view2 = myApp.addView('#view-2', {
				// Because we use fixed-through navbar we can enable dynamic navbar
				dynamicNavbar: true
			});
			var view3 = myApp.addView('#view-3');
			var view4 = myApp.addView('#view-4');
			var view5 = myApp.addView('#view-5');

			// Sortable Toggler:
			$$('.list-block.sortable').on('open', function () {
				$$('.toggle-sortable').text('Done');
			});
			$$('.list-block.sortable').on('close', function () {
				$$('.toggle-sortable').text('Sort');
			});

			$$('.addMarkerButton').on('click', function () {
			  myApp.alert('The Add Marker Button is under construction.');
			});

			$$('.action1').on('click', function () {
			  myApp.alert('The Rename Marker Button is under construction.');
			});

			$$('.swipeout').on('swipeout:deleted', function (e) {
			  myApp.alert('The Delete Marker Button is under construction. This item will come back to life on browser refresh.');
			});

		</script>

	</body>
</html>
