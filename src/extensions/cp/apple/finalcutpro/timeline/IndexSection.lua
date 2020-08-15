--- === cp.apple.finalcutpro.timeline.IndexSection ===
---
--- An abstract base class for sections inside the [Index](cp.apple.finalcutpro.timeline.Index.md).
--- This contains common methods and other definitions that apply for all sections.
---
--- This will generally not be created directly, but will be created via subclass such as
--- [IndexClips](cp.apple.finalcutpro.timeline.IndexClips.md).

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"

local go                    = require "cp.rx.go"

local Do, If                = go.Do, go.If

local IndexSection = class("cp.apple.finalcutpro.timeline.IndexSection"):include(lazy)

--- cp.apple.finalcutpro.timeline.IndexSection(index) -> IndexSection
--- Constructor
--- Creates the `IndexSection` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.
function IndexSection:initialize(index)
    self._index = index
end

--- cp.apple.finalcutpro.timeline.IndexSection:parent() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent index.
function IndexSection:parent()
    return self:index()
end

--- cp.apple.finalcutpro.timeline.IndexSection:app() -> cp.apple.finalcutpro
--- Method
--- The [Final Cut Pro](cp.apple.finalcutpro.md) instance.
function IndexSection:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.timeline.IndexSection:index() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent [Index](cp.apple.finalcutpro.timeline.Index.md).
function IndexSection:index()
    return self._index
end

--- cp.apple.finalcutpro.timeline.IndexSection.search <cp.ui.SearchField>
--- Field
--- The shared [SearchField](cp.ui.SearchField.md) for the [Index](cp.apple.finalcutpro.timeline.Index.md)
function IndexSection.lazy.value:search()
    return self:index().search
end

--- cp.apple.finalcutpro.timeline.IndexSection.activate <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that activates the section.
---
--- Notes:
--- * Must be overridden in subclasses to provide the actual RadioButton.
function IndexSection.lazy.value.activate()
    error("Subclasses must override the lazy `activate` method to return the correct RadioButton.")
end

--- cp.apple.finalcutpro.timeline.IndexSection.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` that represents the item.
function IndexSection.lazy.prop:UI()
    return self:index().UI:mutate(function(original)
        return self.activate:checked() and original()
    end)
end

--- cp.apple.finalcutpro.timeline.IndexSection.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the section is currently showing.
function IndexSection.lazy.prop:isShowing()
    return self.activate.checked
end


--- cp.apple.finalcutpro.timeline.IndexSection:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Clips section in the Timeline Index, if possible.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function IndexSection.lazy.method:doShow()
    local index = self:index()
    return Do(index:doShow())
    :Then(
        If(index.isShowing)
        :Then(self.activate:doPress())
        :Otherwise(false)
    )
    :ThenYield()
    :Label("IndexSection:doShow")
end

--- cp.apple.finalcutpro.timeline.IndexSection:doActivateSearch() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will show the Clips in the Timeline Index and focus on the Search field.
function IndexSection.lazy.method:doActivateSearch()
    return If(self:doShow())
    :Then(self.search:doFocus())
    :Otherwise(false)
    :Label("IndexSection:doActivateSearch")
end

return IndexSection