<%

local log = require("hs.logger").new("webappTemplate")
local inspect = require("hs.inspect")

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

	<meta name="apple-mobile-web-app-title" content="CommandPost">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
	<link rel="apple-touch-icon" href="images/CommandPost.png">

    <title>CommandPost</title>

    <!-- Path to Framework7 Library CSS-->
    <link rel="stylesheet" href="css/framework7.ios.min.css">
	<link rel="stylesheet" href="css/framework7-icons.css">

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
        <p>Left panel content goes here</p>
      </div>
    </div>
    <!-- Right panel with cover effect-->
    <div class="panel panel-right panel-cover">
      <div class="content-block">
        <p>Right panel content goes here</p>
      </div>
    </div>

    <!-- Views, and they are tabs-->

    <!-- We need to set "toolbar-through" class on it to keep space for our tab bar-->
    <div class="views tabs toolbar-through">

      <!-- Your first view, it is also a .tab and should have "active" class to make it visible by default-->
      <div id="view-1" class="view view-main tab active">
        <!-- We can make with view with navigation, let's add Top Navbar-->
        <div class="navbar">
          <div class="navbar-inner">
            <div class="center sliding">CommandPost</div>
          </div>
        </div>

        <!-- Pages-->
        <div class="pages navbar-through">
          <!-- Page, data-page contains page name-->
          <div data-page="index-1" class="page">
            <!-- Scrollable page content-->
            <div class="page-content">

			  <!-- BEGIN ACTIONS -->
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
              <!-- END ACTIONS -->


            </div>
          </div>
        </div>
      </div>



      <!-- Second view (for second wrap)-->
      <div id="view-2" class="view tab">
        <!-- We can make with view with navigation, let's add Top Navbar-->
        <div class="navbar">
          <div class="navbar-inner">
            <div class="center sliding">CommandPost</div>
          </div>
        </div>
        <div class="pages navbar-through">
          <div data-page="index-2" class="page">
            <div class="page-content">

              <!-- BEGIN CONTROLS -->
              <div class="content-block-title">Controls</div>
			  <div class="list-block">
				<ul>
				  <li><a href="#" class="item-link" onclick="highlightBrowserPlayheadX()">
						  <div class="item-content">
							<div class="item-inner">
							  <div class="item-title">Some Control</div>
							</div>
						  </div>
					 </a>
					<script>
					function highlightBrowserPlayheadX() {
						var xhttp = new XMLHttpRequest();
						xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?action=cpHighlightBrowserPlayhead", true);
						xhttp.send();
					}
					</script>
				  </li>
				</ul>
			  </div>
              <!-- END CONTROLS -->

            </div>
          </div>
        </div>
      </div>
      <div id="view-3" class="view tab">
        <!-- We can make with view with navigation, let's add Top Navbar-->
        <div class="navbar">
          <div class="navbar-inner">
            <div class="center sliding">CommandPost</div>
          </div>
        </div>
        <div class="pages navbar-through">
          <div data-page="index-3" class="page">
            <div class="page-content">

              <!-- BEGIN ACTIONS -->
              <div class="content-block-title">Tags</div>
			  <div class="list-block">
				<ul>
				  <li><a href="#" class="item-link" onclick="highlightBrowserPlayheadY()">
						  <div class="item-content">
							<div class="item-inner">
							  <div class="item-title">Some Tags</div>
							</div>
						  </div>
					 </a>
					<script>
					function highlightBrowserPlayheadY() {
						var xhttp = new XMLHttpRequest();
						xhttp.open("GET", "http://<%= hsminweb["CGIVariables"]["HTTP_HOST"] %>/?action=cpHighlightBrowserPlayhead", true);
						xhttp.send();
					}
					</script>
				  </li>
				</ul>
			  </div>
              <!-- END ACTIONS -->

            </div>
          </div>
        </div>
      </div>
      <div id="view-4" class="view tab">
        <div class="pages navbar-fixed">
          <div data-page="index-4" class="page">
            <div class="navbar">
              <div class="navbar-inner">
                <div class="center">CommandPost</div>
              </div>
            </div>
            <div class="page-content">
              <div class="list-block">
                <ul>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-name"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Name</div>
                        <div class="item-input">
                          <input type="text" placeholder="Your name">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-email"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">E-mail</div>
                        <div class="item-input">
                          <input type="email" placeholder="E-mail">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-url"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">URL</div>
                        <div class="item-input">
                          <input type="url" placeholder="URL">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-password"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Password</div>
                        <div class="item-input">
                          <input type="password" placeholder="Password">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-tel"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Phone</div>
                        <div class="item-input">
                          <input type="tel" placeholder="Phone">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-gender"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Gender</div>
                        <div class="item-input">
                          <select>
                            <option>Male</option>
                            <option>Female</option>
                          </select>
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-calendar"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Birth date</div>
                        <div class="item-input">
                          <input type="date" placeholder="Birth day" value="2014-04-30">
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-toggle"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Switch</div>
                        <div class="item-input">
                          <label class="label-switch">
                            <input type="checkbox">
                            <div class="checkbox"></div>
                          </label>
                        </div>
                      </div>
                    </div>
                  </li>
                  <li>
                    <div class="item-content">
                      <div class="item-media"><i class="icon icon-form-settings"></i></div>
                      <div class="item-inner">
                        <div class="item-title label">Slider</div>
                        <div class="item-input">
                          <div class="range-slider">
                            <input type="range" min="0" max="100" value="50" step="0.1">
                          </div>
                        </div>
                      </div>
                    </div>
                  </li>
                </ul>
              </div>
              <div class="content-block">
                <p>Mauris commodo lacus at nisl lacinia, nec facilisis erat rhoncus. Sed eget pharetra nunc. Aenean vitae vehicula massa, sed sagittis ante. Quisque luctus nec velit dictum convallis. Nulla facilisi. Ut sed erat nisi. Donec non dolor massa. Mauris malesuada dolor velit, in suscipit leo consectetur vitae. Duis tempus ligula non eros pretium condimentum. Cras sed dolor odio.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Bottom Tabbar-->
      <div class="toolbar tabbar tabbar-labels">
        <div class="toolbar-inner"><a href="#view-1" class="tab-link active"> <i class="f7-icons">play_round</i><span class="tabbar-label">Actions</span></a><a href="#view-2" class="tab-link"><i class="f7-icons">filter-fill</i><span class="tabbar-label">Controls</span></a><a href="#view-3" class="tab-link"> <i class="f7-icons">tags</i><span class="tabbar-label">Tags</span></a><a href="#view-4" class="tab-link"> <i class="f7-icons">gear_fill</i><span class="tabbar-label">Settings</span></a></div>
      </div>
    </div>
    <!-- Path to Framework7 Library JS-->
    <script type="text/javascript" src="js/framework7.min.js"></script>
    <!-- Path to your app js-->
    <script type="text/javascript" src="js/my-app.js"></script>
  </body>
</html>