<%

	local inspect = require("hs.inspect")

	local commands = require("cp.commands")


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
			hsminweb.log.df("CUSTOM MARKER: %s", queryString["custom_marker"])
		else
			hsminweb.log.df("Unknown Query String: %s", queryString)
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

							<div class="content-block-title">Controls</div>
							<div class="list-block">
								<ul>
									<li>
										<a href="#" class="item-link" onclick="controls_play()">
										<div class="item-content">
											<div class="item-inner">
												<div class="item-title">Play</div>
											</div>
										</div>
									</a>
									<script>
										function controls_play() {
											var xhttp = new XMLHttpRequest();
											xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?group=fcpx&action=cpPlay", true);
											xhttp.send();
										}
									</script>
									</li>
								</ul>
							</div>

							<div class="content-block-title">Exposure</div>
							<div class="list-block">
							  <ul>

								<!-- Slider (Range input) -->
								<li>
								  <div class="item-content">
									<div class="item-media"><i class="icon f7-icons">filter</i></div>
									<div class="item-inner">
									  <div class="item-title label">Global</div>
									  <div class="item-input">
										<div class="range-slider">
										  <input type="range" min="0" max="100" value="50" step="0.1">
										</div>
									  </div>
									</div>
								  </div>
								</li>

								<!-- Slider (Range input) -->
								<li>
								  <div class="item-content">
									<div class="item-media"><i class="icon f7-icons">filter</i></div>
									<div class="item-inner">
									  <div class="item-title label">Shadows</div>
									  <div class="item-input">
										<div class="range-slider">
										  <input type="range" min="0" max="100" value="50" step="0.1">
										</div>
									  </div>
									</div>
								  </div>
								</li>

								<!-- Slider (Range input) -->
								<li>
								  <div class="item-content">
									<div class="item-media"><i class="icon f7-icons">filter</i></div>
									<div class="item-inner">
									  <div class="item-title label">Midtones</div>
									  <div class="item-input">
										<div class="range-slider">
										  <input type="range" min="0" max="100" value="50" step="0.1">
										</div>
									  </div>
									</div>
								  </div>

								<!-- Slider (Range input) -->
								<li>
								  <div class="item-content">
									<div class="item-media"><i class="icon f7-icons">filter</i></div>
									<div class="item-inner">
									  <div class="item-title label">Highlights</div>
									  <div class="item-input">
										<div class="range-slider">
										  <input type="range" min="0" max="100" value="50" step="0.1">
										</div>
									  </div>
									</div>
								  </div>

							  </ul>
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
						<div class="left"><a href="#" class="link">Add</a></div>
						<div class="center sliding">Markers</div>
				        <div class="right"><a href="#" class="link toggle-sortable icon-only">Sort</a></div>
					</div>
				</div>

				<div class="pages navbar-through">
					<div data-page="index-3" class="page">
						<div class="page-content">
							<div class="content-block-title">Markers</div>

							<!-- Sortable list  -->
							<div class="list-block sortable">
								<ul>

									<%
									local customMarkers = {}
									customMarkers[#customMarkers + 1] = "This is a test"
									customMarkers[#customMarkers + 1] = "Another Test"
									customMarkers[#customMarkers + 1] = "Yet Another Test"

									table.sort(customMarkers, function(a, b) return a < b end)

									for i, v in pairs(customMarkers) do
									%>

								  	<li>
										<a href="#" class="item-link" onclick="markers_<%= tostring(i) %>()">
											<div class="item-content">
												<div class="item-inner">
													<div class="item-title"><%= v %></div>
												</div>
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

			<!-- TAGS VIEW: -->
			<div id="view-4" class="view tab">
				<!-- We can make with view with navigation, let's add Top Navbar-->
				<div class="navbar">
					<div class="navbar-inner">
						<div class="center sliding">Tags</div>
					</div>
				</div>

				<div class="pages navbar-through">
					<div data-page="index-4" class="page">
						<div class="page-content">
							<div class="content-block-title">Tags</div>
							<div class="list-block">
								<ul>
									<li>
										<a href="#" class="item-link" onclick="tags_example()">
											<div class="item-content">
												<div class="item-inner">
													<div class="item-title">Example Tag</div>
												</div>
											</div>
										</a>
										<script>
											function tags_example() {
												var xhttp = new XMLHttpRequest();
												xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?group=fcpx&action=cpHighlightBrowserPlayhead", true);
												xhttp.send();
											}
										</script>
									</li>
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
						<span class="tabbar-label">Tags</span>
					</a>
					<a href="#view-5" class="tab-link">
						<i class="f7-icons">gear_fill</i>
						<span class="tabbar-label">Settings</span>
					</a>
				</div>
			</div>

		</div>

		<!-- Path to Framework7 Library JS-->
		<script type="text/javascript" src="js/framework7.min.js"></script>

		<!-- Path to your app js-->
		<script type="text/javascript" src="js/commandpost.js"></script>

	</body>
</html>
