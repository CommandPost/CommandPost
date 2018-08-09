--- === cp.rx.go ===
---
--- Defines [Statements](cp.rx.go.Statement.md) to make processing of
--- [cp.rx.Observable](cp.rx.Observable.md) values
--- in ways that are more familiar to synchronous programmers.
---
--- A common activity is to perform some tasks, wait for the results and
--- do some more work with those results.
---
--- Lets say you want to calculate the price of an item that is in US Dollars (USD) and
--- output it in Australian Dollars (AUD). We have `anItem` that will return an
--- [Observable](cp.rx.go.Observable.md) that fetches the item price, and an
--- `exchangeRate` function that will fetch the current exchange rate for two currencies.
---
--- Using reactive operators, you could use the `zip` function to achieve this:
---
--- ```lua
--- Observable.zip(
---     anItem:priceInUSD(),
---     exchangeRate("USD", "AUD")
--- )
--- :subscribe(function(price, rate)
---     print "AUD Price: ", price * rate
--- end)
--- ```
---
--- The final subscription will only be executed once both the `priceInUSD()` and `exchangeRate(...)` push
--- a value. It will continue calling it while both keep producing values, but will complete if any of them
--- complete.
---
--- Using the [Given](cp.rx.go.Given.md) statement it would look like this:
---
--- ```lua
--- Given(
---    anItem:priceInUSD(),
---    exchangeRate("USD", "AUD"),
--- )
--- :Now(function(price, rate)
---     print "AUD Price: ", price * rate
--- end)
--- ```
---
--- For more information on using and creating statements, see the
--- [Statements](cp.rx.go.Statements.md) documentation.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
-- local log           = require("hs.logger").new("rxgo")
-- local inspect       = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local Statement     = require("cp.rx.go.Statement")
local Do            = require("cp.rx.go.Do")
local Done          = require("cp.rx.go.Done")
local First         = require("cp.rx.go.First")
local Given         = require("cp.rx.go.Given")
local If            = require("cp.rx.go.If")
local Last          = require("cp.rx.go.Last")
local List          = require("cp.rx.go.List")
local Require       = require("cp.rx.go.Require")
local Throw         = require("cp.rx.go.Throw")
local WaitUntil     = require("cp.rx.go.WaitUntil")

-----------------------------------------------------------
-- Utility functions
-----------------------------------------------------------

return {
    Statement = Statement,
    Given = Given,
    Do = Do,
    Require = Require,
    WaitUntil = WaitUntil,
    First = First,
    Last = Last,
    List = List,
    Throw = Throw,
    Done = Done,
    If = If,
}
