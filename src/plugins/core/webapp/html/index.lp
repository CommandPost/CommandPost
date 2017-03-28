<%

local log = require("hs.logger").new("webappTemplate")

log.df("WebApp Page Generating...")

local queryString = {}
cgilua.urlcode.parsequery(hsminweb["CGIVariables"]["QUERY_STRING"], queryString)

if queryString["action"] then
	_G["webAppAction"](queryString["action"])
else
	log.df("Unknown Query String")
end

%>
<!DOCTYPE html>
<html>
  <head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, minimal-ui">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="apple-mobile-web-app-status-bar-style" content="black">
	<title>CommandPost</title>
	<!-- Path to Framework7 Library CSS-->
	<link rel="stylesheet" href="dist/css/framework7.ios.min.css">
	<!-- Path to your custom app styles-->
	<link rel="stylesheet" href="css/my-app.css">
  </head>
  <body>
	<!-- Status bar overlay for fullscreen mode-->
	<div class="statusbar-overlay"></div>
	<!-- Panels overlay-->
	<div class="panel-overlay"></div>
	<!-- Left panel with reveal effect-->
	<div class="panel panel-left panel-reveal">
	  <div class="content-block">
		<p>Under Construction</p>
	  </div>
	</div>
	<!-- Views-->
	<div class="views">
	  <!-- Your main view, should have "view-main" class-->
	  <div class="view view-main">
		<!-- Top Navbar-->
		<div class="navbar">
		  <!-- Navbar inner for Index page-->
		  <div data-page="index" class="navbar-inner">
			<!-- We have home navbar without left link-->
			<div class="center sliding">CommandPost</div>
			<div class="right">
			  <!-- Right link contains only icon - additional "icon-only" class--><a href="#" class="link icon-only open-panel"> <i class="icon icon-bars"></i></a>
			</div>
		  </div>
		  <!-- Navbar inner for About page-->
		  <div data-page="about" class="navbar-inner cached">
			<div class="left sliding"><a href="#" class="back link"> <i class="icon icon-back"></i><span>Back</span></a></div>
			<div class="center sliding">About Us</div>
		  </div>
		  <!-- Navbar inner for Services page-->
		  <div data-page="services" class="navbar-inner cached">
			<div class="left sliding"><a href="#" class="back link"> <i class="icon icon-back"></i><span>Back</span></a></div>
			<div class="center sliding">Services</div>
		  </div>
		  <!-- Navbar inner for Form page-->
		  <div data-page="form" class="navbar-inner cached">
			<div class="left sliding"><a href="#" class="back link"> <i class="icon icon-back"></i><span>Back</span></a></div>
			<div class="center sliding">Form</div>
		  </div>
		</div>
		<!-- Pages, because we need fixed-through navbar and toolbar, it has additional appropriate classes-->
		<div class="pages navbar-through toolbar-through">
		  <!-- Index Page-->
		  <div data-page="index" class="page">
			<!-- Scrollable page content-->
			<div class="page-content">
			  <div class="content-block-title">Introducing WebApp</div>
			  <div class="content-block">
				<div class="content-block-inner">
				  <p>This is a proof-of-concept of a potential "WebApp" for CommandPost.</p>
				</div>
			  </div>
			  <div class="content-block-title">Actions</div>
			  <div class="list-block">
				<ul>
				  <li><a href="#" class="item-link" onclick="highlightBrowserPlayhead()">
						  <div class="item-content">
							<div class="item-inner">
							  <div class="item-title">Highlight Browser Playhead</div>
							</div>
						  </div>
					 </a>
					<script>
					function highlightBrowserPlayhead() {
						var xhttp = new XMLHttpRequest();
						xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?action=cpHighlightBrowserPlayhead", true);
						xhttp.send();
					}
					</script>
				  </li>
				</ul>
			  </div>
			</div>
		  </div>
		<!-- Bottom Toolbar-->
		<!--
		<div class="toolbar">
		  <div class="toolbar-inner"><a href="#" class="link">Link 1</a><a href="#" class="link">Link 2</a></div>
		</div>
		-->
	  </div>
	</div>
	<!-- Path to Framework7 Library JS-->
	<script type="text/javascript" src="dist/js/framework7.min.js"></script>
	<!-- Path to your app js-->
	<script type="text/javascript" src="js/my-app.js"></script>
  </body>
</html>