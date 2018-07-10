Exploring and Crafting Queries for `hs._asm.axuielement`
========================================================

Manipulating a macOS application through its Accessibility objects can be a confusing task. While many of the standard components used in macOS applications have default attributes and actions enabled, each application can modify or extend these in many different ways.

Each application has an application object which acts as its root... all other objects in an application are descendants of this root, but finding the specific object representing a specific button or specific visual element can be difficult and slow.  The purpose of this document is to provide some examples of how to use this module to locate specific objects within an application and then refine the search until it becomes fast enough that it can be used in a programatic fashion.

This module is by no means the only way to identify interesting accessibility objects and the path to them.  If you have Apple's XCode installed, then you can use the Accessibility Inspector application which is a part of XCode.  Others have also recommended [UI Browser](http://pfiddlesoft.com/uibrowser/index.html).

### Exploration Walkthrough

This walkthrough is provided as an example of how some of the functions provided by this module can be used to explore an application's accessibility objects and refine the queries so that they can be used in Hammerspoon modules and functions.  This is an iterative process -- since we know very little initially about how and what a particular application has chosen to provide through accessibility objects, we have to start with a little digging using the Hammerspoon console.

For starters, let's define a few shortcuts that we can use along the way (note, except where otherwise described, it is expected that you will select the entire code block and copy-paste it in its entirety into the console if you're trying this out yourself while reading this):

~~~lua
ax = require("hs._asm.axuielement")
inspect = require("hs.inspect")
timestamp = function(date)
    date = date or require"hs.timer".secondsSinceEpoch()
    return os.date("%F %T" .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
end
~~~

Sometimes you may know what you want... other times, you may just be exploring.  In this case, I started with just wanting to explore Safari and see what might be available...  For this example, I had Safari running with one window and it was displaying the Google search page (https://www.google.com).  Since we're starting at the topmost node of the application and iterating through the entire accessibility hierarchy, this will be slow... you would not normally want to do this under programatic control where speed is key.

~~~lua
print(timestamp())
s = ax.applicationElement(hs.application("Safari")) -- gets the top-level application object for Safari
print(inspect(s:buildTree()))
print(timestamp())
~~~

This results in something along the lines of:

~~~
2016-10-04 23:15:34.3726
<1>{
  AXChildren = { <2>{
      AXChildren = { <3>{
          AXChildren = {},
          AXChildrenInNavigationOrder = {},
          AXEnabled = true,
          AXFocused = false,

... cut for brevity ...

  AXRole = "AXApplication",
  AXRoleDescription = "application",
  AXTitle = "Safari",
  AXWindows = { <table 2>, <table 4> },
  _element = <userdata 3078> -- hs._asm.axuielement: AXApplication (0x600000850080)
}
2016-10-04 23:15:53.62
~~~

Not quite 20 seconds... definitely not something you want to do often, but useful to see just what information is provided.  I zeroed in on the AXLink objects as something that might be useful to be able to grab (not shown here, but if you run this yourself, you'll see them).

Next, we have two primary ways to look for the links... `hs._asm.axuielement:elementSearch` and `hs._asm.axuielement:searchPath`.

##### hs._asm.axuielement:elementSearch

`elementSearch` works by iterating through the accessibility hierarchy starting at the object the method is called on and returns all objects which match the specified criteria.  It *always* runs through the entire hierarchy (from it's starting point) and returns *all* matching objects:

~~~lua
print(timestamp())
links1 = s:elementSearch({ AXRole = "AXLink" })
print(timestamp())
print(#links1)
~~~

Results in:

~~~
2016-10-04 23:25:13.5056
2016-10-04 23:25:27.787
8
~~~

If we want to target just a specific URL, say the one for the Privacy policy:

~~~lua
print(timestamp())
l1 = s:elementSearch({ AXRole = "AXLink", AXURL = "/privacy/" }, true) -- true indicates a pattern search
print(timestamp())
print(#l1, l1[1]("URL"))
~~~

~~~
2016-10-04 23:27:54.9422
2016-10-04 23:28:09.8786
1	https://www.google.com/intl/en/policies/privacy/?fg=1
~~~

The time is about the same... roughly 15 seconds.

Because `elementSearch` always completely reviews the accessibility hierarchy available to it, it's best used when you're pretty close to the bottom already, or working with an application with a fairly small accessibility object set, such as the Dock:

~~~lua
print(timestamp())
d9 = ax.applicationElement(hs.application("Dock")):elementSearch({}) -- an empty criteria tells elementSearch to return all objects
print(timestamp())
print(#d9)
~~~

Results in:

~~~
2016-10-04 23:33:34.5958
2016-10-04 23:33:34.6571
20
~~~

##### hs._asm.axuielement:searchPath

`searchPath` returns one accessibility object at a time, but allows us to more narrowly target the query, resulting in a significant speedup.  Let's start with just our desired targets:

~~~lua
print(timestamp())
links2 = s:searchPath({ AXRole = "AXLink" })
print(timestamp())
print(links2 and links2("URL")) -- if links2 is not nil, print out it's AXURL attribute
~~~

This gives us:

~~~
2016-10-04 23:37:38.8488
2016-10-04 23:37:52.5825
https://mail.google.com/mail/?tab=wm
~~~

About the same, and we only got one answer instead of the 8 above... well, let's look closer at that answer:

~~~lua
inspect(links2:path())
~~~

Results in (cleaned up for easier reading):

~~~
{
    <userdata 1> -- hs._asm.axuielement: AXApplication (0x600001a4cff0),
    <userdata 2> -- hs._asm.axuielement: AXWindow (0x600001a4c4e0),
    <userdata 3> -- hs._asm.axuielement: AXSplitGroup (0x608000e4d7d0),
    <userdata 4> -- hs._asm.axuielement: AXTabGroup (0x600001a59350),
    <userdata 5> -- hs._asm.axuielement: AXGroup (0x600001a58a80),
    <userdata 6> -- hs._asm.axuielement: AXGroup (0x60800044e100),
    <userdata 7> -- hs._asm.axuielement: AXScrollArea (0x600001a49a50),
    <userdata 8> -- hs._asm.axuielement: AXWebArea (0x608000e560b0),
    <userdata 9> -- hs._asm.axuielement: AXGroup (0x600001a43d80),
    <userdata 10> -- hs._asm.axuielement: AXGroup (0x608001649120),
    <userdata 11> -- hs._asm.axuielement: AXLink (0x60000145dd30)
}
~~~

Now, let's try the query again, this time telling it how to proceed:

~~~lua
print(timestamp())
links2 = s:searchPath({
    { role = "AXApplication" }, -- key names that don't start with AX have it prepended
    { role = "AXWindow" },      -- however, you still have to put it in the value
    { role = "AXSplitGroup" },  -- or use a pattern search like this:
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXLink" }
})
print(timestamp())
print(links2 and links2("URL")) -- if links2 is not nil, print out it's AXURL attribute
~~~

Results in:

~~~
2016-10-04 23:45:28.5957
2016-10-04 23:45:28.8391
https://mail.google.com/mail/?tab=wm
~~~

Much better, but what about the other elements?  Well, `searchPath` also stores the search state information so that you can find the next matching element with `:next()`, as you can see here:

~~~lua
print(timestamp())
links2 = links2:next()
print(timestamp())
print(links2 and links2("URL"))
~~~

Giving us:

~~~
2016-10-04 23:48:15.3414
2016-10-04 23:48:15.3529
https://www.google.com/imghp?hl=en&tab=wi&ei=l330V_mkKYWkmwGR2JzQDw&ved=0EKouCBYoAQ
~~~

Let's get the rest of them:

~~~lua
for i = 3, #links1, 1 do
    print(i, timestamp())
    links2 = links2:next()
    print(i, timestamp())
    print(i, links2 and links2("URL"))
end
~~~

All well and good:

~~~
3	2016-10-04 23:52:20.4205
3	2016-10-04 23:52:20.4339
3	https://www.google.com/url?q=https://madeby.google.com/%3Futm_source%3Dhp%26utm_medium%3DHPP_link%26utm_term%3Dall%26utm_campaign%3Doo_ph_pmos:xhw_d&source=hpp&id=5085819&ct=3&usg=AFQjCNFEXGmt-kgWEJ2SNiv-RP4n8E7EAA&sa=X&ved=0ahUKEwi-wYuL5sLPAhXJ7SYKHXlXBRMQ8IcBCAY
4	2016-10-04 23:52:20.4391
4	2016-10-04 23:52:20.447
4	https://www.google.com/intl/en/policies/privacy/?fg=1
5	2016-10-04 23:52:20.4517
5	2016-10-04 23:52:20.4598
5	https://www.google.com/intl/en/policies/terms/?fg=1
6	2016-10-04 23:52:20.4644
6	2016-10-04 23:52:20.4723
6	https://www.google.com/intl/en/ads/?fg=1
7	2016-10-04 23:52:20.4769
7	2016-10-04 23:52:20.4847
7	https://www.google.com/services/?fg=1
8	2016-10-04 23:52:20.4893
8	2016-10-04 23:52:20.4978
8	https://www.google.com/intl/en/about.html?fg=1
~~~

But do it again:

~~~lua
print(timestamp())
links2 = links2:next()
print(timestamp())
print(links2 and links2("URL"))
~~~

~~~
2016-10-04 23:53:57.5933
2016-10-04 23:54:44.703
nil
~~~

Not good at all because in order to determine that there were no more links to find, it had to finish parsing through the remainder of the hierarchy.

`searchPath` lets us add some hints by adding special keys to the query criteria (like `_pattern` in the criteria above to find the AXTabGroup) and by setting an overall depth limit:

~~~lua
print(timestamp())
linksArray = {}
links2 = s:searchPath({
    { role = "AXApplication" },
    { role = "AXWindow" },
    { role = "AXSplitGroup" },
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXLink" }
}, 1) -- set a global depth limit for each criteria
while (links2) do
    table.insert(linksArray, links2)
    links2 = links2:next()
end
print(timestamp())
print(#linksArray)
~~~

Which gives us:

~~~
2016-10-05 00:07:19.7435
2016-10-05 00:07:20.486
5
~~~

Oops?  5 versus the 8 we got before?  Turns out that some of the links are children of the AXLink objects at the bottom of our path. I never went to the trouble to figure out why because I stumbled across an even easier way to get at all of the links which I will describe at the end, but for now, lets continue along the discovery process as I did so I can show you more of the module's features.

Let's try that again, this time adding to the AXLink's search depth...

~~~lua
print(timestamp())
linksArray = {}
links2 = s:searchPath({
    { role = "AXApplication" },
    { role = "AXWindow" },
    { role = "AXSplitGroup" },
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXLink", _depth = 2 }
}, 1) -- set a global depth limit for each criteria
while (links2) do
    table.insert(linksArray, links2)
    links2 = links2:next()
end
print(timestamp())
print(#linksArray)
~~~

Give us:

~~~
2016-10-05 00:14:16.3039
2016-10-05 00:14:17.4276
8
~~~

Better.

It's also worth noting that you can provide multiple criteria which must be met for a specific step in the path... like we did for elementSearch when trying to target a specific URL:

~~~lua
print(timestamp())
links2 = s:searchPath({
    { role = "AXApplication" },
    { role = "AXWindow" },
    { role = "AXSplitGroup" },
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup" },
    { role = "AXGroup" },
    { role = "AXLink", URL = "/privacy/", _pattern = true, _depth = 2 }
}, 1)
print(timestamp())
print(links2 and links2("URL")) -- if links2 is not nil, print out it's AXURL attribute
~~~

Give us:

~~~
2016-10-05 00:21:21.7061
2016-10-05 00:21:22.0903
https://www.google.com/intl/en/policies/privacy/?fg=1
~~~

Now, in the case of Safari, this is pretty fast, and would likely be sufficient, but if you want to see what's going on under the hood and see if we can tweak it further, let's see how the traversal actually occurs:

~~~lua
ax.log.level = 4
print(timestamp())
links2 = s:searchPath({
    { role = "AXApplication" },
    { role = "AXWindow" },
    { role = "AXSplitGroup" },
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup", _id = 1 }, -- any key which starts with _ won't affect the actual
    { role = "AXGroup", _id = 2 }, -- criteria matching, but will show up in the logs
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup", _id = 3 },
    { role = "AXGroup", _id = 4 },
    { role = "AXLink", _depth = 2 }
}, 1)
print(timestamp())
print(links2 and links2("URL")) -- if links2 is not nil, print out it's AXURL attribute
~~~

This gives us:

~~~
2016-10-05 00:27:18.3955
00:27:18 …uielement:     push:AXApplication, searching for:{ _includeSelf = true, role = "AXApplication" }
                         push:AXApplication, searching for:{ role = "AXWindow" }
                         push:AXWindow, searching for:{ role = "AXSplitGroup" }
                         pop: AXWindow
                         push:AXApplication, searching for:{ role = "AXWindow" }
                         push:AXWindow, searching for:{ role = "AXSplitGroup" }
                         push:AXSplitGroup, searching for:{ _pattern = true, role = "TabGroup$" }
                         push:AXTabGroup, searching for:{ _id = 1, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 2, role = "AXGroup" }
                         push:AXGroup, searching for:{ role = "AXScrollArea" }
                         push:AXScrollArea, searching for:{ role = "AXWebArea" }
                         push:AXWebArea, searching for:{ _id = 3, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 4, role = "AXGroup" }
                         pop: AXGroup
                         push:AXWebArea, searching for:{ _id = 3, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 4, role = "AXGroup" }
                         pop: AXGroup
                         push:AXWebArea, searching for:{ _id = 3, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 4, role = "AXGroup" }
                         pop: AXGroup
                         push:AXWebArea, searching for:{ _id = 3, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 4, role = "AXGroup" }
                         push:AXGroup, searching for:{ _depth = 2, role = "AXLink" }
2016-10-05 00:27:18.6231
https://mail.google.com/mail/?tab=wm
~~~

First off we notice that Safari has two window objects, even though we're only really seeing one... some internal offscreen mapping, no doubt, but we can skip even checking it by adding to the window criteria.

We also see that multiple AXGroup's (_id = 3) attached to the AXWebArea have to be checked out before finding the right one.  This brings us to the `_count` key:


~~~lua
ax.log.level = 4
print(timestamp())
links2 = s:searchPath({
    { role = "AXApplication" },
    { role = "AXWindow", title = "Google" },
    { role = "AXSplitGroup" },
    { role = "TabGroup$", _pattern = true },
    { role = "AXGroup", _id = 1 },
    { role = "AXGroup", _id = 2 },
    { role = "AXScrollArea" },
    { role = "AXWebArea" },
    { role = "AXGroup", _id = 3, _count = 4 }, -- _count tells the search to return every 4th AXGroup found at this search level
    { role = "AXGroup", _id = 4 },
    { role = "AXLink", _depth = 2 }
}, 1)
print(timestamp())
print(links2 and links2("URL")) -- if links2 is not nil, print out it's AXURL attribute
~~~

And we see:

~~~
2016-10-05 00:39:15.0518
00:39:15                 push:AXApplication, searching for:{ _includeSelf = true, role = "AXApplication" }
                         push:AXApplication, searching for:{ role = "AXWindow", title = "Google" }
                         push:AXWindow, searching for:{ role = "AXSplitGroup" }
                         push:AXSplitGroup, searching for:{ _pattern = true, role = "TabGroup$" }
                         push:AXTabGroup, searching for:{ _id = 1, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 2, role = "AXGroup" }
                         push:AXGroup, searching for:{ role = "AXScrollArea" }
                         push:AXScrollArea, searching for:{ role = "AXWebArea" }
                         push:AXWebArea, searching for:{ _count = 4, _id = 3, role = "AXGroup" }
                         push:AXGroup, searching for:{ _id = 4, role = "AXGroup" }
                         push:AXGroup, searching for:{ _depth = 2, role = "AXLink" }
2016-10-05 00:39:15.1851
https://mail.google.com/mail/?tab=wm
~~~

About as direct a search as we could hope for.  I have a suspicion that adding the _count to the third AXGroup may be site dependent -- when testing this against the Hammerspoon web site, I think I remember setting it to 3, but unfortunately I didn't record that test, so...  `_count` will probably be most useful in fairly static applications, but I wanted to describe its use here and show an example.

##### searchPath Notes

* Each criteria must be found in order, but they need not be immediate children of each other.  A criteria's `_depth` parameter (or the global depth, if no criteria depth is specified) determines how far down to search for a match for this criteria
* A depth of 1 means that only children will be examined -- this is by far the fastest, but only works if you can specify the entire path to your desired object.  A depth of 2 means that children and children of children will be examined, and so on.
* The observant might have noticed _includeSelf in the query log.  Usually a criteria specifies what you want to find *as a child* of the current object.  This key allows you to specify that the criteria might possibly match the object itself, and in the case above where we start with an application object `s`, and our first step in the path is to match an AXApplication object, we *do* want to match the current object.  If you do not specify this key, it is assumed to be true for the first criteria in a path, but false for every other criteria in the path.
* The search state is added to the uservalue (check out a Lua reference and read about debug.getuservalue and debug.setuservalue) of a returned userdata from a search. If you use the returned value as the starting point for a new search, this state information is reset (i.e. `next` only works until you use the `searchPath` method on the returned userdata.
* Accessibility objects are created and destroyed by an application all the time... If you're not going to use the `next` method on a returned value fairly quickly, it is recommended that you either clear the state information with `result = result:copy()` or perform a new search when you're ready in case the old data has become stale.


##### End Results

The vague idea of examining Safari became how to get at the links in a window... I've show one way that has worked for a number of pages that I've checked, but along the way I came across an accessibility attribute I missed entirely the first time I looked at the tree for Safari: AXLinkUIElements is an element of AXWebArea.

~~~lua
ax = require("hs._asm.axuielement")
sw = ax.windowElement(hs.application("Safari"):mainWindow())
print(timestamp())
webArea = sw:searchPath({
    { role = "AXWindow"},
    { role = "AXSplitGroup" },
    { role = "AXTabGroup" },
    { role = "AXGroup", },
    { role = "AXGroup", },
    { role = "AXScrollArea" },
    { role = "AXWebArea" }
}, 1)
print(timestamp())
links = webArea("AXLinkUIElements")
print(#links)
~~~

Giving us:

~~~
2016-10-05 01:17:23.5075
2016-10-05 01:17:23.6196
8
~~~

### Conclusion

I hope this overview gives you some help in determining how to use this module.  Unlike many other modules, this is more of a toolkit then a set of specific functions. But with this toolkit, you can examine and manipulate applications in ways no simple set of functions could hope to encompass.
