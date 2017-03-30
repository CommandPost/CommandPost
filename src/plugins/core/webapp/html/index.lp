<%

	local queryString = {}
	cgilua.urlcode.parsequery(hsminweb["CGIVariables"]["QUERY_STRING"], queryString)

	if next(queryString) ~= nil then
		if queryString["action"] and queryString["group"] then
			_G["webAppAction"](queryString["group"], queryString["action"])
		else
			hsminweb.log.df("Unknown Query String")
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
			<!-- Your first view, it is also a .tab and should have "active" class to make it visible by default-->
			<div id="view-1" class="view view-main tab active">
				<!-- We can make with view with navigation, let's add Top Navbar-->
				<div class="navbar">
					<div class="navbar-inner">
						<div class="center sliding">
							CommandPost
						</div>
					</div>
				</div>
				<!-- Pages-->
				<div class="pages navbar-through">
					<!-- Page, data-page contains page name-->
					<div data-page="index-1" class="page">
						<!-- We can make with view with navigation, let's add Top Navbar-->
						<div class="navbar">
							<div class="navbar-inner">
								<div class="center sliding">
									Actions
								</div>
							</div>
						</div>
						<!-- Search Bar -->
						<form data-search-list=".list-block-search" data-search-in=".item-title" class="searchbar searchbar-init">
							<div class="searchbar-input">
								<input type="search" placeholder="Search">
								<a href="#" class="searchbar-clear">
								</a>
							</div>
							<a href="#" class="searchbar-cancel">
								Cancel
							</a>
						</form>
						<!-- Search Bar overlay -->
						<div class="searchbar-overlay"></div>
						<div class="page-content">
							<!-- This block will be displayed if nothing found -->
							<div class="content-block searchbar-not-found">
								<div class="content-block-inner">
									Nothing found
								</div>
							</div>
							<!-- This block will be displayed if anything found, and this list block is used a searbar target -->
							<div class="list-block list-block-search searchbar-found">
							<!-- -------------------------------- BEGIN ACTIONS -------------------------------- -->
								<%
									local commandaction = webviewEnvironment["commandaction"]
									local choices = commandaction.choices()["_choices"]
									table.sort(choices, function(a, b) return a.text < b.text end)

									for _, v in pairs(choices) do

										local id 		= v["params"]["id"] or nil
										local group 	= v["params"]["group"] or "Unknown"
										local text 		= v["text"] or "Unknown"

										if id and group and text then %>
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
									end
									%>
						<!-- -------------------------------- END ACTIONS -------------------------------- -->
					</div>
				</div>
			</div>
		</div>
	</div>
	<!-- Second view (for second wrap)-->
	<div id="view-2" class="view tab">
		<!-- We can make with view with navigation, let's add Top Navbar-->
		<div class="navbar">
			<div class="navbar-inner">
				<div class="center sliding">
					CommandPost
				</div>
			</div>
		</div>
		<div class="pages navbar-through">
			<div data-page="index-2" class="page">
				<div class="page-content">
					<!-- -------------------------------- BEGIN CONTROLS -------------------------------- -->
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
					<!-- -------------------------------- END CONTROLS -------------------------------- -->



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
<div id="view-3" class="view tab">
<!-- We can make with view with navigation, let's add Top Navbar-->
	<div class="navbar">
		<div class="navbar-inner">
			<div class="center sliding">
				CommandPost
			</div>
		</div>
	</div>
	<div class="pages navbar-through">
		<div data-page="index-3" class="page">
			<div class="page-content">
				<!-- -------------------------------- BEGIN TAGS -------------------------------- -->
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
			<!-- -------------------------------- END TAGS -------------------------------- -->
		</div>
	</div>
</div>
</div>
<div id="view-4" class="view tab">
	<div class="pages navbar-fixed">
		<div data-page="index-4" class="page">
			<div class="navbar">
				<div class="navbar-inner">
					<div class="center">
						CommandPost
					</div>
				</div>
			</div>
			<div class="page-content">
				<div class="content-block">
					<p>
						WebApp currently has no settings... yet.
					</p>
				</div>
			</div>
		</div>
	</div>
</div>
<!-- Bottom Tabbar-->
<div class="toolbar tabbar tabbar-labels">
	<div class="toolbar-inner">
		<a href="#view-1" class="tab-link active">
		<i class="f7-icons">
			play_round
		</i>
	<span class="tabbar-label">
		Actions
	</span>
</a>
<a href="#view-2" class="tab-link">
<i class="f7-icons">
	filter-fill
</i>
<span class="tabbar-label">
Controls
</span>
</a>
<a href="#view-3" class="tab-link">
<i class="f7-icons">
	tags
</i>
<span class="tabbar-label">
Tags
</span>
</a>
<a href="#view-4" class="tab-link">
<i class="f7-icons">
	gear_fill
</i>
<span class="tabbar-label">
Settings
</span>
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
